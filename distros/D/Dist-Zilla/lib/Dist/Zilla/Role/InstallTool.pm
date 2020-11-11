package Dist::Zilla::Role::InstallTool 6.017;
# ABSTRACT: something that creates an install program for a dist

use Moose::Role;
with qw(
  Dist::Zilla::Role::Plugin
  Dist::Zilla::Role::FileInjector
);

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod Plugins implementing InstallTool have their C<setup_installer> method called to
#pod inject files after all other file injection and munging has taken place.
#pod They're expected to produce files needed to make the distribution
#pod installable, like F<Makefile.PL> or F<Build.PL> and add them with the
#pod C<add_file> method provided by L<Dist::Zilla::Role::FileInjector>, which is
#pod also composed by this role.
#pod
#pod =cut

requires 'setup_installer';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::InstallTool - something that creates an install program for a dist

=head1 VERSION

version 6.017

=head1 DESCRIPTION

Plugins implementing InstallTool have their C<setup_installer> method called to
inject files after all other file injection and munging has taken place.
They're expected to produce files needed to make the distribution
installable, like F<Makefile.PL> or F<Build.PL> and add them with the
C<add_file> method provided by L<Dist::Zilla::Role::FileInjector>, which is
also composed by this role.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
