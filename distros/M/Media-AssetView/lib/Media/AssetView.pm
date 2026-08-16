package Media::AssetView;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-04-27'; # DATE
our $DIST = 'Media-AssetView'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
                       create_views_symlinks
               );

our %SPEC;

$SPEC{create_views_symlinks} = {
    v => 1.1,
    summary => 'Create views symlinks in the Asset-Views directory',
    args => {
    },
};
sub create_views_symlinks {
    [501, "Not yet implemented"];
}

1;
# ABSTRACT: Handle the Asset-Views directory organization

__END__

=pod

=encoding UTF-8

=head1 NAME

Media::AssetView - Handle the Asset-Views directory organization

=head1 VERSION

This document describes version 0.001 of Media::AssetView (from Perl distribution Media-AssetView), released on 2026-04-27.

=head1 SYNOPSIS

 use Media::AssetView qw(
     create_views_symlinks
 );
 my $res = create_asset_views_symlinks(root_dir => '/path/to/my/dir');

=head1 DESCRIPTION

The Assets-Views organization scheme lets you put actual media files (with a
specific naming convention) and can automatically create various views using
symlinks.

Media files are put in F<assets/>:

 ROOT_DIR
   assets/
     audio/
     photo/
     video/
       2026/
         202604/
           20260427a-type=ad-char=char1,char2-prod=PROD1/
           20260427a-type=footage-ai=1-char=char2-prod=PROD1/
       ...
   views/
     by-character/
       char1/
         20260427a-type=ad-char=char1,char2-prod=PROD1/
       char2/
         20260427a-type=ad-char=char1,char2-prod=PROD1/
         20260427a-type=footage-ai=1-char=char2-prod=PROD1/
     by-product/
       PROD1/
         20260427a-type=footage-ai=1-char=char2-prod=PROD1/
     by-type/
       ad/
         20260427a-type=ad-char=char1,char2-prod=PROD1/
       footage/
         20260427a-type=footage-ai=1-char=char2-prod=PROD1/
     by-ai/
       no-ai/
         20260427a-type=ad-char=char1,char2-prod=PROD1/
       ai/
         20260427a-type=footage-ai=1-char=char2-prod=PROD1/

=head1 FUNCTIONS


=head2 create_views_symlinks

Usage:

 create_views_symlinks() -> [$status_code, $reason, $payload, \%result_meta]

Create views symlinks in the Asset-Views directory.

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Media-AssetView>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Media-AssetView>.

=head1 SEE ALSO

L<Filename::KeyValue>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords perlancar

perlancar <perlancar@gmail.com>

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Media-AssetView>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
