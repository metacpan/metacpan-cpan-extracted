package JSAN::Indexer;
use strict;
use warnings;

use Class::DBI::Loader;
use JSAN::Indexer::Creator;
use YAML;
use base qw[Class::Accessor::Fast];
__PACKAGE__->mk_accessors(qw[loader author distribution release library]);

our $VERSION = '0.05';
our $LOADER;
our $DSN;
our $INDEX_DB;

sub import {
    my ($class, $index_db) = @_;
    $INDEX_DB = $index_db if $index_db;
    $INDEX_DB ||= $ENV{JSAN_INDEX_DB}
              || "$ENV{HOME}/.jsan.index.sqlite";
    $DSN = "dbi:SQLite:$INDEX_DB";
}

sub new {
    my ($class) = shift;
    $LOADER = Class::DBI::Loader->new(
        dsn                     => $DSN,
        namespace               => "JSAN::Indexer",
        relationships           => 1,
    );
    my $self = $class->SUPER::new({@_});
    $self->loader($LOADER);
    $self->_class_map;
    eval { $self->_relate };
    return $self;
}

sub create_index_db {
    my ($class) = shift;
    JSAN::Indexer::Creator->create_index_db($class, $DSN, $INDEX_DB, @_);
}

sub _class_map {
    my ($self) = @_;
    $self->$_($self->loader->find_class($_))
      for qw[author distribution release library];
}

sub _relate {
    my ($self) = @_;
    
    my @rel = (
        q[author has_many distributions distribution],
        q[distribution has_many releases release],
        q[distribution has_many libraries library],
        q[release has_a distribution],
        q[release has_a author],
        q[release has_many libraries library],
        q[library has_a distribution],
        q[library has_a release],
    );
    
    foreach my $rel ( @rel ) {
        my ($class, $type, $col, $foreign) = split /\s+/, $rel;
        $foreign ||= $col;


        unless ($type eq 'has_many' && UNIVERSAL::can($self->loader->find_class($class), $col) ) {
            eval { $self->loader->find_class($class)->$type($col => $self->loader->find_class($foreign)) };
            warn $@ if $@;
        }
    }
    
    $self->release->has_a(meta => 'JSAN::Indexer::Meta');
}

package JSAN::Indexer::Meta;
use strict;
use warnings;

use YAML;
use base qw[Class::Accessor::Fast];

__PACKAGE__->mk_accessors(qw[yaml _meta]);
sub new {
    my ($class, $meta) = @_;
    return $class->SUPER::new({yaml => $meta, _meta => Load($meta)});
}

sub requires {
    my ($self) = @_;
    return [] unless $self->_meta;
    my $req   = $self->_meta->{requires};
    my $build = $self->_meta->{build_requires};

    my %reqs;
    if (ref($build) eq 'HASH') {
        $reqs{$_} = $build->{$_} for keys %{$build};
    }
    if (ref($req) eq 'HASH') {
        $reqs{$_} = $req->{$_} for keys %{$req};
    }

    my @reqs;
    while (my ($k, $v) = each %reqs) {
        push @reqs, {
            name    => $k,
            version => $v,
        };
    }
    return \@reqs;
}

1;

__END__

=head1 NAME

JSAN::Indexer -- Data Manager for the JSAN SQLite Index

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2005 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut

