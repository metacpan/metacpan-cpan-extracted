use 5.006;
use strict;
use warnings;

package Metabase::Index::SQL;
# ABSTRACT: Metabase index backend role for common SQL actions

our $VERSION = '1.001';

use Moose::Role;

use Class::Load qw/load_class try_load_class/;
use Data::Stream::Bulk::Array;
use Data::Stream::Bulk::Nil;
use DBIx::RunSQL;
use DBIx::Simple;
use File::Temp ();
use List::AllUtils qw/uniq/;
use SQL::Abstract;
use SQL::Translator::Schema;
use SQL::Translator::Schema::Constants;
use SQL::Translator::Diff;
use SQL::Translator::Utils qw/normalize_name/;
use SQL::Translator;
use Try::Tiny;
use Metabase::Fact;

with 'Metabase::Backend::SQL';
with 'Metabase::Index' => { -version => 1.000 };

has typemap => (
  is => 'ro',
  isa => 'HashRef',
  lazy_build => 1,
);

requires '_build_typemap';

#--------------------------------------------------------------------------#
# attributes built by the role
#--------------------------------------------------------------------------#

has _core_table => (
  is => 'ro',
  isa => 'Str',
  default => sub { "core_meta" },
);

has _requested_content_type => (
  is => 'rw',
  isa => 'Str',
  clearer => '_clear_requested_content_type',
);

has _requested_resource_type => (
  is => 'rw',
  isa => 'Str',
  clearer => '_clear_requested_resource_type',
);

has _query_fields => (
  traits => ['Array'],
  is => 'ro',
  isa => 'ArrayRef[Str]',
  lazy_build => 1,
  handles => {
    _push_query_fields => 'push',
    _grep_query_fields => 'grep',
    _all_query_fields => 'elements',
  },
);

has _content_tables => (
  traits => ['Array'],
  is => 'ro',
  isa => 'ArrayRef[Str]',
  lazy_build => 1,
  handles => {
    _push_content_tables => 'push',
    _grep_content_tables => 'grep',
    _all_content_tables => 'elements',
  },
);

has _resource_tables => (
  traits => ['Array'],
  is => 'ro',
  isa => 'ArrayRef[Str]',
  lazy_build => 1,
  handles => {
    _push_resource_tables => 'push',
    _grep_resource_tables => 'grep',
    _all_resource_tables => 'elements',
  },
);

sub _build__content_tables { return [] }

sub _build__resource_tables { return [] }

sub _build__query_fields { return [] }

sub _all_tables {
  my $self = shift;
  return
    $self->_core_table,
    $self->_all_content_tables,
    $self->_all_resource_tables;
}

#--------------------------------------------------------------------------#
# methods
#--------------------------------------------------------------------------#

sub initialize {
  my ($self, $classes, $resources) = @_;
  @$resources = uniq ( @$resources, "Metabase::Resource::metabase::user" );
  my $schema = $self->schema;
  # Core table
  my $table = $self->_table_from_meta( $self->_core_table, Metabase::Fact->core_metadata_types );
  my $pk = $table->get_field('guid');
  while ( my ($k,$v) = each %{$self->_guid_field_params} ) {
    $pk->$k($v)
      if $pk->can($k);
  }
  $table->add_constraint(
    name => $self->_core_table . "_pk",
    fields => ['guid'],
    type => PRIMARY_KEY,
  );
  $schema->add_table($table);
  # Fact tables
  my @expanded =
    map { $_->fact_classes }
    grep { $_->isa("Metabase::Report") }
    @$classes;
  for my $c ( @$classes, @expanded ) {
    next unless try_load_class($c);
    my $name = normalize_name( lc($c->type) );
    my $types = $c->content_metadata_types;
    next unless $types && keys %$types;
    $self->_push_content_tables($name);
    my $table = $self->_table_from_meta( $name, $types );
    $table->add_field(
      name => '_guid',
      is_nullable => 0,
      %{$self->_guid_field_params}
    );
    $table->add_constraint(
      name => "${name}_pk",
      fields => ['_guid'],
      type => PRIMARY_KEY,
    );
    $schema->add_table($table);
  }
  # Resource tables
  for my $r ( @$resources ) {
    next unless try_load_class($r);
    my $name = $r;
    $name =~ s/^Metabase::Resource:://;
    $name =~ s/::/_/g;
    $name = normalize_name( lc $name );
    my $types = $r->metadata_types;
    next unless keys %$types;
    $self->_push_resource_tables($name);
    my $table = $self->_table_from_meta( $name, $types );
    $table->add_field(
      name => '_guid',
      is_nullable => 0,
      is_primary_key => 1,
      %{$self->_guid_field_params}
    );
    $table->add_constraint(
      name => "${name}_pk",
      fields => ['_guid'],
      type => PRIMARY_KEY,
    );
    $schema->add_table($table);
  }

  $self->_deploy_schema;

  return;
}

sub _table_from_meta {
  my ($self, $name, $typehash) = @_;
  my $table = SQL::Translator::Schema::Table->new( name => $name );
  for my $k ( sort keys %$typehash ) {
#    warn "Adding $k to $name\n";
    $table->add_field(
      name => normalize_name($k),
      data_type => $self->typemap->{$typehash->{$k} || "//str"},
    );
  }
  return $table;
}

sub _content_table {
  my ($self, $name) = @_;
  return normalize_name( lc $name );
}

sub _resource_table {
  my ($self, $name) = @_;
  $name =~ s/^Metabase-Resource-//;
  return normalize_name( lc $name );
}

sub _get_search_sql {
  my ( $self, $select, $spec ) = @_;

  # clear type constraints before analyzing query
  $self->_clear_requested_content_type;
  $self->_clear_requested_resource_type;
  $self->_clear_query_fields;

  my ($where, $limit) = $self->get_native_query($spec);

  my ($saw_content_field, $saw_resource_field);
  for my $f ( $self->_all_query_fields ) {
    $saw_content_field++ if $f =~ qr{^content\.};
    $saw_resource_field++ if $f =~ qr{^resource\.};
    return unless $f =~ qr{^(?:core|content|resource)\.};
  }

  if ( $saw_content_field && ! $self->_requested_content_type ) {
    Carp::confess("query requested content metadata without content type constraint");
  }
  if ( $saw_resource_field && ! $self->_requested_resource_type ) {
    Carp::confess("query requested resource metadata without resource type constraint");
  }

  # based on requests, conduct joins
  my @from = qq{from "core_meta" core};
  return unless $self->_check_query_fields($self->_core_table, 'core');

  if ( my $content_type = $self->_requested_content_type ) {
    my $content_table = $self->_content_table($content_type);
    return unless $self->_check_query_fields($content_table, 'content');
    push @from, qq{join "$content_table" content on core.guid = content._guid};
  }
  if ( my $resource_type = $self->_requested_resource_type ) {
    my $resource_table = $self->_resource_table($resource_type);
    return unless $self->_check_query_fields($resource_table, 'resource');
    push @from, qq{join "$resource_table" resource on core.guid = resource._guid};
  }

  my $sql = join(" ", $select, @from, $where);
  return ($sql, $limit);
}

sub _check_query_fields {
  my ($self, $table, $type) = @_; # type 'core', 'resource' or 'content'
  my $table_obj = $self->schema->get_table("$table");
  for my $f ( $self->_all_query_fields ) {
    next unless $f =~ /^$type\.(.+)$/;
    my $name = $1;
    return unless $table_obj->get_field($name);
  }
  return 1;
}

sub add {
    my ( $self, $fact ) = @_;

    Carp::confess("can't index a Fact without a GUID") unless $fact->guid;

    try {
      $self->dbis->begin_work();
      my $core_meta = $fact->core_metadata;
      $core_meta->{resource} = "$core_meta->{resource}"; #stringify obj
#        use Data::Dumper;
#        warn "Adding " . Dumper $core_meta;
      $core_meta->{guid} = $self->_munge_guid($core_meta->{guid});
      $self->dbis->insert( 'core_meta', $core_meta );
      my $content_meta = $fact->content_metadata;
      # not all facts have content metadata
      if ( keys %$content_meta ) {
        $content_meta->{_guid} = $self->_munge_guid($fact->guid);
#        use Data::Dumper;
#        warn "Adding " . Dumper $content_meta;
        my $content_table = $self->_content_table( $fact->type );
        $self->dbis->insert( $content_table, $content_meta );
      }
      # XXX eventually, add resource metadata -- dagolden, 2011-08-24
      my $resource_meta = $fact->resource_metadata;
      # not all facts have resource metadata
      if ( keys %$resource_meta ) {
        $resource_meta->{_guid} = $self->_munge_guid($fact->guid);
#        use Data::Dumper;
#        warn "Adding " . Dumper $resource_meta;
        my $resource_table = $self->_resource_table( $resource_meta->{type} );
        $self->dbis->insert( $resource_table, $resource_meta );
      }
      $self->dbis->commit;
    }
    catch {
      $self->dbis->rollback;
      Carp::confess("Error inserting record: $_");
    };

}

sub count {
  my ( $self, %spec) = @_;

  my ($sql, $limit) = $self->_get_search_sql("select count(*)", \%spec);

  return 0 unless $sql;
#  warn "COUNT: $sql\n";

  my ($count) = $self->dbis->query($sql)->list;

  return $count;
}

sub query {
  my ( $self, %spec) = @_;

  my ($sql, $limit) = $self->_get_search_sql("select core.guid", \%spec);

  return Data::Stream::Bulk::Nil->new
    unless $sql;

#  warn "QUERY: $sql\n";
  my $result = $self->dbis->query($sql);

  return Data::Stream::Bulk::Array->new(
    array => [ map { $self->_unmunge_guid( $_->[0] ) } $result->arrays ]
  );
}

# XXX evil hackery to allow shards to give us ordering info
sub _shard_query {
  my ( $self, %spec) = @_;
  my $spec = \%spec;

  my $select;
  if ( defined $spec->{-order} and ref $spec->{-order} eq 'ARRAY') {
    my @clauses;
    my @order = @{$spec->{-order}};
    while ( @order ) {
      my ($dir, $field) = splice( @order, 0, 2);
      $field = $self->_quote_field( $field );
      $dir =~ s/^-//;
      $dir = uc $dir;
      push @clauses, $field;
    }
    $select = "select " . join(", ", "core.guid", @clauses);
  }
  else {
    $select = "select core.guid";
  }

  my ($sql, $limit) = $self->_get_search_sql($select, \%spec);

  return Data::Stream::Bulk::Nil->new
    unless $sql;

#  warn "QUERY: $sql\n";
  my $result = $self->dbis->query($sql);

  return Data::Stream::Bulk::Array->new(
    array => [ $result->arrays ]
  );
}

sub delete {
    my ( $self, $guid ) = @_;

    Carp::confess("can't delete without a GUID") unless $guid;

    $guid = $self->_munge_guid($guid);
    try {
      $self->dbis->begin_work();
      $self->dbis->delete( 'core_meta', { 'guid' => $guid } );
      # XXX need to track _content_tables
      for my $table ( uniq $self->_all_content_tables ) {
        $self->dbis->delete( $table, { '_guid' => $guid } );
      }
      for my $table ( uniq $self->_all_resource_tables ) {
        $self->dbis->delete( $table, { '_guid' => $guid } );
      }
      # XXX eventually, add resource metadata -- dagolden, 2011-08-24
      $self->dbis->commit;
    }
    catch {
      $self->dbis->rollback;
      Carp::confess("Error deleting record: $_");
    };
    # delete
}

#--------------------------------------------------------------------------#
# required by Metabase::Query
#--------------------------------------------------------------------------#

requires '_quote_field';
requires '_quote_val';

# We need to track fields used in a query
before _quote_field => sub {
  my ($self, $field) = @_;
  $self->_push_query_fields($field);
};

# We need to track type constraints to determine which tables to join
before op_eq => sub {
  my ($self, $field, $value) = @_;
  if ($field eq 'core.type') {
    $self->_requested_content_type( $value );
  }
  if ($field eq 'resource.type') {
    $self->_requested_resource_type( $value );
  }
};

sub translate_query {
  my ( $self, $spec ) = @_;

  my (@parts, $limit);

  # where
  if ( defined $spec->{-where} ) {
    push @parts, "where " . $self->dispatch_query_op( $spec->{-where} );
  }

  # order
  if ( defined $spec->{-order} and ref $spec->{-order} eq 'ARRAY') {
    my @clauses;
    my @order = @{$spec->{-order}};
    while ( @order ) {
      my ($dir, $field) = splice( @order, 0, 2);
      $field = $self->_quote_field( $field );
      $dir =~ s/^-//;
      $dir = uc $dir;
      push @clauses, "$field $dir";
    }
    push @parts, qq{order by } . join(", ", @clauses);
  }

  # limit
  if ( $limit = $spec->{-limit} ) {
    push @parts, qq{limit $limit};
  }

  return join( q{ }, @parts ), $limit;
}

around [qw/op_eq op_ne op_gt op_lt op_ge op_le op_like/ ] => sub {
  my $orig = shift;
  my $self = shift;
  my ($field, $val) = @_;
  if ( $field eq "core.guid" ) {
#    warn "*** Fixing $field ($val)";
    $val = $self->_munge_guid($val);
  }
  return $self->$orig($field, $val);
};

around [qw/op_between/ ] => sub {
  my $orig = shift;
  my $self = shift;
  my ($field, $low, $high) = @_;
  if ( $field eq "core.guid" ) {
    $low = $self->_munge_guid($low);
    $high = $self->_munge_guid($high);
  }
  return $self->$orig($field, $low, $high);
};

sub op_eq {
  my ($self, $field, $val) = @_;
  return $self->_quote_field($field) . " = " . $self->_quote_val($val);
}

sub op_ne {
  my ($self, $field, $val) = @_;
  return $self->_quote_field($field) . " != " . $self->_quote_val($val);
}

sub op_gt {
  my ($self, $field, $val) = @_;
  return $self->_quote_field($field) . " > " . $self->_quote_val($val);
}

sub op_lt {
  my ($self, $field, $val) = @_;
  return $self->_quote_field($field) . " < " . $self->_quote_val($val);
}

sub op_ge {
  my ($self, $field, $val) = @_;
  return $self->_quote_field($field) . " >= " . $self->_quote_val($val);
}

sub op_le {
  my ($self, $field, $val) = @_;
  return $self->_quote_field($field) . " <= " . $self->_quote_val($val);
}

sub op_between {
  my ($self, $field, $low, $high) = @_;
  return $self->_quote_field($field) . " between "
    . $self->_quote_val($low) . " and " . $self->_quote_val($high);
}

sub op_like {
  my ($self, $field, $val) = @_;
  # XXX really should quote/check $val
  return $self->_quote_field($field) . " like " . $self->_quote_val($val);
}

sub op_not {
  my ($self, $pred) = @_;
  my $clause = $self->dispatch_query_op($pred);
  return "NOT ($clause)";
}

sub op_or {
  my ($self, @args) = @_;
  my @predicates = map { $self->dispatch_query_op($_) } @args;
  return join(" or ", map { "($_)" } @predicates);
}

sub op_and {
  my ($self, @args) = @_;
  my @predicates = map { $self->dispatch_query_op($_) } @args;
  return join(" and ", map { "($_)" } @predicates);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Index::SQL - Metabase index backend role for common SQL actions

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  package Metabase::Index::SQLite;

  use Moose;

  with 'Metabase::Index::SQL';

  # implement required fields
  ...;

  1;

=head1 DESCRIPTION

This is a role that consumes the L<Metabase::Backend::SQL> role and implements
implements the L<Metabase::Index> and L<Metabase::Query> roles generically
using SQL semantics.  RDBMS vendor specific methods must be implemented by a
Moose class consuming this role.

The following methods must be implemented:

  _build_dsn        # a DSN string for DBI
  _build_db_user    # a username for DBI
  _build_db_pass    # a password for DBI
  _build_db_type    # a SQL::Translator type for the DB vendor
  _build_typemap    # hashref of metadata types to schema data types
  _quote_field      # vendor-specific identifier quoting
  _quote_val        # vendor-specific value quoting

=for Pod::Coverage::TrustPod add query delete count initialize
translate_query op_eq op_ne op_gt op_lt op_ge op_le op_between op_like
op_not op_or op_and PRIMARY_KEY

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Leon Brocard <acme@astray.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
