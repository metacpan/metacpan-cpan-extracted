package File::CountLines;
use strict;
use warnings;

our $VERSION = '0.0.3';
our @EXPORT_OK = qw(count_lines);

use Exporter 5.057;
Exporter->import('import');

use Carp qw(croak);
use charnames qw(:full);

our %StyleMap = (
    'cr'        => "\N{CARRIAGE RETURN}",
    'lf'        => "\N{LINE FEED}",
    'crlf'      => "\N{CARRIAGE RETURN}\N{LINE FEED}",
    'native'    => "\n",
);

our $BlockSize = 4096;

sub count_lines {
    my $filename = shift;
    croak 'expected filename in call to count_lines()'
        unless defined $filename;
    my %options = @_;
    my $sep = $options{separator};
    unless (defined $sep) {
        my $style = exists $options{style} ? $options{style} : 'native';
        $sep = $StyleMap{$style};
        die "Don't know how to map style '$style'" unless defined $sep;
    }
    if (length($sep) > 1) {
        return _cl_sysread_multiple_chars(
                $filename,
                $sep,
                $options{blocksize} || $BlockSize,
            );
    } else {
        return _cl_sysread_one_char(
                $filename,
                $sep,
                $options{blocksize} || $BlockSize,
            );
    }
}

sub _cl_sysread_one_char {
    my ($filename, $sep, $blocksize) = @_;
    local $Carp::CarpLevel = 1;
    open my $handle, '<:raw', $filename
        or croak "Can't open file `$filename' for reading: $!";
    binmode $handle;
    my $lines = 0;
    $sep =~ s/([\\{}])/\\$1/g;
    # need eval here because tr/// doesn't interpolate
    my $sysread_status;
    eval qq[
        while (\$sysread_status = sysread \$handle, my \$buffer, $blocksize) {
            \$lines += (\$buffer =~ tr{$sep}{});
        }
    ];
    die "Can't sysread() from file `$filename': $!"
        unless defined ($sysread_status);
    close $handle or croak "Can't close file `$filename': $!";
    return $lines;
}

sub _cl_sysread_multiple_chars {
    my ($filename, $sep, $blocksize) = @_;
    local $Carp::CarpLevel = 1;
    open my $handle, '<:raw', $filename
        or croak "Can't open file `$filename' for reading: $!";
    binmode $handle;
    my $len = length($sep);
    my $lines = 0;
    my $buffer = '';
    my $sysread_status;
    while ($sysread_status = sysread $handle, $buffer, $blocksize, length($buffer)) {
        my $offset = -$len;
        while (-1 != ($offset = index $buffer, $sep, $offset + $len)) {
            $lines++;
        }
        # we assume $len >= 2; otherwise use _cl_sysread_one_char()
        $buffer = substr $buffer, 1 - $len;
    }
    die "Can't sysread() from file `$filename': $!"
        unless defined ($sysread_status);
    close $handle or croak "Can't close file `$filename': $!";
    return $lines;
}

1;

__END__

=head1 NAME

File::CountLines - efficiently count the number of line breaks in a file.

=head1 SYNOPSIS

    use File::CountLines qw(count_lines);
    my $no_of_lines = count_lines('/etc/passwd');

    # other uses
    my $carriage_returns = count_lines( 
            'path/to/file.txt', 
            style   => 'cr',
        );
    # possible styles are 'native' (the default), 'cr', 'lf'

=head1 DESCRIPTION

L<perlfaq5> answers the question on how to count the number of lines
in a file. This module is a convenient wrapper around that method, with
additional options.

More specifically, it counts the number of I<line breaks> rather than lines.
On Unix systems nearlly all text files end with a newline (by convention), so
usually the number of lines and number of line breaks is equal.

Since different operating systems have different ideas of what a newline is,
you can specifiy a C<style> option, which can be one of the following values:

=over

=item C<native>

This takes Perl's C<\n> as the line separator, which should be the right thing in most cases. See L<perlport> for details. This is the default. 

=item C<cr>

Take a carriage return as line separator (MacOS style)

=item C<lf>

Take a line feed as line separator (Unix style)

=item C<crlf>

Take a carriage return followed by a line feed as separator (Microsoft
Windows style)

=back

Alternatively you can specify an arbitrary separator like this:

    my $lists = count_lines($file, separator => '\end{itemize}');

It is taken verbatim and searched for in the file.

The file is read in equally sized blocks. The size of the blocks
can be supplied with the C<blocksize> option. The default is 4096,
and can be changed by setting C<$File::CountLines::BlockSize>.

Do not use a block size smaller than the length of the separator, that
might produce wrong results. (In general there's no reason to chose a
smaller block size at all. Depending on your size a larger block size
might speed up things a bit.)

=head1 Character Encodings

If you supply a separator yourself, it should not be a decoded string.

The file is read in binary mode, which implies that this module
works fine for text files in ASCII-compatible encodings, including
ASCII itself, UTF-8 and all the ISO-8859-* encodings (aka Latin-1,
Latin-2, ...).

Note that the multi byte encodings like UTF-32, UTF-16le, UTF-16be
and UCS-2 encode a line feed character in a way that the C<0x0A> byte
is a substring of the encoded character, but if you search blindly for
that byte you will get false positives. For example the I<LATIN CAPITAL
LETTER C WITH DOT ABOVE>, U+010A has the byte sequence C<0x0A 0x01> when
encoded as UTF-16le, so it would be counted as a newline. Even search for
C<0x0A 0x00> might give false positives.

So the summary is that for now you can't use this module in a meaningful
way to count lines of text files in encodings that are not ASCII-compatible.
If there's demand for, I can implement that though.

=head1 Extending

You can add your own EOL styles by adding them to the
C<%File::CountLines::StyleMap> hash, with the name of the style as hash key
and the separator as the value.

=head1 AUTHOR

Moritz Lenz L<http://perlgeek.de>, L<mailto:moritz@faui2k3.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Moritz A. Lenz. This module is free software.
You may use, redistribute and modify it under the same terms as perl itself.

Example code included in this package may be used as if it were in the Public
Domain.

=head1 DEVELOPMENT

You can obtain the latest development version from L<http://github.com/moritz/File-CountLines>:

    git clone git://github.com/moritz/File-CountLines.git

=cut

