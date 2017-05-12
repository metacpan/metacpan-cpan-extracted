use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::Prereqs::Upgrade;

our $VERSION = '0.001001';

# ABSTRACT: Upgrade existing prerequisites in place

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has with around );
use Scalar::Util qw( blessed );
use Dist::Zilla::Util::ConfigDumper qw( config_dumper );

with 'Dist::Zilla::Role::PrereqSource';

sub _defaulted {
  my ( $name, $type, $default, @rest ) = @_;
  return has $name, is => 'ro', isa => $type, init_arg => q[-] . $name, lazy => 1, default => $default, @rest;
}

sub _builder {
  my ( $name, $type, @rest ) = @_;
  return has $name, is => 'ro', isa => $type, init_arg => q[-] . $name, 'lazy_build' => 1, @rest;
}

has 'modules' => (
  is       => 'ro',
  isa      => 'HashRef[Str]',
  init_arg => '-modules',
  required => 1,
  traits   => [qw( Hash )],
  handles  => {
    '_user_wants_upgrade_on' => 'exists',
    '_wanted_minimum_on'     => 'get',
  },
);

_defaulted 'applyto_phase'   => 'ArrayRef[Str]' => sub { [qw(build test runtime configure develop)] };
_defaulted 'target_relation' => 'Str'           => sub { 'recommends' };
_defaulted 'source_relation' => 'Str'           => sub { 'requires' };

_builder 'applyto_map' => 'ArrayRef[Str]';
_builder _applyto_map_pairs => 'ArrayRef[HashRef]', init_arg => undef;

around dump_config => config_dumper( __PACKAGE__,
  {
    attrs => [qw( modules applyto_map applyto_phase target_relation source_relation )],
  },
);

__PACKAGE__->meta->make_immutable;
no Moose;





sub mvp_multivalue_args { return qw(-applyto_map -applyto_phase) }

sub register_prereqs {
  my ($self)  = @_;
  my $zilla   = $self->zilla;
  my $prereqs = $zilla->prereqs;
  my $guts = $prereqs->cpan_meta_prereqs->{prereqs} || {};

  for my $applyto ( @{ $self->_applyto_map_pairs } ) {
    $self->_register_applyto_map_entry( $applyto, $guts );
  }
  return $prereqs;
}

sub BUILDARGS {
  my ( undef, $config, @extra ) = @_;
  if ( 'HASH' ne ( ref $config || q[] ) or scalar @extra ) {
    $config = { $config, @extra };
  }
  my $modules = {};
  for my $key ( keys %{$config} ) {
    next if $key =~ /\A-/msx;
    next if 'plugin_name' eq $key;
    next if blessed $config->{$key};
    next if 'zilla' eq $key;
    $modules->{$key} = delete $config->{$key};
  }
  return { '-modules' => $modules, %{$config} };
}

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
    my $v = $self->_wanted_minimum_on($module);

    # Get the original requirement and see if applying the new minimum changes anything
    my $fake_target = $prereqs->{$phase}->{$rel}->clone;
    my $old_string  = $fake_target->as_string_hash->{$module};
    $fake_target->add_string_requirement( $module, $v );

    # Dep changed in the effective source spec
    next if $fake_target->as_string_hash->{$module} eq $old_string;

    $self->log_debug( [ 'Upgrading %s %s to %s', $module, "$old_string", "$v" ] );

    # Apply the change to the target spec to to it being an upgrade.
    $self->zilla->register_prereqs( $targetspec, $module, $fake_target->as_string_hash->{$module} );
  }
  return $self;
}

sub _build_applyto_map {
  my ($self) = @_;
  my (@out);
  for my $phase ( @{ $self->applyto_phase } ) {
    push @out, sprintf '%s.%s = %s.%s', $phase, $self->source_relation, $phase, $self->target_relation;
  }
  return \@out;
}

# _Pulp__5010_qr_m_propagate_properly
## no critic (Compatibility::PerlMinimumVersionAndWhy)
my $re_phase    = qr/configure|build|runtime|test|develop/msx;
my $re_relation = qr/requires|recommends|suggests|conflicts/msx;

my $combo = qr/(?:$re_phase)[.](?:$re_relation)/msx;

sub _parse_map_token {
  my ( $self,  $token )    = @_;
  my ( $phase, $relation ) = $token =~ /\A($re_phase)[.]($re_relation)/msx;
  if ( not defined $phase or not defined $relation ) {
    return $self->log_fatal( [ '%s is not in the form <phase.relation>', $token ] );
  }
  return { phase => $phase, relation => $relation, };
}

sub _parse_map_entry {
  my ( $self,   $entry )  = @_;
  my ( $source, $target ) = $entry =~ /\A\s*($combo)\s*=\s*($combo)\s*\z/msx;
  if ( not defined $source or not defined $target ) {
    return $self->log_fatal( [ '%s is not a valid entry for -applyto_map', $entry ] );
  }
  return {
    source => $self->_parse_map_token($source),
    target => $self->_parse_map_token($target),
  };
}

sub _build__applyto_map_pairs {
  my ($self) = @_;
  return [ map { $self->_parse_map_entry($_) } @{ $self->applyto_map } ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Prereqs::Upgrade - Upgrade existing prerequisites in place

=head1 VERSION

version 0.001001

=head1 DESCRIPTION

This allows you to automatically upgrade selected prerequisites
to selected versions, if, and only if, they're already prerequisites.

This is intended to be used to compliment C<[AutoPrereqs]> without adding dependencies.

  [AutoPrereqs]

  [Prereqs::Upgrade]
  Moose = 2.0 ; Moose 2.0 is added as a minimum to runtime.recommends to 2.0 if a lower version is in runtime.requires

This is intended to be especially helpful in C<PluginBundle>'s where one may habitually
always want a certain version of a certain dependency every time they use it, but don't want to be burdened
with remembering to encode that version of it.

=for Pod::Coverage mvp_multivalue_args register_prereqs

=head1 USAGE

=head2 BASICS

For most cases, all you'll need to do is:

  [Prereqs::Upgrade]
  My::Module = Version Spec that is recommended

And then everything in C<PHASE.requires> will be copied to C<PHASE.recommends>
if it is determined that doing so will cause the dependency to be changed.

For instance, you may want to do:

  [Prereqs::Upgrade]
  Moose = 2.0
  Moo   = 1.008001

Note that this will not imply Moo unless Moo is B<ALREADY> a requirement, and won't imply Moose unless Moose is B<ALREADY>
a requirement.

And this will transform:

  { runtime: { requires: { Moose: 0 }}

Into

  { runtime: {
         requires:   { Moose: 0 },
         recommends: { Moose: 2.0 }
  }}

=head3 C<-target_relation>

By default, the target relationship type is C<recommends>.

However, this can be adjusted with the C<-target_relation> attribute.

  [Prereqs::Upgrade]
  ; -target_relation = requires ; Not recommended and way more strict
  -target_relation = suggests   ; Makes upgrades suggestions instead of recommendations
  Moose = 2.0
  Moo   = 1.008001

=head3 C<-source_relation>

By default, this tool assumes you have a single relation type
that you wish to translate into a  L<< C<target>|/-target_relation >>,
and thus the default C<-source_relation> is C<requires>.

  [Prereqs::Upgrade]
  ; This example doesn't make much sense but it would work
  -source_relation = recommends
  -target_relation = suggests
  Moose = 2.0

This would add a C<PHASE.suggests> upgrade to C<2.0> if C<Moose> was found in C<PHASE.recommends>

=head3 C<-applyto_phase>

By default, this tool applies upgrades from C<-source_relation> to C<-target_relation>
C<foreach> C<-applyto_phase>, and this lists default contents is:

  [Prereqs::Upgrade]
  -applyto_phase = build
  -applyto_phase = configure
  -applyto_phase = test
  -applyto_phase = runtime
  -applyto_phase = develop

=head2 ADVANCED USAGE

=head3 C<-applyto_map>

Advanced users can define arbitrary transform maps, which the L<basic|/BASIC USAGE> parameters
are simplified syntax for.

Under the hood, you can define any source C<PHASE.RELATION> and map it as an upgrade to any target C<PHASE.RELATION>, even if it doesn't make much sense to do so.

This section is material that often seems like C<YAGNI> but I find I end up needing it somewhere,
because its not very straight forward to demonstrate a simple case where it would be useful.

However, in this example: If a distribution uses Moose, then the distribution itself is permitted to have version = C<0>

But a C<runtime.recommends> of C<2.0> is injected, and a C<develop.requires> of C<2.0> is injected.

  [Prereqs::Upgrade]
  -applyto_map = runtime.requires = runtime.recommends
  -applyto_map = runtime.requires = develop.requires
  Moose = 2.0

=head1 SEE ALSO

=over 4

=item * L<< C<[Prereqs::MatchInstalled]>|Dist::Zilla::Plugin::Prereqs::MatchInstalled >>

Upgrades stated dependencies to whatever you have installed, which is
significantly more flippant than having some auto-upgrading base versions.

=item * L<< C<[Prereqs::Recommend::MatchInstalled]>|Dist::Zilla::Plugin::Prereqs::Recommend::MatchInstalled >>

Like the above, except supports C<requires> → C<recommends> translation ( and does that by default )

=item * L<< C<[Prereqs::MatchInstalled::All]>|Dist::Zilla::Plugin::Prereqs::MatchInstalled::All >>

The most hateful way you can request C<CPAN> to install all the latest things for your module.

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
