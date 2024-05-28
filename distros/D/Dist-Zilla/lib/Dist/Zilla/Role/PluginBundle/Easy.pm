package Dist::Zilla::Role::PluginBundle::Easy 6.032;
# ABSTRACT: something that bundles a bunch of plugins easily
# This plugin was originally contributed by Christopher J. Madsen

use Moose::Role;
with 'Dist::Zilla::Role::PluginBundle';

use Dist::Zilla::Pragmas;

use Module::Runtime 'use_module';
use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod   package Dist::Zilla::PluginBundle::Example;
#pod   use Moose;
#pod   with 'Dist::Zilla::Role::PluginBundle::Easy';
#pod
#pod   sub configure {
#pod     my $self = shift;
#pod
#pod     $self->add_plugins('VersionFromModule');
#pod     $self->add_bundle('Basic');
#pod   }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This role builds upon the PluginBundle role, adding methods to take most of the
#pod grunt work out of creating a bundle.  It supplies the C<bundle_config> method
#pod for you.  In exchange, you must supply a C<configure> method, which will store
#pod the bundle's configuration in the C<plugins> attribute by calling
#pod C<add_plugins> and/or C<add_bundle>.
#pod
#pod =cut

use MooseX::Types::Moose qw(Str ArrayRef HashRef);

use String::RewritePrefix 0.005
  rewrite => {
    -as => '_plugin_class',
    prefixes => {
      '=' => '',
      '%' => 'Dist::Zilla::Stash::',
      '' => 'Dist::Zilla::Plugin::',
    },
  },
  rewrite => {
    -as => '_bundle_class',
    prefixes => {
      ''  => 'Dist::Zilla::PluginBundle::',
      '@' => 'Dist::Zilla::PluginBundle::',
      '=' => ''
    },
  };

requires 'configure';

#pod =attr name
#pod
#pod This is the bundle name, taken from the Section passed to
#pod C<bundle_config>.
#pod
#pod =cut

has name => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

#pod =attr payload
#pod
#pod This hashref contains the bundle's parameters (if any), taken from the
#pod Section passed to C<bundle_config>.
#pod
#pod =cut

has payload => (
  is       => 'ro',
  isa      => HashRef,
  required => 1,
);

#pod =attr plugins
#pod
#pod This arrayref contains the configuration that will be returned by
#pod C<bundle_config>.  You normally modify this by using the
#pod C<add_plugins> and C<add_bundle> methods.
#pod
#pod =cut

has plugins => (
  is       => 'ro',
  isa      => ArrayRef,
  default  => sub { [] },
);

sub bundle_config {
  my ($class, $section) = @_;

  my $self = $class->new($section);

  $self->configure;

  return $self->plugins->@*;
}

#pod =method add_plugins
#pod
#pod   $self->add_plugins('Plugin1', [ Plugin2 => \%plugin2config ])
#pod
#pod Use this method to add plugins to your bundle.
#pod
#pod It is passed a list of plugin specifiers, which can be one of a few things:
#pod
#pod =for :list
#pod * a plugin moniker (like you might provide in your config file)
#pod * an arrayref of: C<< [ $moniker, $plugin_name, \%plugin_config ] >>
#pod
#pod In the case of an arrayref, both C<$plugin_name> and C<\%plugin_config> are
#pod optional.
#pod
#pod The plugins are added to the config in the order given.
#pod
#pod =cut

sub add_plugins {
  my ($self, @plugin_specs) = @_;

  my $prefix  = $self->name . '/';
  my $plugins = $self->plugins;

  foreach my $this_spec (@plugin_specs) {
    my $moniker;
    my $name;
    my $payload;

    if (! ref $this_spec) {
      ($moniker, $name, $payload) = ($this_spec, $this_spec, {});
    } elsif (@$this_spec == 1) {
      ($moniker, $name, $payload) = ($this_spec->[0], $this_spec->[0], {});
    } elsif (@$this_spec == 2) {
      $moniker = $this_spec->[0];
      $name    = ref $this_spec->[1] ? $moniker : $this_spec->[1];
      $payload = ref $this_spec->[1] ? $this_spec->[1] : {};
    } else {
      ($moniker, $name, $payload) = @$this_spec;
    }

    push @$plugins, [ $prefix . $name => _plugin_class($moniker) => $payload ];
  }
}

#pod =method add_bundle
#pod
#pod   $self->add_bundle(BundleName => \%bundle_config)
#pod
#pod Use this method to add all the plugins from another bundle to your bundle.  If
#pod you omit C<%bundle_config>, an empty hashref will be supplied.
#pod
#pod =cut

sub add_bundle {
  my ($self, $bundle, $payload) = @_;

  my $package = _bundle_class($bundle);
  $payload ||= {};

  &use_module(
    $package,
    $payload->{':version'} ? $payload->{':version'} : (),
  );

  $bundle = "\@$bundle" unless $bundle =~ /^@/;

  push $self->plugins->@*,
    $package->bundle_config({
      name    => $self->name . '/' . $bundle,
      package => $package,
      payload => $payload,
    });
}

#pod =method config_slice
#pod
#pod   $hash_ref = $self->config_slice(arg1, { arg2 => 'plugin_arg2' })
#pod
#pod Use this method to extract parameters from your bundle's C<payload> so
#pod that you can pass them to a plugin or subsidiary bundle.  It supports
#pod easy renaming of parameters, since a plugin may expect a parameter
#pod name that's too generic to be suitable for a bundle.
#pod
#pod Each arg is either a key in C<payload>, or a hashref that maps keys in
#pod C<payload> to keys in the hash being constructed.  If any specified
#pod key does not exist in C<payload>, then it is omitted from the result.
#pod
#pod =cut

sub config_slice {
  my $self = shift;

  my $payload = $self->payload;

  my %arg;

  foreach my $arg (@_) {
    if (ref $arg) {
      while (my ($in, $out) = each %$arg) {
        $arg{$out} = $payload->{$in} if exists $payload->{$in};
      }
    } else {
      $arg{$arg} = $payload->{$arg} if exists $payload->{$arg};
    }
  }

  return \%arg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::PluginBundle::Easy - something that bundles a bunch of plugins easily

=head1 VERSION

version 6.032

=head1 SYNOPSIS

  package Dist::Zilla::PluginBundle::Example;
  use Moose;
  with 'Dist::Zilla::Role::PluginBundle::Easy';

  sub configure {
    my $self = shift;

    $self->add_plugins('VersionFromModule');
    $self->add_bundle('Basic');
  }

=head1 DESCRIPTION

This role builds upon the PluginBundle role, adding methods to take most of the
grunt work out of creating a bundle.  It supplies the C<bundle_config> method
for you.  In exchange, you must supply a C<configure> method, which will store
the bundle's configuration in the C<plugins> attribute by calling
C<add_plugins> and/or C<add_bundle>.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 ATTRIBUTES

=head2 name

This is the bundle name, taken from the Section passed to
C<bundle_config>.

=head2 payload

This hashref contains the bundle's parameters (if any), taken from the
Section passed to C<bundle_config>.

=head2 plugins

This arrayref contains the configuration that will be returned by
C<bundle_config>.  You normally modify this by using the
C<add_plugins> and C<add_bundle> methods.

=head1 METHODS

=head2 add_plugins

  $self->add_plugins('Plugin1', [ Plugin2 => \%plugin2config ])

Use this method to add plugins to your bundle.

It is passed a list of plugin specifiers, which can be one of a few things:

=over 4

=item *

a plugin moniker (like you might provide in your config file)

=item *

an arrayref of: C<< [ $moniker, $plugin_name, \%plugin_config ] >>

=back

In the case of an arrayref, both C<$plugin_name> and C<\%plugin_config> are
optional.

The plugins are added to the config in the order given.

=head2 add_bundle

  $self->add_bundle(BundleName => \%bundle_config)

Use this method to add all the plugins from another bundle to your bundle.  If
you omit C<%bundle_config>, an empty hashref will be supplied.

=head2 config_slice

  $hash_ref = $self->config_slice(arg1, { arg2 => 'plugin_arg2' })

Use this method to extract parameters from your bundle's C<payload> so
that you can pass them to a plugin or subsidiary bundle.  It supports
easy renaming of parameters, since a plugin may expect a parameter
name that's too generic to be suitable for a bundle.

Each arg is either a key in C<payload>, or a hashref that maps keys in
C<payload> to keys in the hash being constructed.  If any specified
key does not exist in C<payload>, then it is omitted from the result.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
