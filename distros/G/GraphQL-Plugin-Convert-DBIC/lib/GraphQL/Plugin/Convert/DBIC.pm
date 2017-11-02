package GraphQL::Plugin::Convert::DBIC;
use 5.008001;
use strict;
use warnings;
use GraphQL::Schema;
use GraphQL::Debug qw(_debug);

our $VERSION = "0.02";
use constant DEBUG => $ENV{GRAPHQL_DEBUG};

my %TYPEMAP = (
  guid => 'String',
  wlongvarchar => 'String',
  wvarchar => 'String',
  wchar => 'String',
  bigint => 'Int',
  bit => 'Int',
  tinyint => 'Int',
  longvarbinary => 'String',
  varbinary => 'String',
  binary => 'String',
  longvarchar => 'String',
  unknown_type => 'String',
  all_types => 'String',
  char => 'String',
  numeric => 'Float',
  decimal => 'Float',
  integer => 'Int',
  smallint => 'Int',
  float => 'Float',
  real => 'Float',
  double => 'Float',
  datetime => 'DateTime',
  date => 'DateTime',
  interval => 'Int',
  time => 'DateTime',
  timestamp => 'DateTime',
  varchar => 'String',
  boolean => 'Boolean',
  udt => 'String',
  udt_locator => 'String',
  row => 'String',
  ref => 'String',
  blob => 'String',
  blob_locator => 'String',
  clob => 'String',
  clob_locator => 'String',
  array => 'String',
  array_locator => 'String',
  multiset => 'String',
  multiset_locator => 'String',
  type_date => 'DateTime',
  type_time => 'DateTime',
  type_timestamp => 'DateTime',
  type_time_with_timezone => 'DateTime',
  type_timestamp_with_timezone => 'DateTime',
  interval_year => 'Int',
  interval_month => 'Int',
  interval_day => 'Int',
  interval_hour => 'Int',
  interval_minute => 'Int',
  interval_second => 'Int',
  interval_year_to_month => 'Int',
  interval_day_to_hour => 'Int',
  interval_day_to_minute => 'Int',
  interval_day_to_second => 'Int',
  interval_hour_to_minute => 'Int',
  interval_hour_to_second => 'Int',
  interval_minute_to_second => 'Int',
  # not DBI SQL_* types
  int => 'Int',
  text => 'String',
  tinytext => 'String',
);
my %TYPE2SCALAR = map { ($_ => 1) } qw(ID String Int Float Boolean);

sub _dbicsource2pretty {
  my ($source) = @_;
  $source = $source->source_name || $source;
  $source =~ s#.*::##;
  join '', map ucfirst, split /_+/, $source;
}

sub _apply_modifier {
  my ($modifier, $typespec) = @_;
  return $typespec if !$modifier;
  return $typespec if $modifier eq 'non_null'
    and ref $typespec eq 'ARRAY'
    and $typespec->[0] eq 'non_null'; # no double-non_null
  [ $modifier, { type => $typespec } ];
}

sub _type2input {
  my ($name, $fields, $name2pk21, $fk21, $column21, $name2type) = @_;
  +{
    kind => 'input',
    name => "${name}Input",
    fields => {
      (map { ($_ => $fields->{$_}) }
        grep !$name2pk21->{$name}{$_} && !$fk21->{$_}, keys %$column21),
      _make_fk_fields($name, $fk21, $name2type, $name2pk21),
    },
  };
}

sub _make_fk_fields {
  my ($name, $fk21, $name2type, $name2pk21) = @_;
  my $type = $name2type->{$name};
  (map {
    my $field_type = $type->{fields}{$_}{type};
    $TYPE2SCALAR{$field_type}
      ? ($_ => { type => $field_type })
      : map {
          (lcfirst "${field_type}_${_}" => {
            type => $name2type->{$field_type}{fields}{$_}{type}
          })
        } keys %{ $name2pk21->{$field_type} }
  } keys %$fk21);
}

sub _make_pk_fields {
  my ($name, $pk21, $name2type) = @_;
  my $type = $name2type->{$name};
  (map {
    $_ => { type => $type->{fields}{$_}{type} }
  } keys %$pk21),
}

sub to_graphql {
  my ($class, $dbic_schema_cb) = @_;
  my $dbic_schema = $dbic_schema_cb->();
  my @ast = ({kind => 'scalar', name => 'DateTime'});
  my (%name2type, %name2column21, %name2pk21, %name2fk21);
  for my $source (map $dbic_schema->source($_), $dbic_schema->sources) {
    my $name = _dbicsource2pretty($source);
    my %fields;
    my $columns_info = $source->columns_info;
    $name2pk21{$name} = +{ map { ($_ => 1) } $source->primary_columns };
    my %rel2info = map {
      ($_ => $source->relationship_info($_))
    } $source->relationships;
    for my $column (keys %$columns_info) {
      my $info = $columns_info->{$column};
      DEBUG and _debug("schema_dbic2graphql($name.col)", $column, $info);
      $fields{$column} = +{
        type => _apply_modifier(
          !$info->{is_nullable} && 'non_null',
          $TYPEMAP{ lc $info->{data_type} }
            // die "'$column' unknown data type: @{[lc $info->{data_type}]}\n",
        ),
      };
      $name2fk21{$name}->{$column} = 1 if $info->{is_foreign_key};
      $name2column21{$name}->{$column} = 1;
    }
    for my $rel (keys %rel2info) {
      my $info = $rel2info{$rel};
      DEBUG and _debug("schema_dbic2graphql($name.rel)", $rel, $info);
      my $type = _dbicsource2pretty($info->{source});
      $rel =~ s/_id$//; # dumb heuristic
      delete $name2column21{$name}->{$rel}; # so it's not a "column" now
      $type = _apply_modifier('list', $type) if $info->{attrs}{accessor} eq 'multi';
      $fields{$rel} = +{
        type => $type,
      };
    }
    my $spec = +{
      kind => 'type',
      name => $name,
      fields => \%fields,
    };
    $name2type{$name} = $spec;
    push @ast, $spec;
  }
  push @ast, map _type2input(
    $_, $name2type{$_}->{fields}, \%name2pk21, $name2fk21{$_},
    $name2column21{$_}, \%name2type,
  ), keys %name2type;
  push @ast, {
    kind => 'type',
    name => 'Query',
    fields => {
      map {
        my $name = $_;
        my $type = $name2type{$name};
        (
          # the PKs query
          lcfirst($name) => {
            type => _apply_modifier('list', $name),
            args => {
              map {
                $_ => {
                  type => _apply_modifier('non_null', _apply_modifier('list',
                    _apply_modifier('non_null', $type->{fields}{$_}{type})
                  ))
                }
              } keys %{ $name2pk21{$name} }
            },
          },
          "search$name" => {
            description => 'list of ORs each of which is list of ANDs',
            type => _apply_modifier('list', $name),
            args => {
              input => {
                type => _apply_modifier('non_null', _apply_modifier('list',
                  _apply_modifier('non_null', _apply_modifier('list',
                    _apply_modifier('non_null', "${name}Input")
                  ))
                ))
              },
            },
          },
        )
      } keys %name2type
    },
  };
  push @ast, {
    kind => 'type',
    name => 'Mutation',
    fields => {
      map {
        my $name = $_;
        my $type = $name2type{$name};
        (
          "create$name" => {
            type => $name,
            args => {
              input => { type => _apply_modifier('non_null', "${name}Input") },
            },
          },
          "update$name" => {
            type => $name,
            args => {
              input => { type => _apply_modifier('non_null', "${name}Input") },
              _make_pk_fields($name, $name2pk21{$name}, \%name2type),
            },
          },
          "delete$name" => {
            type => 'Boolean',
            args => {
              _make_pk_fields($name, $name2pk21{$name}, \%name2type),
            },
          },
        )
      } keys %name2type
    },
  };
  +{
    schema => GraphQL::Schema->from_ast(\@ast),
  };
}

=encoding utf-8

=head1 NAME

GraphQL::Plugin::Convert::DBIC - convert DBIx::Class schema to GraphQL schema

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-DBIC.svg?branch=master)](https://travis-ci.org/graphql-perl/GraphQL-Plugin-Convert-DBIC) |

[![CPAN version](https://badge.fury.io/pl/GraphQL-Plugin-Convert-DBIC.svg)](https://metacpan.org/pod/GraphQL::Plugin::Convert::DBIC)

=end markdown

=head1 SYNOPSIS

  use GraphQL::Plugin::Convert::DBIC;
  use Schema;
  my $converted = GraphQL::Plugin::Convert::DBIC->to_graphql(
    sub { Schema->connect }
  );
  print $converted->{schema}->to_doc;

=head1 DESCRIPTION

This module implements the L<GraphQL::Plugin::Convert> API to convert
a L<DBIx::Class::Schema> to L<GraphQL::Schema> etc.

Its C<Query> type represents a guess at what fields are suitable, based
on providing a lookup for each type (a L<DBIx::Class::ResultSource>)
by each of its columns.

The C<Mutation> type is similar: one C<create/update/delete(type)> per
"real" type.

=head1 ARGUMENTS

To the C<to_graphql> method: a code-ref returning a L<DBIx::Class::Schema>
object. This is so it can be called during the conversion process,
but also during execution of a long-running process to e.g. execute
database queries, when the database handle passed to this method as a
simple value might have expired.

=head1 DEBUGGING

To debug, set environment variable C<GRAPHQL_DEBUG> to a true value.

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

=head1 LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
