package File::Update;
$File::Update::VERSION = '0.0.2';
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT_OK = (qw(modify_on_change write_on_change write_on_change_no_utf8));

sub write_on_change
{
    my ( $io, $text_ref ) = @_;

    if ( ( !-e $io ) or ( $io->slurp_utf8() ne $$text_ref ) )
    {
        $io->spew_utf8($$text_ref);
    }

    return;
}

sub modify_on_change
{
    my ( $io, $sub_ref ) = @_;

    my $text = $io->slurp_utf8();

    if ( $sub_ref->( \$text ) )
    {
        $io->spew_utf8($text);
    }

    return;
}

sub write_on_change_no_utf8
{
    my ( $io, $text_ref ) = @_;

    if ( ( !-e $io ) or ( $io->slurp() ne $$text_ref ) )
    {
        $io->spew($$text_ref);
    }

    return;
}

1;

__END__

=pod

=head1 NAME

File::Update - update/modify/mutate a file only on change in contents.

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use Path::Tiny qw/ path /;
    use File::Update qw/ write_on_change /;

    my $text = "Updated on " . strftime("%Y-%m-%d", time) . "\n";

    write_on_change(path("dated-file.txt"), \$text);

=head1 VERSION

version 0.0.2

=head1 FUNCTIONS

=head2 write_on_change($path, \"new contents")

Accepts a L<Path::Tiny> like object and a reference to a string that contains
the new contents. Writes the new content only if it is different from the
existing one in the file.

=head2 modify_on_change($path, sub { my $t = shift; return $$t =~ s/old/new/g;})

Accepts a subroutine reference that accepts the reference to the existing
content, can mutate it and if it returns a true value, the new text is written
to the file.

=head2 write_on_change_no_utf8($path, \"new contents")

Like write_on_change() but while using L<Path::Tiny>'s non-utf8 methods.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/file-update/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc File::Update

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/File-Update>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/File-Update>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Update>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/File-Update>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/File-Update>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/File-Update>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/F/File-Update>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=File-Update>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=File::Update>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-file-update at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=File-Update>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-File-Update>

  git clone https://github.com/shlomif/perl-File-Update.git

=cut
