package App::File::IsSorted::Command::check;
$App::File::IsSorted::Command::check::VERSION = '0.2.0';
use App::File::IsSorted -command;

use strict;
use warnings;
use autodie;
use 5.016;

use File::IsSorted ();

sub abstract { "check for files having sorted lines" }

sub description { return abstract(); }

sub opt_spec
{
    return ();
}

sub validate_args
{
    my ( $self, $opt, $args ) = @_;

    # no args allowed but options!
    $self->usage_error("args required") if not @$args;
}

sub execute
{
    my ( $self, $opt, $args ) = @_;

    my $checker = File::IsSorted->new;

    foreach my $path (@$args)
    {
        $checker->is_file_sorted( { path => $path } );
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.2.0

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/File-IsSorted>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-IsSorted>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/File-IsSorted>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/F/File-IsSorted>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=File-IsSorted>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=File::IsSorted>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-file-issorted at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=File-IsSorted>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-File-IsSorted>

  git clone https://github.com/shlomif/perl-File-IsSorted.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/file-issorted/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
