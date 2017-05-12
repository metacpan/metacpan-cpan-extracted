package Dist::Zilla::MintingProfile::Author::YAKEX;

use strict;
use warnings;

# ABSTRACT: Dist::Zilla minting profile the way YAKEX does it
our $VERSION = 'v0.1.5'; # VERSION

use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=head1 NAME

Dist::Zilla::MintingProfile::Author::YAKEX - Dist::Zilla minting profile the way YAKEX does it

=head1 VERSION

version v0.1.5

=head1 SYNOPSIS

  dzil new -P Author:YAKEX Your::Dist::Name

=head1 DESCRIPTION

This is a L<Dist::Zilla> MintingProfile used by YAKEX's distribution. It setups the following files:

  .gitignore
  Changes
  MANIFEST.SKIP
  dist.ini
  perlcritic.rc
  weaver.ini

in addition to the distribution main module.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Role::MintingProfile>

=item *

L<Dist::Zilla::PluginBundle::Author::YAKEX>

=back

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
