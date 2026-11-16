package IO::Factotum::sourcehighlight;

use v5.16;
use warnings;

use IO::Factotum;

# --failsafe gives a file whose language is not known as it is, and
# --infer-lang tells the language of a script by its first line
our @COMMAND = qw(source-highlight --failsafe --infer-lang -f esc);

# The colors: esc.style is the style of source-highlight for the
# terminal
our @STYLE = qw(--style-file=esc.style);

# A file larger than this is left as it is, 0 for no limit
our $MAX_SIZE = 256 * 1024;

# A file which has an escape character is left as it is, and so are
# an empty file and a large one.
sub match {
    my $file = shift;
    return 0 unless -f $file;
    my $size = -s _ or return 0;
    return 0 if $MAX_SIZE and $size > $MAX_SIZE;
    open my $fh, '<:raw', $file or return 0;
    local $/;
    my $content = <$fh> // return 0;
    index($content, "\e") < 0;
}

# This is called in a process of its own (IO::Factotum), which
# becomes that of source-highlight.  When it fails, as with a style
# file which is not found, the file is read as it is.
sub highlight {
    my $file = $_[-1];
    exec @COMMAND, @STYLE, '-i', $file
	or die "source-highlight: $!\n";
}

my $done;
sub setup {
    return if $done++;
    IO::Factotum::register(match => \&match, command => [ \&highlight ]);
    return;
}

sub import {
    setup();
    IO::Factotum::tie_argv();
}

1;

__END__

=encoding utf-8

=head1 NAME

IO::Factotum::sourcehighlight - syntax highlight by GNU Source-highlight

=head1 SYNOPSIS

    perl -MIO::Factotum::sourcehighlight -ne 'print' file.c

    ansicolumn --factotum=sourcehighlight file.c file.h

=head1 DESCRIPTION

This module registers a converter of L<IO::Factotum> which colors
source files by the C<source-highlight> command of GNU
Source-highlight, the one often used with C<less> through
C<LESSOPEN>:

    source-highlight --failsafe --infer-lang -f esc \
        --style-file=esc.style -i FILE

The language is told by C<source-highlight> from the name of the
file, and that of a script from its first line.  A file whose
language is not known is read as it is, and so are a file which has
an escape character already, an empty file, and a file larger than
C<$IO::Factotum::sourcehighlight::MAX_SIZE> bytes (256 KB by default,
0 for no limit).

The colors are those of C<esc.style>, which comes with
C<source-highlight>.  Set C<@IO::Factotum::sourcehighlight::STYLE> to
use another style file:

    @IO::Factotum::sourcehighlight::STYLE = ('--style-file=my.style');

Loaded by C<use> or C<-M>, it also ties C<ARGV>
(C<IO::Factotum::tie_argv>), and a program which reads by
C<E<lt>E<gt>> gets the colored text.  C<setup> only registers the
converter.

=head1 INSTALL

C<source-highlight> is in Homebrew and in the packages of the Linux
distributions:

    brew install source-highlight

=head1 SEE ALSO

L<IO::Factotum>, L<IO::Factotum::skylighting>

L<https://www.gnu.org/software/src-highlite/>

=cut
