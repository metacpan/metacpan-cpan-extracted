use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::DistManifest;
# ABSTRACT: Release tests for the manifest
our $VERSION = '2.000005'; # VERSION
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::DistManifest - Release tests for the manifest

=head1 VERSION

version 2.000005

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::DistManifest]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

  xt/release/dist-manifest.t - a standard Test::DistManifest test

=for test_synopsis 1;
__END__

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/Dist-Zilla-Plugin-Test-DistManifest/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::Test::DistManifest/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Dist-Zilla-Plugin-Test-DistManifest>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-Plugin-Test-DistManifest.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Dist-Zilla-Plugin-Test-DistManifest/issues>.

=head1 AUTHORS

=over 4

=item *

Marcel Grünauer <marcel@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
___[ xt/release/dist-manifest.t ]___
#!perl

use Test::More;

eval "use Test::DistManifest";
plan skip_all => "Test::DistManifest required for testing the manifest"
  if $@;
manifest_ok();
