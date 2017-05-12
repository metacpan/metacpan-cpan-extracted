use 5.006;
use strict;
use warnings;

package Dist::Zilla::Plugin::Prereqs::Plugins;

our $VERSION = '1.003003';

# ABSTRACT: Add all Dist::Zilla plugins presently in use as prerequisites.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has around );
use Dist::Zilla::Util;
use MooseX::Types::Moose qw( HashRef ArrayRef Str );
use Dist::Zilla::Util::BundleInfo;
use Dist::Zilla::Util::ExpandINI::Reader;
use Module::Runtime qw( require_module );
use Path::Tiny qw( path );
with 'Dist::Zilla::Role::PrereqSource';





















has phase => ( is => ro =>, isa => Str, lazy => 1, default => sub { 'develop' }, );





















has relation => ( is => ro =>, isa => Str, lazy => 1, default => sub { 'requires' }, );













has exclude => ( is => ro =>, isa => ArrayRef [Str], lazy => 1, default => sub { [] } );





has _exclude_hash => ( is => ro =>, isa => HashRef [Str], lazy => 1, builder => '_build__exclude_hash' );









sub mvp_multivalue_args { return qw(exclude) }





sub _build__exclude_hash {
  my ( $self, ) = @_;
  return { map { ( $_ => 1 ) } @{ $self->exclude } };
}
around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  $localconf->{phase}    = $self->phase;
  $localconf->{relation} = $self->relation;
  $localconf->{exclude}  = $self->exclude;

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
    unless __PACKAGE__ eq ref $self;

  return $config;
};

__PACKAGE__->meta->make_immutable;
no Moose;

sub _register_plugin_prereq {
  my ( $self, $package, $lines ) = @_;
  return if exists $self->_exclude_hash->{$package};
  $self->zilla->register_prereqs( { phase => $self->phase, type => $self->relation }, $package, 0 );
  return unless @{ $lines || [] };
  while ( @{$lines} ) {
    my $key   = shift @{$lines};
    my $value = shift @{$lines};
    next unless q[:version] eq $key;
    $self->zilla->register_prereqs( { phase => $self->phase, type => $self->relation }, $package, $value );
  }
  return;
}







sub register_prereqs {
  my ($self) = @_;
  my $reader = Dist::Zilla::Util::ExpandINI::Reader->new();
  my $ini    = path( $self->zilla->root )->child('dist.ini');
  if ( not $ini->exists ) {
    $self->log_fatal(q[Prereqs::Plugins only works on dist.ini due to :version hidden since 5.032]);
    return;
  }
  my (@sections) = @{ $reader->read_file("$ini") };
  while (@sections) {
    my ($section) = shift @sections;

    # Special case for Dzil
    if ( '_' eq ( $section->{name} || q[] ) ) {
      $self->_register_plugin_prereq( q[Dist::Zilla], $section->{lines} );
      next;
    }
    my $package_expanded = Dist::Zilla::Util->expand_config_package_name( $section->{package} );

    # Standard plugin.
    if ( $section->{package} !~ /\A\@/msx ) {
      $self->_register_plugin_prereq( $package_expanded, $section->{lines} );
      next;
    }

    # Bundle
    # TODO: Maybe register the bundle itself?
    next if exists $self->_exclude_hash->{$package_expanded};

    # Handle bundle
    my $bundle = Dist::Zilla::Util::BundleInfo->new(
      bundle_name    => $section->{package},
      bundle_payload => $section->{lines},
    );

    for my $plugin ( $bundle->plugins ) {
      $self->_register_plugin_prereq( $plugin->module, [ $plugin->payload_list ] );
    }
  }
  return $self->zilla->prereqs;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Prereqs::Plugins - Add all Dist::Zilla plugins presently in use as prerequisites.

=head1 VERSION

version 1.003003

=head1 SYNOPSIS

    [Prereqs::Plugins]
    ; all plugins are now develop.requires deps

    [Prereqs::Plugins]
    phase = runtime    ; all plugins are now runtime.requires deps

=head1 DESCRIPTION

This is mostly because I am lazy, and the lengthy list of hand-updated dependencies
on my C<@Author::> bundle started to get overwhelming, and I'd periodically miss something.

This module is kinda C<AutoPrereqs>y, but in ways that I can't imagine being plausible with
a generic C<AutoPrereqs> tool, at least, not without requiring some nasty re-implementation
of how C<dist.ini> is parsed.

=head1 METHODS

=head2 C<mvp_multivalue_args>

The list of attributes that can be specified multiple times

    exclude

=head2 C<register_prereqs>

See L<<< C<< Dist::Zilla::Role::B<PrereqSource> >>|Dist::Zilla::Role::PrereqSource >>>

=head1 ATTRIBUTES

=head2 C<phase>

The target installation phase to inject into:

=over 4

=item * C<runtime>

=item * C<configure>

=item * C<build>

=item * C<test>

=item * C<develop>

=back

=head2 C<relation>

The type of dependency relation to create:

=over 4

=item * C<requires>

=item * C<recommends>

=item * C<suggests>

=item * C<conflicts>

Though think incredibly hard before using this last one ;)

=back

=head2 C<exclude>

Specify anything you want excluded here.

May Be specified multiple times.

    [Prereqs::Plugins]
    exclude = Some::Module::Thingy
    exclude = Some::Other::Module::Thingy

=head1 PRIVATE ATTRIBUTES

=head2 C<_exclude_hash>

=head1 PRIVATE METHODS

=head2 C<_build__exclude_hash>

=head1 LIMITATIONS

=over 4

=item * This module will B<NOT> report C<@Bundles> as dependencies at present.

=item * This module will B<NOT> I<necessarily> include B<ALL> dependencies, but is only intended to include the majority of them.

=item * This module will not report I<injected> dependencies, only dependencies that can be discovered from the parse tree directly, or from the return values of any indicated bundles.

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
