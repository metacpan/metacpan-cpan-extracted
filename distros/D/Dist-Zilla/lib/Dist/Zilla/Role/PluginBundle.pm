package Dist::Zilla::Role::PluginBundle 6.032;
# ABSTRACT: something that bundles a bunch of plugins

use Moose::Role;

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod When loading configuration, if the config reader encounters a PluginBundle, it
#pod will replace its place in the plugin list with the result of calling its
#pod C<bundle_config> method, which will be passed a Config::MVP::Section to
#pod configure the bundle.
#pod
#pod =cut

sub register_component {
  my ($class, $name, $arg, $self) = @_;
  # ... we should register a placeholder so MetaConfig can tell us about the
  # pluginbundle that was loaded
}

requires 'bundle_config';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::PluginBundle - something that bundles a bunch of plugins

=head1 VERSION

version 6.032

=head1 DESCRIPTION

When loading configuration, if the config reader encounters a PluginBundle, it
will replace its place in the plugin list with the result of calling its
C<bundle_config> method, which will be passed a Config::MVP::Section to
configure the bundle.

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

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
