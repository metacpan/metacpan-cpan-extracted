package Dist::Zilla::Role::Plugin 6.032;
# ABSTRACT: something that gets plugged in to Dist::Zilla

use Moose::Role;
with 'Dist::Zilla::Role::ConfigDumper';

use Dist::Zilla::Pragmas;

use Params::Util qw(_HASHLIKE);
use Moose::Util::TypeConstraints 'class_type';

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod The Plugin role should be applied to all plugin classes.  It provides a few key
#pod methods and attributes that all plugins will need.
#pod
#pod =attr plugin_name
#pod
#pod The plugin name is generally determined when configuration is read.
#pod
#pod =cut

has plugin_name => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

#pod =attr zilla
#pod
#pod This attribute contains the Dist::Zilla object into which the plugin was
#pod plugged.
#pod
#pod =cut

has zilla => (
  is  => 'ro',
  isa => class_type('Dist::Zilla'),
  required => 1,
  weak_ref => 1,
);

#pod =method log
#pod
#pod The plugin's C<log> method delegates to the Dist::Zilla object's
#pod L<Dist::Zilla/log> method after including a bit of argument-munging.
#pod
#pod =cut

has logger => (
  is   => 'ro',
  lazy => 1,
  handles => [ qw(log log_debug log_fatal) ],
  default => sub {
    $_[0]->zilla->chrome->logger->proxy({
      proxy_prefix => '[' . $_[0]->plugin_name . '] ',
    });
  },
);

# We define these effectively-pointless subs here to allow other roles to
# modify them with around. -- rjbs, 2010-03-21
sub mvp_multivalue_args {};
sub mvp_aliases         { return {} };

sub plugin_from_config {
  my ($class, $name, $arg, $section) = @_;

  my $self = $class->new({
    %$arg,
    plugin_name => $name,
    zilla       => $section->sequence->assembler->zilla,
  });
}

sub register_component {
  my ($class, $name, $arg, $section) = @_;

  my $self = $class->plugin_from_config($name, $arg, $section);

  my $version = $self->VERSION || 0;

  $self->log_debug([ 'online, %s v%s', $self->meta->name, $version ]);

  push @{ $self->zilla->plugins }, $self;

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Plugin - something that gets plugged in to Dist::Zilla

=head1 VERSION

version 6.032

=head1 DESCRIPTION

The Plugin role should be applied to all plugin classes.  It provides a few key
methods and attributes that all plugins will need.

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

=head2 plugin_name

The plugin name is generally determined when configuration is read.

=head2 zilla

This attribute contains the Dist::Zilla object into which the plugin was
plugged.

=head1 METHODS

=head2 log

The plugin's C<log> method delegates to the Dist::Zilla object's
L<Dist::Zilla/log> method after including a bit of argument-munging.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
