package IO::Factotum::Highlight::skylighting;

use v5.16;
use warnings;

use IO::Factotum;

our @COMMAND = qw(skylighting -f ansi -r -C 16 -S pygments);

# A file larger than this is left as it is, 0 for no limit.  The
# colored text is many times larger than the file, and takes time to
# fold: some seconds for a megabyte.
our $MAX_SIZE = 256 * 1024;

# A file which has an escape character is left as it is: skylighting
# takes the ANSI sequences in it apart, and exits with status 0.
# So are an empty file, which would get a line, and a large one.
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

# The names of interpreters which are not the names of the syntax
my %SYNTAX = (
    node  => 'javascript',
    tclsh => 'tcl',
    ksh   => 'bash',
    dash  => 'bash',
);

# The syntax of a script, by the interpreter on its first line
# (#!/usr/bin/env perl, #!/usr/bin/python3): the name of the command,
# after env and its options and variables, without the version number.
sub interpreter {
    my $line = shift;
    $line =~ /\A#!\s*(\S.*)/ or return undef;
    my @word = split ' ', $1;
    my $command = shift @word // return undef;
    if ($command =~ m{(?:\A|/)env\z}) {
	shift @word while @word and $word[0] =~ /\A-|=/;
	$command = shift @word // return undef;
    }
    my $name = $command =~ s{.*/}{}r =~ s/[\d.]+\z//r;
    return undef if $name eq '';
    $SYNTAX{$name} // $name;
}

# Run skylighting with the arguments, and return what it writes, or
# undef when it fails.  Its messages are thrown away by the caller.
sub skylighting {
    open my $fh, '-|', @COMMAND, @_ or return undef;
    my $out = do { local $/; <$fh> };
    close $fh or return undef;
    $out // '';
}

# Run skylighting on the file given as the last argument, and print
# what it gives without the sequences which do nothing: skylighting
# puts \e[22;23;24m after every reset, and resets twice at the top.
# A line which ends with two sequences gets an empty line after it
# when it is folded by Text::ANSI::Fold and the text fills the width.
# This is called in a process of its own (IO::Factotum), and dies
# when skylighting fails: the file is then read as it is.
sub highlight {
    my $file = $_[-1];
    # skylighting tells the language from the name of the file.  When
    # it can not, the interpreter on the first line tells it.
    my $out = skylighting($file) // do {
	open my $fh, '<', $file or die "$file: $!\n";
	my $syntax = interpreter(scalar <$fh> // '')
	    // die "skylighting failed\n";
	skylighting('-s', $syntax, $file) // die "skylighting failed\n";
    };
    $out =~ s/\e\[0m\K\e\[22;23;24m//g;
    $out =~ s/\e\[0m\K(?:\e\[0m)+//g;
    # CR LF stay together: the reset comes between them
    $out =~ s/\r((?:\e\[[0-9;]*m)+)$/$1\r/mg;
    print $out;
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

IO::Factotum::Highlight::skylighting - syntax highlight by skylighting

=head1 SYNOPSIS

    perl -MIO::Factotum::Highlight::skylighting -ne 'print' file.c

    ansicolumn --highlight file.c file.h

=head1 DESCRIPTION

This module registers a converter of L<IO::Factotum> which colors
source files by the C<skylighting> command, the syntax highlighter of
pandoc:

    skylighting -f ansi -r -C 16 -S pygments FILE

The language is told by C<skylighting> from the name of the file.
When the name does not tell it, as that of a script without an
extension, the interpreter on the first line does (C<#!/usr/bin/env
perl>, C<#!/bin/bash>).  A file whose language is not known is read as
it is, and so are a file which has an escape character already, an empty
file, and a file larger than C<$IO::Factotum::Highlight::skylighting::MAX_SIZE>
bytes (256 KB by default, 0 for no limit): the colored text is many
times larger than the file and takes time to process.

The C<pygments> style, the default of pandoc, has no background
color, and C<-C 16> uses the 16 colors of the terminal, so that the
colors go with those of the terminal.

The sequences which do nothing in the output of C<skylighting>, as
C<ESC[22;23;24m> after every reset, are taken away.

Loaded by C<use> or C<-M>, it also ties C<ARGV>
(C<IO::Factotum::tie_argv>), and a program which reads by
C<E<lt>E<gt>> gets the colored text.  C<setup> only registers the
converter.

=head1 INSTALL

C<skylighting> is in Homebrew and in the packages of the Linux
distributions:

    brew install skylighting

=head1 SEE ALSO

L<IO::Factotum>, L<IO::Factotum::Highlight::sky>,
L<IO::Factotum::Highlight::sourcehighlight>, L<Getopt::EX::Factotum>

L<https://github.com/jgm/skylighting>

=cut
