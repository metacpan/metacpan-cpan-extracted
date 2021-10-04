use strict;
use warnings;
use 5.022;

package Dist::Zilla::MintingProfile::AlienBuild 0.04 {

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

version 0.04

=head1 SYNOPSIS

 dzil new -P AlienBuild Alien::libfoo

=head1 DESCRIPTION

This is a L<Dist::Zilla> minting profile for creating L<Alien> distributions
based on the L<Alien::Build> framework.  It uses a reasonable template and the
L<[@Starter]|Dist::Zilla::PluginBundle::Starter> or
L<[@Starter::Git]|Dist::Zilla::PluginBundle::Starter::Git> bundle plus the
L<[AlienBuild]|Dist::Zilla::Plugin::AlienBuild> plugin.

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

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
