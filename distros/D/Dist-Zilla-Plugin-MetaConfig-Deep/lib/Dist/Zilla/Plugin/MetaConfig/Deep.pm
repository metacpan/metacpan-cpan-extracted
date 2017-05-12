use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::MetaConfig::Deep;

our $VERSION = '0.001001';

# ABSTRACT: Experimental enhancements to MetaConfig

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with );

with 'Dist::Zilla::Role::MetaProvider';

sub _metadata_perl { return { version => $] } }

sub _metadata_zilla {
  my ($self) = @_;

  my $config   = $self->zilla->dump_config;
  my $composed = $self->_metadata_class_composes( $self->zilla );

  return {
    class   => $self->zilla->meta->name,
    version => $self->zilla->VERSION,
    ( keys %{$config}   ? ( config     => $config )   : () ),
    ( keys %{$composed} ? ( x_composes => $composed ) : () ),
  };
}

sub _metadata_plugins {
  my ($self) = @_;
  return [ map { $self->_metadata_plugin($_) } @{ $self->zilla->plugins } ];
}

sub _metadata_class_composes {
  my ( undef, $plugin ) = @_;

  my $composed = {};
  for my $component ( $plugin->meta->calculate_all_roles_with_inheritance ) {
    next if $component->name =~ /[|]|_ANON_/sx;    # skip unions and anon classes
    $composed->{ $component->name } = $component->name->VERSION;
  }
  for my $component ( $plugin->meta->linearized_isa ) {
    next if $component->meta->name =~ /[|]|_ANON_/sx;         # skip unions.
    next if $component->meta->name eq $plugin->meta->name;    # skip self
    $composed->{ $component->meta->name } = $component->meta->name->VERSION;
  }

  return $composed;
}

sub _metadata_plugin {
  my ( $self, $plugin ) = @_;
  my $config   = $plugin->dump_config;
  my $composed = $self->_metadata_class_composes($plugin);
  return {
    class   => $plugin->meta->name,
    name    => $plugin->plugin_name,
    version => $plugin->VERSION,
    ( keys %{$config}   ? ( config     => $config )   : () ),
    ( keys %{$composed} ? ( x_composes => $composed ) : () ),
  };
}





sub metadata {
  my ($self) = @_;

  my $dump = {};

  $dump->{zilla}   = $self->_metadata_zilla;
  $dump->{perl}    = $self->_metadata_perl;
  $dump->{plugins} = $self->_metadata_plugins;

  return { x_Dist_Zilla => $dump };
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MetaConfig::Deep - Experimental enhancements to MetaConfig

=head1 VERSION

version 0.001001

=head1 DESCRIPTION

This module serves as an experimental space for features I think the core MetaConfig I<should>
provide, but in a state of uncertainty about how they should be implemented.

The objective is to extract more metadata about plugins without plugins having to percolate
hand-written adjustments system-wide to get a useful interface.

=head2 Composition Data

This exposes data about the roles and parent classes, and their respective versions in play
on a given plugin, to give greater depth for problem diagnosis.

  {
    "class" : "Dist::Zilla::Plugin::Author::KENTNL::CONTRIBUTING",
    "config" : {...},
    "name" : "@Author::KENTNL/Author::KENTNL::CONTRIBUTING",
    "version" : "0.001005",
    "x_composes" : {
      "Dist::Zilla::Plugin::GenerateFile::FromShareDir" : "0.009",
      "Dist::Zilla::Role::AfterBuild"                   : "5.041",
      "Dist::Zilla::Role::AfterRelease"                 : "5.041",
      "Dist::Zilla::Role::ConfigDumper"                 : "5.041",
      "Dist::Zilla::Role::FileGatherer"                 : "5.041",
      "Dist::Zilla::Role::FileInjector"                 : "5.041",
      "Dist::Zilla::Role::FileMunger"                   : "5.041",
      "Dist::Zilla::Role::Plugin"                       : "5.041",
      "Dist::Zilla::Role::RepoFileInjector"             : "0.005",
      "Dist::Zilla::Role::TextTemplate"                 : "5.041",
      "Moose::Object"                                   : "2.1604",
      "MooseX::SlurpyConstructor::Role::Object"         : "1.2"
    }
  }

C<@ETHER> has already made excellent inroads into making this sort of metadata exposed
via exporting C<version> in all C<metaconfig> plugin's she has access to, and this is an attempt
at providing the same level of insight without requiring so much explicit buy-in from plugin authors.

This also has the neat side effect of showing what phases a plug-in is subscribed to.

=for Pod::Coverage metadata

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
