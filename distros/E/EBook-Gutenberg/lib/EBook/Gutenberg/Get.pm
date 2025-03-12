package EBook::Gutenberg::Get;
use 5.016;
our $VERSION = '0.01';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(gutenberg_link gutenberg_get);

use File::Copy;
use File::Fetch;
use File::Spec;
use File::Temp qw(tempdir);

our %FORMATS = (
    'html' => {
        link => sub {
            "https://www.gutenberg.org/ebooks/$_[0].html.images"
        },
        suffix => 'html',
    },
    'epub3' => {
        link => sub {
            "https://www.gutenberg.org/ebooks/$_[0].epub3.images"
        },
        suffix => 'epub',
    },
    'epub' => {
        link => sub {
            "https://www.gutenberg.org/ebooks/$_[0].epub.images"
        },
        suffix => 'epub',
    },
    'epub-noimages' => {
        link => sub {
            "https://www.gutenberg.org/ebooks/$_[0].epub.noimages"
        },
        suffix => 'epub',
    },
    'kindle' => {
        link => sub {
            "https://www.gutenberg.org/ebooks/$_[0].kf8.images"
        },
        suffix => 'azw3',
    },
    'mobi' => {
        link => sub {
            "https://www.gutenberg.org/ebooks/$_[0].kindle.images"
        },
        suffix => 'mobi',
    },
    'text' => {
        link => sub {
            "https://www.gutenberg.org/ebooks/$_[0].txt.utf-8"
        },
        suffix => 'txt',
    },
    'zip' => {
        link => sub {
            "https://www.gutenberg.org/cache/epub/$_[0]/pg$_[0]-h.zip"
        },
        suffix => 'zip',
    },
);

sub gutenberg_link {

    my $id  = shift;
    my $fmt = shift;

    return $FORMATS{ $fmt }->{ link }($id);

}

sub gutenberg_get {

    my $id = shift;
    my $param = shift;

    unless ($id =~ /^\d+$/) {
        die "id must be an integar\n";
    }

    my $fmt = $param->{ fmt } // 'epub3';
    my $to = $param->{ to } // "$id.*";

    $to =~ s/\.\*$/\.$FORMATS{ $fmt }->{ suffix }/;

    if (-d $to) {
        die "Cannot download file to $to: is a directory\n";
    }

    my $link = gutenberg_link($id, $fmt);

    my $tmp = tempdir(CLEANUP => 1);

    my $ff = File::Fetch->new(uri => $link);

    my $fetch = $ff->fetch(to => $tmp)
        or die $ff->error;

    move($fetch, $to)
        or die "Failed to move $fetch to $to: $!\n";

    rmdir $tmp;

    return $to;

}

1;

=head1 NAME

EBook::Gutenberg::Get - Fetch ebooks from Project Gutenberg

=head1 SYNOPSIS

  use EBook::Gutenberg::Get;

  my $ebook = gutenberg_get($id);

=head1 DESCRIPTION

B<EBook::Gutenberg::Get> is a module that provides some subroutines related to
downloading ebooks from Project Gutenberg. This is developer documentation,
for L<gutenberg> user documentation you should consult its manual.

Note that this module is not designed to perform bulk downloading/scraping.
Attempting to use this module to do so may result in Project Gutenberg banning
you from their site. You have been warned.

=head1 SUBROUTINES

The following subroutines are exported by C<EBook::Gutenberg::Get>
automatically.

=over 4

=item $get = gutenberg_get($id, [\%param])

Fetches an ebook from Project Gutenberg. C<$id> is the ID of the ebook to
fetch. C<\%params> is a hash ref of extra parameters to configure the download
process.

The following are valid parameters:

=over 4

=item to

Path to write downloaded file to. Defaults to C<'$id.*'>. If the provided path
has a C<'.*'> suffix, the C<'.*'> will be substituted by the ebook format's
file suffix.

=item fmt

Format of ebook to download. The following are valid options:

=over 4

=item html

=item epub3

=item epub

=item epub-noimages

=item kindle

=item mobi

=item text

=item zip

=back

Defaults to C<'epub3'>.

=back

=item $link = gutenberg_link($id, $fmt)

Returns the download link of an ebook. C<$id> is the ID of the ebook. C<$fmt>
is the ebook format.

=back

=head1 GLOBAL VARIABLES

=over 4

=item %EBook::Gutenberg::FORMATS

Hash of valid ebook formats and a hash ref of some format data. See the
documentation for C<fmt> in C<gutenberg_get> for a list of ebook formats.

The format hash ref has this format:

=over 4

=item link

Subroutine reference that, when given an ebook ID, returns a download link to
that ebook.

=item suffix

The default file suffix to use with the format.

=back

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/gutenberg>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<gutenberg>, L<File::Fetch>

=cut

# vim: expandtab shiftwidth=4
