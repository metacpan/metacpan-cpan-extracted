use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::if::not::ENV;

our $VERSION = '0.001001';

# ABSTRACT: Load a plugin when an ENV key is NOT true.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has around with );
use Dist::Zilla::Util qw();
with 'Dist::Zilla::Role::PluginLoader::Configurable';

has key => ( is => ro =>, required => 1 );

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  $localconf->{key} = $self->key;

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
    unless __PACKAGE__ eq ref $self;

  return $config;
};

around load_plugins => sub {
  my ( $orig, $self, $loader ) = @_;
  my $key = $self->key;
  return if exists $ENV{$key} and $ENV{$key};
  return $self->$orig($loader);
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::if::not::ENV - Load a plugin when an ENV key is NOT true.

=head1 VERSION

version 0.001001

=head1 SYNOPSIS

  [if::not::ENV]
  key            = AIRPLANE
  dz_plugin      = Some::Plugin
  dz_plugin_name = NOTAIRPLANE/Some::Plugin
  >= some_plugin_argument = itsvalue
  >= some_plugin_argument = itsvalue

Then

  dzil build # Some::Plugin is loaded
  AIRPLANE=1 dzil build # Some::Plugin NOT loaded!... but still a develop dep.
  AIRPLANE=0 dzil build # Some::Plugin loaded

=head2 SEE ALSO

=over 4

=item * C<[if]> - L<< Dist::Zilla::Plugin::if|Dist::Zilla::Plugin::if >>

=item * C<[if::not]> - L<< Dist::Zilla::Plugin::if::not|Dist::Zilla::Plugin::if::not >>

=item * C<[if::ENV]> - L<< Dist::Zilla::Plugin::if::ENV|Dist::Zilla::Plugin::if::ENV >>

=item * C<PluginLoader::Configurable role> - L<<
Dist::Zilla::Role::PluginLoader::Configurable|Dist::Zilla::Role::PluginLoader::Configurable
>>

=item * C<PluginLoader role> - L<< Dist::Zilla::Role::PluginLoader|Dist::Zilla::Role::PluginLoader >>

=item * C<PluginLoader util> - L<< Dist::Zilla::Util::PluginLoader|Dist::Zilla::Util::PluginLoader >>

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
