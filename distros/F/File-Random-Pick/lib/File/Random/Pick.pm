package File::Random::Pick;

our $DATE = '2015-11-23'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(random_line);

sub random_line {
    my ($path, $num_lines) = @_;

    $num_lines //= 1;

    my $fh;
    if (ref($path)) {
        $fh = $path;
    } else {
        open $fh, "<", $path or die "Can't open $path: $!";
    }

    if ($num_lines < 1) {
        die "Please specify a positive number of lines to pick";
    } elsif ($num_lines == 1) {
        # use algorithm from Learning Perl
        my $line;
        while (<$fh>) {
            $line = $_ if rand($.) < 1;
        }
        return $line;
    } else {
        my @lines;
        while (<$fh>) {
            if (@lines < $num_lines) {
                # we haven't reached $num_lines, put line to result in a random
                # position
                splice @lines, rand(@lines+1), 0, $_;
            } else {
                # we have reached $nnum_items, just replace an item randomly,
                # using algorithm from Learning Perl, slightly modified
                rand($.) < @lines and splice @lines, rand(@lines), 1, $_;
            }
        }
        return @lines;
    }
}

1;
# ABSTRACT: Pick random lines from a file

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Random::Pick - Pick random lines from a file

=head1 VERSION

This document describes version 0.02 of File::Random::Pick (from Perl distribution File-Random-Pick), released on 2015-11-23.

=head1 SYNOPSIS

 use File::Random::Pick qw(random_line);
 my $line  = random_line("/usr/share/dict/words");
 my @lines = random_line("/usr/share/dict/words", 3);

 # also accepts a filehandle
 my $line = random_line($fh);

=head1 DESCRIPTION

This module can return random lines from a specified file.

Compared to the existing L<File::Random>, this module does not return
duplicates. I have also submitted a ticket to incorporate this functionality
into File::Random [1]. It also accepts a filehandle, for convenience.

=head1 FUNCTIONS

=head2 random_line($path_or_handle [ , $num_lines ]) => list

Return random lines from a specified file (or filehandle). Will not return
duplicates (meaning, will not return the same line of the file twice, but might
still return duplicates if two or more lines contain the same content). Will die
on failure to open file. C<$num_lines> defaults to 1. If there are less than
C<$num_lines> available in the file, will return just the available number of
lines.

The algorithm used is from L<perlfaq> (C<perldoc -q "random line">), which scans
the file once. The algorithm is for returning a single line and is modified to
support returning multiple lines.

=head1 SEE ALSO

L<File::Random>

L<File::RandomLine>

[1] L<https://rt.cpan.org/Ticket/Display.html?id=109384>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Random-Pick>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Random-Pick>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Random-Pick>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
