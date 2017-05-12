use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Util::EmulatePhase;

our $VERSION = '1.001002';

#ABSTRACT: Nasty tools for probing Dist::Zilla's internal state.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Scalar::Util qw( refaddr );
use Try::Tiny;
use Sub::Exporter -setup => {
  exports => [qw( deduplicate expand_modname get_plugins get_metadata get_prereqs)],
  groups  => [ default => [qw( -all )] ],
};





















sub deduplicate {
  my ( @args, ) = @_;
  my ( %seen, @out );
  for my $item (@args) {
    push @out, $item unless exists $seen{$item};
    $seen{$item} = 1;
  }
  return @out;
}










sub expand_modname {
  ## no critic ( RegularExpressions::RequireDotMatchAnything RegularExpressions::RequireExtendedFormatting RegularExpressions::RequireLineBoundaryMatching )
  my $v = shift;
  $v =~ s/^-/Dist::Zilla::Role::/;
  $v =~ s/^=/Dist::Zilla::Plugin::/;
  return $v;
}















sub get_plugins {
  my ($config) = @_;
  if ( not $config or not exists $config->{'zilla'} ) {
    require Carp;
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    Carp::croak('get_plugins({ zilla => $something }) is a minimum requirement');
  }
  my $zilla = $config->{zilla};

  if ( not $zilla->isa('Dist::Zilla') ) {

    #require Carp;
    #Carp::cluck('get_plugins({ zilla => $something}) is not Dist::Zilla, might be a bug');
  }

  my $plugins = [];

  if ( $zilla->can('plugins') ) {
    $plugins = $zilla->plugins();
  }
  else {
    return;
  }

  if ( not @{$plugins} ) {
    return;
  }

  if ( exists $config->{'with'} ) {
    my $old_plugins = $plugins;
    $plugins = [];
    for my $with ( map { expand_modname($_) } @{ $config->{with} } ) {
      push @{$plugins}, grep { $_->does($with) } @{$old_plugins};
    }
  }

  if ( exists $config->{'skip_with'} ) {
    for my $value ( @{ $config->{'skip_with'} } ) {
      my $without = expand_modname($value);
      $plugins = [ grep { not $_->does($without) } @{$plugins} ];
    }
  }

  if ( exists $config->{'isa'} ) {
    my $old_plugins = $plugins;
    $plugins = [];
    for my $isa_package ( @{ $config->{isa} } ) {
      my $isa = expand_modname($isa_package);
      push @{$plugins}, grep { $_->isa($isa) } @{$old_plugins};
    }
  }

  if ( exists $config->{'skip_isa'} ) {
    for my $value ( @{ $config->{'skip_isa'} } ) {
      my $isnt = expand_modname($value);
      $plugins = [ grep { not $_->isa($isnt) } @{$plugins} ];
    }
  }

  return deduplicate( @{$plugins} );
}





















sub get_metadata {
  my ($config) = @_;
  if ( not $config or not exists $config->{'zilla'} ) {
    require Carp;
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    Carp::croak('get_metadata({ zilla => $something }) is a minimum requirement');
  }
  $config->{with} = [] unless exists $config->{'with'};
  push @{ $config->{'with'} }, '-MetaProvider';
  my @plugins = get_plugins($config);
  my $meta    = {};
  for my $value (@plugins) {
    require Hash::Merge::Simple;
    $meta = Hash::Merge::Simple::merge( $meta, $value->metadata );
  }
  return $meta;
}





















sub get_prereqs {
  my ($config) = @_;
  if ( not $config or not exists $config->{'zilla'} ) {
    require Carp;
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    Carp::croak('get_prereqs({ zilla => $something }) is a minimum requirement');
  }

  $config->{'with'} = [] unless exists $config->{'with'};
  push @{ $config->{'with'} }, '-PrereqSource';
  my @plugins = get_plugins($config);

  # This is a bit nasty, because prereqs call back into their data and mess with zilla :/
  require Dist::Zilla::Util::EmulatePhase::PrereqCollector;
  my $zilla = Dist::Zilla::Util::EmulatePhase::PrereqCollector->new( shadow_zilla => $config->{zilla} );
  for my $value (@plugins) {
    {    # subverting!
      ## no critic ( Variables::ProhibitLocalVars )
      local $value->{zilla} = $zilla;
      $value->register_prereqs;
    }
    if ( refaddr($zilla) eq refaddr( $value->{zilla} ) ) {
      require Carp;
      Carp::croak('Zilla did not reset itself');
    }
  }
  $zilla->prereqs->finalize;
  return $zilla->prereqs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::EmulatePhase - Nasty tools for probing Dist::Zilla's internal state.

=head1 VERSION

version 1.001002

=head1 METHODS

=head2 deduplicate

Internal utility that de-duplicates references by ref-addr alone.

  my $array = [];
  is_deeply( [ deduplicate( $array, $array ) ],[ $array ] )

=head2 expand_modname

Internal utility to expand various shorthand notations to full ones.

  expand_modname('-MetaProvider') == 'Dist::Zilla::Role::MetaProvider';
  expand_modname('=MetaNoIndex')  == 'Dist::Zilla::Plugin::MetaNoIndex';

=head2 get_plugins

Probe Dist::Zilla's plugin registry and get items matching a specification

  my @plugins = get_plugins({
    zilla     => $self->zilla,
    with      => [qw( -MetaProvider -SomethingElse     )],
    skip_with => [qw( -SomethingBadThatIsAMetaProvider )],
    isa       => [qw( =SomePlugin   =SomeOtherPlugin   )],
    skip_isa  => [qw( =OurPlugin                       )],
  });

=head2 get_metadata

Emulates Dist::Zilla's internal metadata aggregation and does it all again.

Minimum Usage:

  my $metadata = get_metadata({ zilla => $self->zilla });

Extended usage:

  my $metadata = get_metadata({
    $zilla = $self->zilla,
     ... more params to get_plugins ...
     ... ie: ...
     with => [qw( -MetaProvider )],
     isa  => [qw( =MetaNoIndex )],
   });

=head2 get_prereqs

Emulates Dist::Zilla's internal prereqs aggregation and does it all again.

Minimum Usage:

  my $prereqs = get_prereqs({ zilla => $self->zilla });

Extended usage:

  my $metadata = get_prereqs({
    $zilla = $self->zilla,
     ... more params to get_plugins ...
     ... ie: ...
     with => [qw( -PrereqSource )],
     isa  => [qw( =AutoPrereqs )],
   });

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Util::EmulatePhase",
    "interface":"exporter"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
