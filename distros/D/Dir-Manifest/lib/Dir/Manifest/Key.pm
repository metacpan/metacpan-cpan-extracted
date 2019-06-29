package Dir::Manifest::Key;
$Dir::Manifest::Key::VERSION = '0.2.0';
use strict;
use warnings;
use 5.014;

use Path::Tiny qw/ path tempdir tempfile cwd /;

use Moo;

has 'key' => ( is => 'ro', required => 1 );
has 'fh'  => ( is => 'ro', required => 1 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dir::Manifest::Key

=head1 VERSION

version 0.2.0

=head1 DESCRIPTION

Here is the primary use case: you have several long texts (and/or binary blobs) that you
wish to load from the code (e.g: for the "want"/expected values of tests) and you wish to
conventiently edit them, track them and maintain them. Using L<Dir::Manifest> you can
put each in a separate file in a directory, create a manifest file listing all valid
filenames/key and then say something like
C<<< my $text = $dir->text("deal24solution.txt", {lf => 1}) >>>. And hopefully it will
be done securely and reliably.

=head1 NAME

Dir::Manifest::Key - a Dir::Manifest key.

=head1 VERSION

version 0.2.0

=head1 METHODS

=head2 $self->key()

The key as string.

=head2 $self->fh()

A L<Path::Tiny> object for reading from the file.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Dir-Manifest>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dir-Manifest>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dir-Manifest>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Dir-Manifest>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dir-Manifest>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Dir-Manifest>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dir-Manifest>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dir-Manifest>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dir::Manifest>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dir-manifest at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Dir-Manifest>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Dir-Manifest>

  git clone https://github.com/shlomif/Dir-Manifest.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/dir-manifest/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
