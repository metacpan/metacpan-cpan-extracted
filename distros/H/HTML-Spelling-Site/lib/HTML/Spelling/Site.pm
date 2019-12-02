package HTML::Spelling::Site;
$HTML::Spelling::Site::VERSION = '0.4.1';
use strict;
use warnings;

use 5.014;

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.4.1

=head1 SYNOPSIS

See L<HTML::Spelling::Site::Checker> .

And also see the example code on L<https://bitbucket.org/shlomif/shlomi-fish-homepage> .

=head1 DESCRIPTION

HTML::Spelling::Site was created in order to consolidate and extract the
duplicate functionality for spell checking my web-sites. Currently
documentation is somewhat lacking and the modules could use some extra
automated tests, but I'm anxious to get something out the door.

=head1 NAME

HTML::Spelling::Site - a system/framework for spell-checking an entire static
HTML site.

=head1 SEE ALSO

L<Test::HTML::Spelling> - possibly somewhat less generic than
HTML::Spelling::Site and can also only handle one file at the time. Note that
I contributed a little to it, but only after I started working on the code
that became this framework.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/HTML-Spelling-Site>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/HTML-Spelling-Site>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Spelling-Site>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/HTML-Spelling-Site>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/HTML-Spelling-Site>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/HTML-Spelling-Site>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-Spelling-Site>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-Spelling-Site>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::Spelling::Site>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-spelling-site at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Spelling-Site>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/HTML-Spelling-Site>

  git clone https://github.com/shlomif/HTML-Spelling-Site.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/html-spelling-site/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
