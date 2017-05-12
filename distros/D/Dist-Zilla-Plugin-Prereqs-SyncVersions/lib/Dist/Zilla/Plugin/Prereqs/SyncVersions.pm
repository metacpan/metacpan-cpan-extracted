use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::Prereqs::SyncVersions;

# ABSTRACT: (DEPRECATED) Homogenize prerequisites so dependency versions are consistent

our $VERSION = '0.003002';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has with around );
use MooseX::Types::Moose qw( HashRef ArrayRef Str );
with 'Dist::Zilla::Role::PrereqSource';



































has applyto_phase => (
  is => ro =>,
  isa => ArrayRef [Str] =>,
  lazy    => 1,
  default => sub { [qw(build test runtime configure)] },
);



















has applyto_relation => (
  is => ro =>,
  isa => ArrayRef [Str],
  lazy    => 1,
  default => sub { [qw(requires)] },
);















has applyto => (
  is => ro =>,
  isa => ArrayRef [Str] =>,
  lazy    => 1,
  builder => _build_applyto =>,
);

has _applyto_list => (
  is => ro =>,
  isa => ArrayRef [ ArrayRef [Str] ],
  lazy    => 1,
  builder => _build__applyto_list =>,
);

has _max_versions => (
  is      => ro  =>,
  isa     => HashRef,
  lazy    => 1,
  default => sub { {} },
);

sub _versionify {
  my ( undef, $version ) = @_;
  return $version if ref $version;
  require version;
  return version->parse($version);
}

sub _set_module_version {
  my ( $self, $module, $version ) = @_;
  if ( not exists $self->_max_versions->{$module} ) {
    $self->_max_versions->{$module} = $self->_versionify($version);
    return;
  }
  my $comparator = $self->_versionify($version);
  my $current    = $self->_max_versions->{$module};
  if ( $current < $comparator ) {
    $self->log_debug( [ 'Version upgrade on : %s', $module ] );
    $self->_max_versions->{$module} = $comparator;
  }
  return;
}

sub _get_module_version {
  my ( $self, $module ) = @_;
  return $self->_max_versions->{$module};
}

sub _build_applyto {
  my $self = shift;
  my @out;
  for my $phase ( @{ $self->applyto_phase } ) {
    for my $relation ( @{ $self->applyto_relation } ) {
      push @out, $phase . q[.] . $relation;
    }
  }
  return \@out;
}

sub _build__applyto_list {
  my $self = shift;
  my @out;
  for my $type ( @{ $self->applyto } ) {
    if ( $type =~ /^ ([^.]+) [.] ([^.]+) $/msx ) {
      push @out, [ "$1", "$2" ];
      next;
    }
    return $self->log_fatal( [ q[<<%s>> does not match << <phase>.<relation> >>], $type ] );
  }
  return \@out;
}











sub mvp_multivalue_args { return qw( applyto applyto_relation applyto_phase ) }

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  $localconf->{applyto_phase}    = $self->applyto_phase;
  $localconf->{applyto_relation} = $self->applyto_relation;
  $localconf->{applyto}          = $self->applyto;

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
    unless __PACKAGE__ eq ref $self;

  return $config;
};

__PACKAGE__->meta->make_immutable;
no Moose;

sub _foreach_phase_rel {
  my ( $self, $prereqs, $callback ) = @_;
  for my $applyto ( @{ $self->_applyto_list } ) {
    my ( $phase, $rel ) = @{$applyto};
    next if not exists $prereqs->{$phase};
    next if not exists $prereqs->{$phase}->{$rel};
    $callback->( $phase, $rel, $prereqs->{$phase}->{$rel}->as_string_hash );
  }
  return;
}








sub register_prereqs {
  my ($self)  = @_;
  my $zilla   = $self->zilla;
  my $prereqs = $zilla->prereqs;
  my $guts = $prereqs->cpan_meta_prereqs->{prereqs} || {};

  $self->_foreach_phase_rel(
    $guts => sub {
      my ( undef, undef, $reqs ) = @_;
      for my $module ( keys %{$reqs} ) {
        $self->_set_module_version( $module, $reqs->{$module} );
      }
    },
  );
  $self->_foreach_phase_rel(
    $guts => sub {
      my ( $phase, $rel, $reqs ) = @_;
      for my $module ( keys %{$reqs} ) {
        my $v = $self->_get_module_version( $module, $reqs->{$module} );
        $zilla->register_prereqs( { phase => $phase, type => $rel }, $module, $v );
      }
    },
  );
  return $prereqs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Prereqs::SyncVersions - (DEPRECATED) Homogenize prerequisites so dependency versions are consistent

=head1 VERSION

version 0.003002

=head1 DEPRECATED

This module is deprecated as equivalent behavior is now part of C<Dist::Zilla>.

However, this module will keep maintained for anyone who wants this behavior without upgrading to C<DZil 5>

=head1 SYNOPSIS

    ; <bunch of metaprereq providing modules>

    [Prereqs::SyncVersions]

Note: This must come B<after> packages that add their own prerequisites in order to work as intended.

=head1 DESCRIPTION

This module exists to pose mostly as a workaround for potential bugs in downstream tool-chains.

Namely, C<CPAN.pm> is confused when it sees:

    runtime.requires : Foo >= 5.0
    test.requires    : Foo >= 6.0

It doesn't know what to do.

This is an easy enough problem to solve if you're using C<[Prereqs]> directly,
and C<[AutoPrereqs]> already does the right thing, but it gets messier
when you're working with L<< plugins that inject their own prerequisites|https://github.com/dagolden/Path-Tiny/commit/c620171db96597456a182ea6088a24d8de5debf6 >>

So this plugin will homogenize dependencies to be the same version in all phases
which infer the dependency, matching the largest one found, so the above becomes:

    runtime.requires : Foo >= 6.0
    test.requires    : Foo >= 6.0

=head1 METHODS

=head2 C<mvp_multivalue_args>

The following attributes exist, and may be specified more than once:

    applyto
    applyto_relation
    applyto_phase

=head2 C<register_prereqs>

This method is called during C<Dist::Zilla> prerequisite generation,
and it injects supplementary prerequisites to make things match up.

=head1 ATTRIBUTES

=head2 C<applyto_phase>

A multi-value attribute that specifies which phases to iterate and homogenize.

By default, this is:

    applyto_phase = build
    applyto_phase = test
    applyto_phase = runtime
    applyto_phase = configure

However, you could extend it further to include C<develop> if you wanted to.

    applyto_phase = build
    applyto_phase = test
    applyto_phase = runtime
    applyto_phase = configure
    appyyto_phase = develop

=head2 C<applyto_relation>

A multi-value attribute that specifies which relations to iterate and homogenize.

By default, this is:

    applyto_relation = requires

However, you could extend it further to include C<suggests> and C<recommends> if you wanted to.
You could even add C<conflicts> ... but you really shouldn't.

    applyto_relation = requires
    applyto_relation = suggests
    applyto_relation = recommends
    applyto_relation = conflicts ; Danger will robinson.

=head2 C<applyto>

A multi-value attribute that by default composites the values of

C<applyto_relation> and C<applyto_phase>.

This is if you want to be granular about how you specify phase/relations to process.

    applyto = runtime.requires
    applyto = develop.requires
    applyto = test.suggests

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Plugin::Prereqs::SyncVersions",
    "interface":"class",
    "inherits":"Moose::Object",
    "does":"Dist::Zilla::Role::PrereqSource"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
