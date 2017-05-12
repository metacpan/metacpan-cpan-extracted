package Dist::Zilla::Plugin::Test::Legal;

# ABSTRACT: common tests to check for copyright and license notices

use 5.006;
use strict;
use warnings;

use namespace::autoclean;

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';

our $VERSION = '0.02';  # VERSION

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=for :stopwords Alan Young cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan

=head1 NAME

Dist::Zilla::Plugin::Test::Legal - common tests to check for copyright and license notices

=head1 VERSION

  This document describes v0.02 of Dist::Zilla::Plugin::Test::Legal
  Released November 21, 2014 as part of Dist-Zilla-Plugin-Test-Legal.

=head1 SYNOPSIS

in C<dist.ini>

  [Test::Legal]

=head1 DESCRIPTION

This module will add a L<Test::Legal> test as a release test to your module

=head1 REQUIRES

=over 4

=item * L<Moose>

=item * L<namespace::autoclean>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::Test::Legal

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Zilla-Plugin-Test-Legal>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-Test-Legal>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-Legal>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Dist-Zilla-Plugin-Test-Legal>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Test-Legal>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Dist-Zilla-Plugin-Test-Legal>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-Test-Legal>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-Test-Legal>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-Test-Legal>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::Test::Legal>

=back

=head2 Email

You can email the author of this module at C<AYOUNG at cpan.org> asking for help with any problems you have.

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web interface at L<https://github.com/harleypig/Dist-Zilla-Plugin-Test-Legal/issues>. You will be automatically notified of any progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/harleypig/Dist-Zilla-Plugin-Test-Legal>

  git clone git://github.com/harleypig/Dist-Zilla-Plugin-Test-Legal.git

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 CHANGES

=head2 Version 0.01 (2012-01-03T20:17:03Z)

=over 4

=item *

Initial Creation

=back

=head1 AUTHOR

Alan Young <ayoung@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alan Young.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

__DATA__
__[ xt/release/test-legal.t ]__
use strict;
use warnings;

use Test::More;

eval 'use Test::Legal';
plan skip_all => 'Test::Legal required for testing licenses'
  if $@

copyright_ok;
license_ok;
