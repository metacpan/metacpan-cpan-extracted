package Dist::Zilla::MintingProfile::Author::TABULO;

use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';
use namespace::clean;

our $VERSION = '1.000012';

__PACKAGE__->meta->make_immutable;
1;

#ABSTRACT: A minimal Dist::Zilla minting profile for TABULO

__END__

=pod

=encoding UTF-8

=for :stopwords Tabulo[n]

=head1 NAME

Dist::Zilla::MintingProfile::Author::TABULO - A minimal Dist::Zilla minting profile for TABULO

=head1 VERSION

version 1.000012

=head1 FOREWORD

This is a minting profile used for TABULO's distributions.

Like his dzil plugin-bundle, it was heavily inspired/copied from several other sources, and here, especially from: L<Dist::Zilla::MintingProfile::Starter>,  L<Dist::Zilla::MintingProfile::Starter::Git>

Thank you @DBOOK!

=head2 WARNING

Please note that, although this module needs to be on CPAN for obvious reasons,
it is really intended to be a collection of personal preferences, which are
expected to be in great flux, at least for the time being.

Therefore, please do NOT base your own distributions on this one, since anything
can change at any moment without prior notice, while I get accustomed to dzil
myself and form those preferences in the first place...
Absolutely nothing in this distribution is guaranteed to remain constant or
be maintained at this point. Who knows, I may even give up on dzil altogether...

You have been warned.

=head1 SYNOPSIS

  # setup only needs to be run once to set up your dzil config
  $ dzil setup
  $ dzil new -P Author::TABULO My::New::Dist

=head1 DESCRIPTION

This minting profile for L<< C<dzil new>|Dist::Zilla::App::Command::new >>
creates a minimal new distribution consisting of a basic C<dist.ini> using the
L<[@Author::TABULO]|Dist::Zilla::PluginBundle::Author::TABULO> plugin bundle, and a skeleton
for the main module and its documentation.

The author, license, and copyright
will be populated in the C<dist.ini> and documentation from the current dzil
C<config.ini>, which can be initialized using
L<< C<dzil setup>|Dist::Zilla::App::Command::setup >>. The version is
initialized statically as C<0.001>.

=head1 CUSTOMIZING

It's easy to create your own local version of this (or any other) minting
profile which you can customize as you choose.

See L<Dist::Zilla::MintingProfile::Starter> for recipes on customization.

=head1 SEE ALSO

L<Dist::Zilla>, L<Dist::Zilla::MintingProfile::Starter>,  L<Dist::Zilla::MintingProfile::Starter::Git>, L<Dist::Zilla::PluginBundle::Starter>

=head1 AUTHORS

Tabulo[n] <dev@tabulo.net>

=head1 LEGAL

This software is copyright (c) 2023 by Tabulo[n].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
