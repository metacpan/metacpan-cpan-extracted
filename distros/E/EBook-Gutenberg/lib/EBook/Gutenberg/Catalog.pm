package EBook::Gutenberg::Catalog;
use 5.016;
our $VERSION = '1.00';
use strict;
use warnings;

use File::Copy;
use File::Fetch;
use File::Spec;
use File::Temp qw(tempdir);
use List::Util qw(all);

use Text::CSV_XS qw(csv);

my $CATALOG_URI = "https://www.gutenberg.org/cache/epub/feeds/pg_catalog.csv";
my $CATALOG_HEAD = 'Text#,Type,Issued,Title,Language,Authors,Subjects,LoCC,Bookshelves';

sub _catalog_ok {

    my $file = shift;

    open my $fh, '<', $file
        or die "Failed to open $file for reading: $!\n";
    my $head = readline $fh;
    close $fh;

    return $head =~ /^\Q$CATALOG_HEAD\E/;

}

sub _bookify {

    my $book = shift;

    my @b = map { s/\s+/ /gr } @$book;

    return {
        'Text#'       => $b[0],
        'Type'        => $b[1],
        'Issued'      => $b[2],
        'Title'       => $b[3],
        'Language'    => $b[4],
        'Authors'     => $b[5],
        'Subjects'    => $b[6],
        'LoCC'        => $b[7],
        'Bookshelves' => $b[8],
    };

}

sub new {

    my $class = shift;
    my $file  = shift;

    my $self;

    $$self = File::Spec->rel2abs($file);

    bless $self, $class;

    if (-d $$self) {
        die "$$self is a directory\n";
    }

    if (-f $$self and !_catalog_ok($$self)) {
        die "$$self is not a valid Project Gutenberg catalog file\n";
    }

    return $self;

}

sub path {

    my $self = shift;

    return $$self;

}

sub set_path {

    my $self = shift;
    my $file = shift;

    $$self = File::Spec->rel2abs($file);

    if (-d $$self) {
        die "$$self is a directory\n";
    }

    if (-f $$self and !_catalog_ok($$self)) {
        die "$$self is not a valid Project Gutenberg catalog file\n";
    }

    return $$self;

}

sub fetch {

    my $self = shift;

    my $tmp = tempdir(CLEANUP => 1);

    my $ff = File::Fetch->new(uri => $CATALOG_URI);

    my $fetch = $ff->fetch(to => $tmp)
        or die $ff->error;

    unless (_catalog_ok($fetch)) {
        die "Downloaded catalog was not a valid Project Gutenberg catalog file\n";
    }

    move($fetch, $$self)
        or die "Failed to move $fetch to $$self: $!\n";

    rmdir $tmp;

    return $$self;

}

sub book {

    my $self = shift;
    my $id   = shift;

    unless (-f $$self) {
        die "$$self is not a regular file\n";
    }

    my $csv = Text::CSV_XS->new({ binary => 1, auto_diag => 1 });

    open my $fh, '<', $$self
        or die "Failed to open $$self for reading: $!\n";

    my $book;

    while (my $row = $csv->getline($fh)) {
        if ($row->[0] eq $id) {
            $book = $row;
            last;
        }
    }

    close $fh;

    return defined $book ? _bookify($book) : undef;

}

sub books {

    my $self  = shift;
    my $param = shift;

    unless (-f $$self) {
        die "$$self is not a regular file\n";
    }

    my $filter = {};

    for my $p (split /,/, $CATALOG_HEAD) {
        next unless ref $param->{ $p } eq 'CODE';
        $filter->{ $p } = $param->{ $p };
    }

    my $books = csv(
        in => $$self,
        filter => $filter,
        # Convert all whitespace to single space
        after_parse => sub {
            for my $k (keys %{ $_[1] }) {
                $_[1]->{ $k } =~ s/\s+/ /g;
            }
        }
    );

    return $books;

}

1;

=head1 NAME

EBook::Gutenberg::Catalog - Project Gutenberg catalog interface

=head1 SYNOPSIS

  use EBook::Gutenberg::Catalog;

  my $catalog = EBook::Gutenberg::Catalog->new($path);

=head1 DESCRIPTION

B<EBook::Gutenberg::Catalog> is a module that provides an interface for reading
Project Gutenberg CSV catalog files. This is developer documentation, for
L<gutenberg> user documentation you should consult its manual.

=head1 METHODS

=over 4

=item $cat = EBook::Gutenberg::Catalog->new($path)

Returns a blessed B<EBook::Gutenberg::Catalog> object representing a Project
Gutenberg catalog file stored in C<$path>. C<$path> doesn't actually have to
exist, it can be fetched later via the C<fetch()> method.

=item $path = $cat->path()

Returns path to C<$cat>'s catalog file.

=item $path = $cat->set_path($new)

Set C<$cat>'s catalog file to C<$new>. Returns newly set path.

=item $fetch = $cat->fetch()

Fetches Project Gutenberg catalog file and writes it to the path specified in
C<new()>. Returns the path to the fetched file.

=item $book = $cat->book($id)

Get hash ref representing the book with an ID C<$id> from the catalog file. The
hash ref has the following format:

  {
    'Text#'       => '...',
    'Type'        => '...',
    'Issued'      => '...',
    'Title'       => '...',
    'Language'    => '...',
    'Authors'     => '...',
    'Subjects'    => '...',
    'LoCC'        => '...',
    'Bookshelves' => '...',
  }

=item $books = $cat->books([\%params])

Returns array ref of hash refs representing books from catalog that conform to
the parameters supplied by C<\%params>. The hash refs follow the same format
used by the ones returned by C<book()>.

C<\%params> is a hash ref of ebook fields and subroutine references that are
used to C<grep> for specific ebooks. The subroutine will have C<$_> set to the
value of the field. If the subroutine does not return true when given a value,
the ebook will be filtered out. The following are valid fields to use for
C<\%params>.

=over 4

=item Text#

=item Type

=item Issued

=item Title

=item Language

=item Authors

=item Subjects

=item LoCC

=item Bookshelves

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

L<gutenberg>

=cut

# vim: expandtab shiftwidth=4
