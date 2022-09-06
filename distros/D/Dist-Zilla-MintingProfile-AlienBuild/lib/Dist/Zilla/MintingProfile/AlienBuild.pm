use strict;
use warnings;
use 5.022;

package Dist::Zilla::MintingProfile::AlienBuild 0.07 {

  use Moose;
  with 'Dist::Zilla::Role::MintingProfile::ShareDir';
  use namespace::autoclean;

  # ABSTRACT: A minimal Dist::Zilla minting profile for Aliens

  __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::AlienBuild - A minimal Dist::Zilla minting profile for Aliens

=head1 VERSION

version 0.07

=head1 SYNOPSIS

 dzil new -P AlienBuild Alien::libfoo

=head1 DESCRIPTION

This is a L<Dist::Zilla> minting profile for creating L<Alien> distributions
based on the L<Alien::Build> framework.  It uses a reasonable template and the
L<[@Starter]|Dist::Zilla::PluginBundle::Starter> or
L<[@Starter::Git]|Dist::Zilla::PluginBundle::Starter::Git> bundle plus the
L<[AlienBuild]|Dist::Zilla::Plugin::AlienBuild> plugin.

=head1 CAVEATS

This module indirectly requires both L<Alien::FFI> and L<Alien::Archive3>.  If
you do not want to build them from source, or do not have internet access where
the build is happening you will want to pre-install C<libffi> and C<libarchive>.
On Debian based systems, you can do that with
C<sudo apt-get update && sudo apt-get install libffi-dev libarchive-dev>.  Note
that libarchive 3.2.0 is required for a system install so if you have an older
Debian or Ubuntu system you should upgrade your operating system.

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<Alien::Build>

=item L<alienfile>

=item L<[@Starter]|Dist::Zilla::PluginBundle::Starter>

=item L<[@Starter::Git]|Dist::Zilla::PluginBundle::Starter::Git>

=item L<[AlienBuild]|Dist::Zilla::Plugin::AlienBuild>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
