use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::Prereqs::Recommend::MatchInstalled;

our $VERSION = '0.003003';

# ABSTRACT: Advertise versions of things you have as soft dependencies

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has around );
use MooseX::Types::Moose qw( HashRef ArrayRef Str );
with 'Dist::Zilla::Role::PrereqSource';

















has 'applyto_phase' => (
  is => ro =>,
  isa => ArrayRef [Str] =>,
  lazy    => 1,
  default => sub { [qw(build test runtime configure develop)] },
);




















has 'source_relation' => (
  is      => ro  =>,
  isa     => Str,
  lazy    => 1,
  default => sub { 'requires' },
);





















has 'target_relation' => (
  is      => ro  =>,
  isa     => Str =>,
  lazy    => 1,
  default => sub { 'recommends' },
);





















has 'applyto_map' => (
  is => ro =>,
  isa => ArrayRef [Str] =>,
  lazy    => 1,
  builder => _build_applyto_map =>,
);

sub _mk_phase_entry {
  my ( $self, $phase ) = @_;
  return sprintf q[%s.%s = %s.%s], $phase, $self->source_relation, $phase, $self->target_relation;
}

sub _build_applyto_map {
  my ($self) = @_;
  my @out;
  for my $phase ( @{ $self->applyto_phase } ) {
    push @out, $self->_mk_phase_entry($phase);
  }
  return \@out;
}

has '_applyto_map_hash' => (
  is => ro =>,
  isa => ArrayRef [HashRef] =>,
  lazy    => 1,
  builder => _build__applyto_map_hash =>,
);

# _Pulp__5010_qr_m_propagate_properly
## no critic (Compatibility::PerlMinimumVersionAndWhy)
my $re_phase    = qr/configure|build|runtime|test|develop/msx;
my $re_relation = qr/requires|recommends|suggests|conflicts/msx;

my $combo = qr/(?:$re_phase)[.](?:$re_relation)/msx;

sub _parse_map_token {
  my ( $self, $token ) = @_;
  my ( $phase, $relation );
  if ( ( $phase, $relation ) = $token =~ /\A($re_phase)[.]($re_relation)/msx ) {
    return {
      phase    => $phase,
      relation => $relation,
    };
  }
  return $self->log_fatal( [ '%s is not in the form <phase.relation>', $token ] );

}

sub _parse_map_entry {
  my ( $self, $entry ) = @_;
  my ( $source, $target );
  if ( ( $source, $target ) = $entry =~ /\A\s*($combo)\s*=\s*($combo)\s*\z/msx ) {
    return {
      source => $self->_parse_map_token($source),
      target => $self->_parse_map_token($target),
    };
  }
  return $self->log_fatal( [ '%s is not a valid entry for applyto_map', $entry ] );
}

sub _build__applyto_map_hash {
  my ($self) = @_;
  my @out;
  for my $line ( @{ $self->applyto_map } ) {
    push @out, $self->_parse_map_entry($line);
  }
  return \@out;
}

has 'modules' => (
  is => ro =>,
  isa => ArrayRef [Str],
  lazy    => 1,
  default => sub { [] },
);

has _modules_hash => (
  is      => ro                   =>,
  isa     => HashRef,
  lazy    => 1,
  builder => _build__modules_hash =>,
);

sub _build__modules_hash {
  my $self = shift;
  return { map { ( $_, 1 ) } @{ $self->modules } };
}

sub _user_wants_upgrade_on {
  my ( $self, $module ) = @_;
  return exists $self->_modules_hash->{$module};
}

sub mvp_multivalue_args { return qw(applyto_map applyto_phase modules) }
sub mvp_aliases { return { 'module' => 'modules' } }

sub _current_version_of {
  my ( undef, $package ) = @_;
  if ( 'perl' eq $package ) {

    # Thats not going to work, Dave.
    return $];
  }
  require Module::Data;
  my $md = Module::Data->new($package);
  return if not $md;
  return if not -e $md->path;
  return if -d $md->path;
  return $md->_version_emulate;
}

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config    = $self->$orig(@args);
  my $localconf = {};
  $localconf->{applyto_phase}   = $self->applyto_phase;
  $localconf->{applyto_map}     = $self->applyto_map;
  $localconf->{modules}         = $self->modules;
  $localconf->{source_relation} = $self->source_relation;
  $localconf->{target_relation} = $self->target_relation;
  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION unless __PACKAGE__ eq ref $self;
  $config->{ +__PACKAGE__ } = $localconf;
  return $config;
};

__PACKAGE__->meta->make_immutable;
no Moose;

sub _register_applyto_map_entry {
  my ( $self, $applyto, $prereqs ) = @_;
  my ( $phase, $rel );
  $phase = $applyto->{source}->{phase};
  $rel   = $applyto->{source}->{relation};
  my $targetspec = {
    phase => $applyto->{target}->{phase},
    type  => $applyto->{target}->{relation},
  };
  $self->log_debug( [ 'Processing %s.%s => %s.%s', $phase, $rel, $applyto->{target}->{phase}, $applyto->{target}->{relation} ] );
  if ( not exists $prereqs->{$phase} or not exists $prereqs->{$phase}->{$rel} ) {
    $self->log_debug( [ 'Nothing in %s.%s', $phase, $rel ] );
    return;
  }
  my $reqs = $prereqs->{$phase}->{$rel}->as_string_hash;

  for my $module ( keys %{$reqs} ) {
    next unless $self->_user_wants_upgrade_on($module);
    my $latest = $self->_current_version_of($module);
    if ( defined $latest ) {
      $self->zilla->register_prereqs( $targetspec, $module, $latest );
      next;
    }

    $self->log(
      [ q[You asked for the installed version of %s,] . q[ and it is a dependency but it is apparently not installed], $module, ],
    );
  }
  return $self;
}

sub register_prereqs {
  my ($self)  = @_;
  my $zilla   = $self->zilla;
  my $prereqs = $zilla->prereqs;
  my $guts = $prereqs->cpan_meta_prereqs->{prereqs} || {};

  for my $applyto ( @{ $self->_applyto_map_hash } ) {
    $self->_register_applyto_map_entry( $applyto, $guts );
  }
  return $prereqs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Prereqs::Recommend::MatchInstalled - Advertise versions of things you have as soft dependencies

=head1 VERSION

version 0.003003

=head1 SYNOPSIS

C<[Prereqs::MatchInstalled]> was a good concept, but its application seemed too strong for some things.

This is a variation on the same theme, but instead of upgrading dependencies in-place,
it propagates the upgrade to a different relation, to produce a softer dependency map.

Below shows the defaults expanded by hand.

    [Prereqs::Recommend::MatchInstalled]
    applyto_phase = configure
    applyto_phase = runtime
    applyto_phase = test
    applyto_phase = build
    applyto_phase = develop
    source_relation = requires
    target_relation = recommends

And add these stanzas for example:

    modules = Module::Build
    modules = Moose

And you have yourself a distribution that won't needlessly increase the dependencies
on either, but will add increased dependencies to the C<recommends> phase.

This way, people doing

    cpanm YourModule

Get only what they I<need>

While

    cpanm --with-recommends YourModule

Will get more recent things upgraded

=head1 DESCRIPTION

The C<[Prereqs::Recommend::MatchInstalled]> is a tool for authors who wish to
keep end users informed of which versions of critical dependencies the author
has themselves used, as an encouragement for the users to consume at least that
version, but without making it a hard requirement.

In practice this can be used for anything, but this modules author currently
recommends you restrict this approach only to development dependencies,
I<mostly> because even a system of auto-recommendation is still too aggressive
for most modules, or if you insist this concept on C<CPAN>, use something with
"but not larger than" mechanics like C<[Prereqs::Upgrade]>

=head1 ATTRIBUTES

=head2 C<applyto_phase>

    [Prereqs::Recommend::MatchInstalled]
    applyto_phase = SOMEPHASE
    applyto_phase = SOMEPHASE

This attribute can be specified multiple times.

Valuable values are:

    build test runtime configure develop

And those are the default values too.

=head2 C<source_relation>

    [Prereqs::Recommend::MatchInstalled]
    source_relation = requires

This attribute specifies the prerequisites to skim for modules to recommend upgrades on.

Valuable values are:

    requires recommends suggests

Lastly:

    conflicts

Will probably do I<something>, but I have no idea if that means anything. If you want to conflict with what you've installed with, ... go right ahead.

=head2 C<target_relation>

    [Prereqs::Recommend::MatchInstalled]
    target_relation = recommends

This attribute specifies the relationship type to inject upgrades into.

Valuable values are:

    requires recommends suggests

Lastly:

    conflicts

Will probably do I<something>, but I have no idea if that means anything. If you want to conflict with what you've installed
with, ... go right ahead.

=head2 C<applyto_map>

    [Prereqs::Recommend::MatchInstalled]
    applyto_map = runtime.requires = runtime.recommends

This attribute is the advanced internals of the other attributes, and it exists for insane, advanced, and niché applications.

General format is:

    applyto_map = <source_phase>.<source_relation> = <target_phase>.<target_relation>

And you can probably do everything with this.

You could also conceivably emulate C<[Prereqs::MatchInstalled]> in entirety by using this feature excessively.

C<applyto_map> may be declared multiple times.

=for Pod::Coverage mvp_aliases mvp_multivalue_args register_prereqs

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
