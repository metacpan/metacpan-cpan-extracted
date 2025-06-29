package Filename::Type::Image;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-21'; # DATE
our $DIST = 'Filename-Type-Image'; # DIST
our $VERSION = '0.006'; # VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(check_image_filename);

our $STR_RE = "djvu|jpeg|jpg2|svgz|tiff|wbmp|webp|art|bmp|cdr|cdt|cpt|cr2|crw|djv|erf|gif|ico|ief|jng|jp2|jpe|jpf|jpg|jpm|jpx|nef|orf|pat|pbm|pcx|pgm|png|pnm|ppm|psd|ras|rgb|svg|tif|xbm|xcf|xpm|xwd"; # STR_RE

our $RE = qr(\.(?:$STR_RE)\z)i;

our %SPEC;

$SPEC{check_image_filename} = {
    v => 1.1,
    summary => 'Check whether filename indicates being an image',
    description => <<'MARKDOWN',


MARKDOWN
    args => {
        filename => {
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
        # XXX recurse?
        #ci => {
        #    summary => 'Whether to match case-insensitively',
        #    schema  => 'bool',
        #    default => 1,
        #},
    },
    result_naked => 1,
    result => {
        schema => ['any*', of=>['bool*', 'hash*']],
        description => <<'MARKDOWN',

Return false if no archive suffixes detected. Otherwise return a hash of
information.

MARKDOWN
    },
    examples => [
        {
            args => {filename => 'foo.txt'},
            naked_result => 0,
        },
        {
            args => {filename => 'foo.mp4'},
            naked_result => 0,
        },
        {
            args => {filename => 'foo.jpg'},
            naked_result => {},
        },
        {
            args => {filename => 'foo.PNG'},
            naked_result => {},
        },
    ],
};
sub check_image_filename {
    my %args = @_;

    $args{filename} =~ $RE ? {} : 0;
}

1;
# ABSTRACT: Check whether filename indicates being an image

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Type::Image - Check whether filename indicates being an image

=head1 VERSION

This document describes version 0.006 of Filename::Type::Image (from Perl distribution Filename-Type-Image), released on 2024-12-21.

=head1 SYNOPSIS

 use Filename::Type::Image qw(check_image_filename);
 my $res = check_image_filename(filename => "foo.jpg");
 if ($res) {
     printf "File is image";
 } else {
     print "File is not image\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 check_image_filename

Usage:

 check_image_filename(%args) -> bool|hash

Check whether filename indicates being an image.

Examples:

=over

=item * Example #1:

 check_image_filename(filename => "foo.txt"); # -> 0

=item * Example #2:

 check_image_filename(filename => "foo.mp4"); # -> 0

=item * Example #3:

 check_image_filename(filename => "foo.jpg"); # -> {}

=item * Example #4:

 check_image_filename(filename => "foo.PNG"); # -> {}

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

(No description)


=back

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Type-Image>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Type-Image>.

=head1 SEE ALSO

L<Filename::Type::Audio>

L<Filename::Type::Video>

L<Filename::Type::Ebook>

L<Filename::Type::Media>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Type-Image>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
