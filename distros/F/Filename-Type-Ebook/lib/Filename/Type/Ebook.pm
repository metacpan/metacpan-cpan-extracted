package Filename::Type::Ebook;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-20'; # DATE
our $DIST = 'Filename-Type-Ebook'; # DIST
our $VERSION = '0.002'; # VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(check_ebook_filename);

our %SPEC;

our %SUFFIXES = (
    '.azw'     => {format=>'kindle'},
    '.azw3'    => {format=>'kindle'},
    '.kf8'     => {format=>'kindle'},
    '.kfx'     => {format=>'kindle'},

    '.cbr'     => {format=>'cbr'},
    '.cbz'     => {format=>'cbr'},
    '.cb7'     => {format=>'cbr'},
    '.cbt'     => {format=>'cbr'},
    '.cba'     => {format=>'cbr'},

    '.chm'     => {format=>'chm'},

    '.djvu'    => {format=>'djvu'},

    '.doc'     => {format=>'doc'},
    '.docx'    => {format=>'docx'},

    '.epub'    => {format=>'epub'},

    '.htm'     => {format=>'html'},
    '.html'    => {format=>'html'},

    '.mobi'    => {format=>'mobi'},
    '.prc'    => {format=>'mobi'},

    '.pdf'     => {format=>'pdf'},

    '.ps'      => {format=>'postscript'},

    '.rtf'     => {format=>'rtf'},

    '.text'    => {format=>'txt'},
    '.txt'     => {format=>'txt'},

    # old/unpopular
    # .pdb (palm)
    # .fb2 (fictionbook)
    # .xeb, .ceb (apabi)
    # .ibooks (apple ibook)
    # .inf (ibm)
    # .lit (microsoft lit)
    # .pkg (newton)
    # .opf (open ebook, superseded by epub)
    # .pdg (ssreader)
    # .tr2, .tr3 (tomeraider)
    # .oxps, .xps (open xml paper)

    # ambiguous
    # .xml
);

our %FORMATS = (
);

our $STR_RE = join "|", map {quotemeta} sort keys %SUFFIXES;

our $RE = qr((?:$STR_RE)\z)i;

$SPEC{check_ebook_filename} = {
    v => 1.1,
    summary => 'Check whether filename indicates being an e-book',
    description => <<'MARKDOWN',


MARKDOWN
    args => {
        filename => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        ci => {
            summary => 'Whether to match case-insensitively',
            schema  => 'bool',
            default => 1,
        },
    },
    result_naked => 1,
};
sub check_ebook_filename {
    my %args = @_;

    $args{filename} =~ $RE ? {} : 0;
}

1;
# ABSTRACT: Check whether filename indicates being an e-book

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Type::Ebook - Check whether filename indicates being an e-book

=head1 VERSION

This document describes version 0.002 of Filename::Type::Ebook (from Perl distribution Filename-Type-Ebook), released on 2024-12-20.

=head1 SYNOPSIS

 use Filename::Type::Ebook qw(check_ebook_filename);
 my $res = check_ebook_filename(filename => "how not to die.pdf");
 if ($res) {
     print "Filename indicates an ebook\n",
 } else {
     print "Filename does not indicate an ebook\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 check_ebook_filename

Usage:

 check_ebook_filename(%args) -> any

Check whether filename indicates being an e-book.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<filename>* => I<str>

(No description)


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Type-Ebook>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Type-Ebook>.

=head1 SEE ALSO

Other C<Filename::Type::*>, e.g. L<Filename::Type::Image> or
L<Filename::Type::Video>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Type-Ebook>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
