package Dist::Zilla::Plugin::Test::CheckManifest;
{
  $Dist::Zilla::Plugin::Test::CheckManifest::VERSION = '0.04';
}

use strict;
use warnings;

use Moose;

extends 'Dist::Zilla::Plugin::InlineFiles';

=head1 NAME

Dist::Zilla::Plugin::Test::CheckManifest - Release test for the MANIFEST

=head1 VERSION

version 0.04

=head1 SYNOPSIS

In your F<dist.ini>:

    [Test::CheckManifest]

=head1 DESCRIPTION

This Dist::Zilla plugin provides the following file:

    xt/release/check-manifest.t - a standard Test::CheckManifest test

=head1 SEE ALSO

=over

=item L<Test::CheckManifest>

=item L<Dist::Zilla::Plugin::Test::DistManifest>

=back

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

no Moose;

__PACKAGE__ -> meta -> make_immutable;

1; # End of Dist::Zilla::Plugin::Test::CheckManifest

__DATA__
___[ xt/release/check-manifest.t ]___
#!perl -T

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use Test::More;

eval "use Test::CheckManifest 1.24";
plan skip_all => "Test::CheckManifest 1.24 required for testing MANIFEST"
  if $@;

ok_manifest();
