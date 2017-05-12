#!/usr/bin/perl

use strict;
use warnings;

package File::Bidirectional;
use Carp;
use Fcntl qw/:seek O_RDONLY/;

our $VERSION = '0.01';

=pod

=head1 NAME

File::Bidirectional - Read a file line-by-line either forwards or backwards

=head1 SYNOPSIS

    use File::Bidirectional;
    my $file = "/var/log/large_file";

    # Object interface

    # start from the last line
    my $fh = File::Bidirectional->new($file, {origin => -1})
        or die $!;

    # read backwards until point of interest
    while (my $line = $fh->readline()) {
        last if $line =~ /RECORD_START/;
    }

    # switch directions
    $fh->switch();

    # read forwards until point of interest
    while (my $line = $fh->readline()) {
        last if $line =~ /RECORD_END/;
    }

    # Tied Handle Interface

    local *F;
    tie *F, "File::Bidirectional", $file, {origin => 1}
        or die $!;

    while (my $line = <F>) { ... }

    (tied *F)->switch();

=head1 DESCRIPTION

File::Bidirectional reads a file line-by-line in either the forwards or
backwards direction. It supports an object interface as well as a tied
filehandle interface, and should be straight-forward to use. It is also memory
efficient, since it is intended to be used on files too large to be efficiently
slurped into an array and traversed backwards.

The direction in which to traverse the file can be changed at anytime, but it is
important to note that the last-read line will be repeated when this happens.
See C<line_num> to see why this is so.

On non-Unix platforms, this module attempts to immitate native Perl in
converting the line endings. Currently, this is limited and untested, so please
see L</LINE ENDINGS> for more information.

=head1 MOTIVATION

I had a C<diff> file describing the changes in a large (> 200MB) file. Based on
the line numbers in the C<diff>, I have to repeatedly read backwards and
forwards in the large file to obtain the context lines before and after the
C<diff> changes. The number of context lines vary, thus it was a little more
involved than regenerating the C<diff> with an appropriate C<--context> option.

I decided to publish this module as I thought others might have similar needs.
Reading large log files backwards is probably the most common of these, but if
you have any other interesting uses, do let me know.

=cut

# globals
my ($BLOCK_SIZE);
BEGIN {
    # defaults - can be changed through constructor
    $BLOCK_SIZE     = 1024 * 8;

    # _read_line() and _eof() are used as sensible defaults. we will fix up the
    # aliases again later to optimize away one indirection function call

    # tied interface
    *TIEHANDLE  = \&new;
    *READLINE   = \&_read_line;
    *EOF        = \&_eof;
    *CLOSE      = \&close; 
    *TELL       = \&tell;

    # IO::Handle compatability
    *getline    = \&_read_line;

    # File::ReadBackwards compatability
    *get_handle = \&fh;

    # aliases
    *readline   = \&_read_line;
    *eof        = \&_eof;
}

=pod

=head1 CONSTRUCTOR (CLASS METHODS)

=over

=item new $file, \%option

    $fh = File::Bidirectional->new($file);
    $fh = File::Bidirectional->new($file, {mode => 'forward'});
    $fh = File::Bidirectional->new($file, {mode => 'backward'});
    $fh = File::Bidirectional->new($file, {origin => -1});
    $fh = File::Bidirectional->new($file, \%option);

Has the file name as the first parameter, and a hashref of options as an
optional second parameter. Upon success, it will return the object. For invalid
parameters, it will C<Carp/croak>. For L<perlfunc/sysopen> errors, it returns
undef and sets the error code in L<perlvar/$!>.

The list of valid options are:

=over

=item mode

Can be either C<bi> (bi-directional), C<forward> or C<backward>. The C<forward>
and C<backward> modes are restrictive: the file is read from the first and last
line respectively, and switching directions is prohibited. The C<bi> mode
allows direction switching, and will start from the first line by default (use
the C<origin> option to change that.) The default is C<bi>.

=item origin

Can be either C<1> or C<-1>. These denote whether the first or last line of the
file is considered as line 1 by C<line_num>. (C<readline> will always start
from line 1.) C<origin> can only be set if the C<mode> option is C<bi>. The
default is C<1>.

=item binmode

Can be any true or false expression. It is analogous to the L<perlfunc/binmode>
built-in function. On systems that distinguish between binary and text files,
notably DOS and Windows-based systems, this is important. A true value will
preserve C<\r\n> as is; a false value will convert C<\r\n> to C<\n>. The
default is false.

=item separator

Can be any scalar string. It is analogous to the L<perlvar/"$/"> variable.
C<separator> determines C<File::Bidirectional>'s notion of what a line is. The
default is L<perlvar/"$/">, which in turn defaults to C<"\n">.

Caveat: The Perl-ish magic that occurs when L<perlvar/"$/"> is C<""> does not
happen yet.

=item regex

Can be any true or false expression. It determines whether the C<separator>
option is a regex or a string. The default is false.

=item block_size

Can be any positive integer. This is the size of a single block read by the
underlying L<perlfunc/sysread>. The default is 8192.

=back

=back

=head1 INSTANCE METHODS

=cut


sub new {
    my ($class, $file, $option) = @_;
    croak "expected class method"
        unless defined $class;
    croak "expected filename"
        unless defined $file;
    croak "expected hashref for parameters"
        unless !defined $option || ref($option) eq 'HASH';

    # block size and buffer size
    my $block_size = $option->{block_size} || $BLOCK_SIZE;
    croak "expected block_size to be positive integer"
        unless $block_size =~ /^\d+$/ && $block_size > 0;

    # default separator is $/
    my $sep = $option->{separator};
    $sep = $/
        unless defined $sep;

    # default is not to treat separator as regex
    my $sep_re = $option->{regex};
    $sep_re = 0
        unless defined $sep_re;

    # pre-compile regular expression
    my $re = ($sep_re) ? qr/(.*?$sep|.+)/ : qr/(.*?\Q$sep\E|.+)/;

    # translation takes place on DOS (without binmode), Mac etc.
    my $binmode = $option->{binmode};
    my $translate = 
        (_is_dos() && !$binmode)    ? qr/\015\012/  :
        (_is_mac())                 ? qr/\015/      :
        undef;

    # default mode is bidirectional
    my $mode = $option->{mode};
    croak "expected mode to be [bi|forward|backward]"
        unless !defined $mode || $mode =~ /^(bi|forward|backward)$/;
    $mode = 'bi' unless defined $mode;

    # origin can only be explicitly set for bidirectional
    my $origin = $option->{origin};
    croak "expected origin only for mode \"bi\""
        unless !defined $origin || $mode eq 'bi';
    croak "expected origin to be [1|-1]"
        unless !defined $origin || $origin =~ /^(1|-1)$/;
    if (!defined $origin) {
        $origin = 
            ($mode eq 'bi')         ? 1  :
            ($mode eq 'forward')    ? 1  :
            ($mode eq 'backward')   ? -1 : undef;
    }

    # file size
    my $file_size = -s $file;

    # set starting point of cursor to coincide with the origin
    my $start = ($origin == 1) ? 0 : $file_size;

    sysopen my $fh, $file, O_RDONLY
        or return undef;
    binmode $fh;

    my $x = {
        mode    => $mode,   # mode
        fh      => $fh,     # filehandle
        cur     => $start,  # physical cursor on filehandle
        buffer  => [],      # buffer
        origin  => $origin, # 1: first line as line 1   / -1: last line as line 1
        move    => $origin, # 1: moving forwards        / -1: moving backwards
        line    => 0,       # forward: line read        / backward: line to be read
        re      => $re,     # regular expression for separator
        translate   => $translate,
        file_size   => $file_size,
        block_size  => $block_size,
    };

    bless ($x, $class);

    # fixup the aliases to save a method call for readline
    $x->_fixup_alias();

    return $x;
}

=pod

=over

=item readline

    while (my $line = $fh->readline()) { ... }

Returns the subsequent line. This refers either to the next line when the
direction is forwards, or to the previous line when the direction is backwards.
The direction can be changed with C<switch>. C<undef> is returned when there
are no more lines to be read.

=item getline

An alias for C<readline>. It exists for compatability with the IO::* classes.

=item eof

Returns true when C<readline> will return an C<undef>, false otherwise.

=item switch

    $fh->switch();

Switches the current direction in which we are reading the file. It will
L<Carp/croak> if the C<mode> option in the constructor is set to C<forward> or
C<backward>.

Note that switching directions will cause the last-read line to be repeated by
C<readline>.

=cut

# reverse movement direction
sub switch {
    my ($x) = @_;

    croak "needs to be bidirectional mode to switch directions"
        unless $x->{mode} eq 'bi';

    # get current tell() before changing direction and invalidating the buffer
    $x->{cur}   = $x->tell();

    # invalidate the buffer
    undef @{$x->{buffer}};

    # change direction
    $x->{move} *= -1;

    # fixup aliases for readline() and eof() after changing direction
    $x->_fixup_alias();
}

=pod

=item close

    $fh->close();

Closes the underlying filehandle and releases the memory allocated for its
buffer. On success it returns true, otherwise it returns false with the error
code found in L<perlvar/$!>. All subsequent C<readline> calls will return
undef, and C<line_num>, its last value.

=cut

# close file and destroy state
sub close {
    my ($x) = @_;
    undef @{$x->{buffer}};
    $x->{cur} = ($x->{move} == 1) ? $x->{file_size} : 0;
    CORE::close($x->{fh})
        or return undef;
    return 1;
}

=pod

=item direction $direction

Takes an optional parameter: 1 for reading forwards, -1 for reading backwards,
L<Carp/croak> otherwise. If an argument for the parameter is provided, the
direction will be switched if necessary. Either way, it returns the (new)
direction.

=cut

sub direction {
    my ($x, $direction) = @_;
    croak "expected direction to be [1|-1]"
        unless !defined $direction || $direction =~ /^(1|-1)$/;

    if (defined $direction && $direction != $x->{move}) {
        $x->switch();
    }

    return $x->{move};
}

=pod

=item line_num

    my $fh=File::Bidirectional->new($file); n=$fh->line_num(); # n = 0
    $fh->readline();                        n=$fh->line_num(); # n = 1
    $fh->readline();                        n=$fh->line_num(); # n = 2
    $fh->switch();                          n=$fh->line_num(); # n = 2
    $fh->readline();                        n=$fh->line_num(); # n = 1
    $fh->readline();                        n=$fh->line_num(); # n = 0

Returns the current line number. It is analogous to L<perlvar/$.>.

For a file with I<n> logical lines, the line number ranges from 0 to I<n>. When
reading away from the origin (forwards if the first line is the origin), its
behavior is always identical to that of L<perlvar/$.> - it refers to the number
of lines that has been read. When reading towards the origin, it refers to the
number of lines that can still be read.

When C<switch> is called, the direction is changed, but the line number
remains the same. Therefore, the last-read line before changing directions will
be repeated by C<readline>.

=cut

# current line number, 1-based
# forward:  the line that has just been read
# backward: the line that is going to be read
sub line_num {
    my ($x) = @_;
    return $x->{line};
}

=pod

=item tell

Returns the current position of the filehandle.

=cut

# logical cursor on filehandle
sub tell {
    my ($x) = @_;
    my $pos = 0;
    for my $s (@{$x->{buffer}}) {
        $pos += length $s;
    }
    return ($x->{move} == 1) ? $x->{cur} - $pos : $x->{cur} + $pos;
}

=pod

=item fh

Returns the underlying filehandle. This is mainly useful for file-locking.

Notice that this actually breaks the encapsulation of File::Bidirectional,
therefore it becomes the user's responsibility to ensure that nothing bad
happens to the underlying filehandle. For example, it should definitely not be
closed.

The underlying filehandle will be returned with its seek position set to what is
returned by C<tell>. It should generally be okay for this seek position to be
modified (the object remembers its own seek position and will always restore
it). Any other operations on the filehandle, however, is very likely to void
your warranty. =)

=cut

sub fh {
    my ($x) = @_;
    sysseek($x->{fh}, $x->tell(), SEEK_SET);
    return $x->{fh};
}



# used only as fail-safe default
sub _read_line {
    my ($x) = @_;
    return 
        ($x->{move} == 1 ) ? $x->_next_line() :
        ($x->{move} == -1) ? $x->_prev_line() :
        undef;
}


sub _next_line {
    my ($x) = @_;
    # 1. more than 1 line is in the buffer, so the top of the buffer is a
    # complete line
    # 2. only line -1 (last line) remains in the buffer
    # 3. nothing else to read, i.e. return undef
    while (1) {
        if (@{$x->{buffer}} > 1 || $x->{cur} == $x->{file_size}) {
            my $line = shift @{$x->{buffer}};
            $x->{line} += $x->{origin} if defined $line;
            return $line;
        }

        # no complete line, so read something

        # reading forward is easy - just sysseek() to where the bottom of the
        # buffer is, and let sysread() do the rest
        sysseek($x->{fh}, $x->{cur}, SEEK_SET)
            or croak $!;

        # sysread returns undef for errors;
        # due to the pre-condition, 0 should not occur either
        my $tmp;
        my $size = sysread($x->{fh}, $tmp, $x->{block_size})
            or croak $!;
        $x->{cur} += $size;

        # prepend to the temp the leftover partial line in the buffer
        $tmp = pop (@{$x->{buffer}}) . $tmp
            if (@{$x->{buffer}});

        # platform-dependent translation
        $tmp =~ s/$x->{translate}/\n/
            if defined $x->{translate};

        # split the temp and store it in the buffer
        @{$x->{buffer}} = $tmp =~ /$x->{re}/gs;
    }
}

sub _prev_line {
    my ($x) = @_;
    while (1) {
        # 1. more than 1 line is in the buffer, so the bottom of the buffer is
        # a complete line
        # 2. only line 1 remains in the buffer
        # 3. nothing else to read, i.e. return undef
        if (@{$x->{buffer}} > 1 || $x->{cur} == 0) {
            my $line = pop @{$x->{buffer}};
            $x->{line} -= $x->{origin} if defined $line;
            return $line;
        }

        # no complete line, so read something

        # reading backward requires us to first calculate where the top of the
        # buffer will reach. be careful to handle trailing bytes properly.
        my $read_size = $x->{block_size};
        $x->{cur} -= $x->{block_size};
        if ($x->{cur} < 0) {
            $read_size += $x->{cur};
            $x->{cur} = 0;
        }
        sysseek($x->{fh}, $x->{cur}, SEEK_SET)
            or croak $!;

        # sysread returns undef for errors;
        # due to the pre-condition, 0 should not occur either
        my $tmp = '';
        sysread($x->{fh}, $tmp, $read_size) == $read_size
            or croak $!;

        # append to the temp the leftover partial line in the buffer
        $tmp .= pop @{$x->{buffer}}
            if (@{$x->{buffer}});

        # platform-dependent translation
        $tmp =~ s/$x->{translate}/\n/
            if defined $x->{translate};

        # split the temp and store it in the buffer
        @{$x->{buffer}} = $tmp =~ /$x->{re}/gs;
    }
}

# used only as fail-safe default
sub _eof {
    my ($x) = @_;
    return 
        ($x->{move} == 1 ) ? $x->next_eof() :
        ($x->{move} == -1) ? $x->prev_eof() :
        undef;
}

sub _next_eof {
    my ($x) = @_;
    return $x->{cur} == $x->{file_size} && @{$x->{buffer}} == 0;
}

sub _prev_eof {
    my ($x) = @_;
    return $x->{cur} == 0 && @{$x->{buffer}} == 0;
}

# fixes up our aliases so that we eliminate the indirection functions
# _read_line() and _eof()
sub _fixup_alias {
    my ($x) = @_;

    # TODO: walk through the symbol table to do this automatically?

    # redefining aliases
    no warnings qw/redefine/;
    *READLINE   = ($x->{move} == 1) ? \&_next_line : ($x->{move} == -1) ? \&_prev_line : undef;
    *getline    = ($x->{move} == 1) ? \&_next_line : ($x->{move} == -1) ? \&_prev_line : undef;
    *readline   = ($x->{move} == 1) ? \&_next_line : ($x->{move} == -1) ? \&_prev_line : undef;
    *eof        = ($x->{move} == 1) ? \&_next_eof  : ($x->{move} == -1) ? \&_prev_eof  : undef;
    *EOF        = ($x->{move} == 1) ? \&_next_eof  : ($x->{move} == -1) ? \&_prev_eof  : undef;
}


# function
sub _is_dos  {
    return $^O =~ /^(dos|os2|mswin32|cygwin)$/i;
}

# function
sub _is_mac {
    return $^O =~ /^(macos)$/i;
}

sub _dump {
    my ($x) = @_;
    require YAML;

    # YAML crashes for regexes
    my %h = map {$_ => $x->{$_}} grep {!/^re$/} keys %$x;
    return YAML::Dump(\%h);
}

=pod

=back

=head1 TIED HANDLE INTERFACE

    local *F;
    tie *F, "File::Bidirectional", $file, {origin => 1}
        or die $!;

    while (my $line = <F>) { ... }

    (tied *F)->switch();

The C<TIEHANDLE>, C<READLINE>, C<EOF>, C<CLOSE> and C<TELL> are aliased to the
constructor and the lower-case method names, respectively. All other tied
operations, such as seeking and writing, are unsupported and will generate an
unknown method area.

To use the other methods, it is necessary to get at the reference to the object
underlying the tied variable via L<perlfunc/tied>.

=head1 LINE ENDINGS

Currently, File::Bidirectional attempts to imitate Perl by converting the
platform-specific line separator into C<\n>. Currently, this only means
converting C<\r> on MacOS, and C<\r\n> on DOS and Windows-type systems (when the
C<binmode> option is not set).

So far, this module has only been tested on Unix where line endings do not need
to be converted, thus it will be greatly appreciated if users can feedback
whether the line endings conversion work on their respective platforms.

=head1 BENCHMARKS

As would be expected, File::Bidirectional is hardly as fast as native Perl I/O. To
break the news gently, it can be up to an order of magnitude slower...

Reading through a 250MB file with various methods yield the following numbers:

    Method                      | Time (s)
    --------------------------------------
    Native Perl                 |   5
    IO::File                    |  16
    File::Bidirectional (OO)    |  42
    File::Bidirectional (tied)  |  51

To be optimistic about it, in the best case File::Bidirectional takes 2.6 times
the time taken for IO::File. For smaller files, the absolute time difference
may be less noticeable, so you will have to decide if the tradeoff is worth it
for your application. It is about as fast as I can make it without dropping
down into C, but if anybody has a compelling need for speed or ideas on how to
optimize things, please do drop me a line.

The benchmarks were performed circa 2005, on a Pentium-4 machine with clockspeed
2.8GHz, a 7200rpm IDE harddisk, running Debian sarge and ext3. The programs
tested were the respective variants of

    while (my $line = <$fh>) { chomp $line; }

The record separator was simply C<"\n"> and no newline translation took place.

=head1 AUTHOR

Kian Win Ong, cpan@bulk.squeakyblue.com

=head1 COPYRIGHT

Copyright (C) 2005 by Kian Win Ong. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself. This can be either the GNU General Public License or the Artistic
License, as specified in the Perl README file.

=head1 ACKNOWLEDGEMENTS

Thanks goes out to Uri Guttman, the author of File::ReadBackwards, from which I
stole a bunch of code and tests. =)

=cut

1;
