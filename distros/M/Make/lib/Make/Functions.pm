package Make::Functions;

use strict;
use warnings;

our $VERSION = '2.004';

my @temp_handles;    # so they don't get destroyed before end of program

sub wildcard {
    my ( $fsmap, @args ) = @_;
    ## no critic (BuiltinFunctions::RequireBlockMap)
    return map $fsmap->{glob}->($_), @args;
    ## use critic
}

sub shell {
    my ( $fsmap, @args ) = @_;
    my $value = `@args`;
    chomp $value;
    return split "\n", $value;
}

sub addprefix {
    my ( $fsmap, $prefix, $text_input ) = @_;
    ## no critic (BuiltinFunctions::RequireBlockMap)
    return map $prefix . $_, @{ Make::tokenize($text_input) };
    ## use critic
}

sub notdir {
    my ( $fsmap, $text_input ) = @_;
    my @files = @{ Make::tokenize($text_input) };
    s#^.*/## for @files;
    return @files;
}

sub dir {
    my ( $fsmap, $text_input ) = @_;
    my @files = @{ Make::tokenize($text_input) };
    foreach (@files) {
        $_ = './' unless s#^(.*)/[^/]*$#$1#;
    }
    return @files;
}

sub subst {
    my ( $fsmap, $from, $to, $value ) = @_;
    $from = quotemeta $from;
    $value =~ s/$from/$to/g;
    return $value;
}

sub patsubst {
    my ( $fsmap, $from, $to, $value ) = @_;
    $from = quotemeta $from;
    $value =~ s/$from(?=(?:\s|\z))/$to/g;
    return $value;
}

sub mktmp {
    my ( $fsmap, $text_input ) = @_;
    my $fh = File::Temp->new;    # default UNLINK = 1
    push @temp_handles, $fh;
    print $fh $text_input;
    return $fh->filename;
}

=head1 NAME

Make::Functions - Functions in Makefile macros

=head1 SYNOPSIS

    require Make::Functions;
    my ($dir) = Make::Functions::dir($fsmap, "x/y");
    # $dir now "x"

=head1 DESCRIPTION

Package that contains the various functions used by L<Make>.

=head1 FUNCTIONS

Implements GNU-make style functions. The call interface for all these
Perl functions is:

    my @return_list = func($fsmap, @args);

The args will have been extracted from the Makefile, comma-separated,
as in GNU make. The first arg is a L<Make/FSFunctionMap>.

=head2 wildcard

Returns all its args expanded using C<glob>.

=head2 shell

Runs the command, returns the output with all newlines replaced by spaces.

=head2 addprefix

Prefixes each word in the second arg with first arg:

    $(addprefix x/,1 2)
    # becomes x/1 x/2

=head2 notdir

Returns everything after last C</>.

=head2 dir

Returns everything up to last C</>. If no C</>, returns C<./>.

=head2 subst

In the third arg, replace every instance of first arg with second. E.g.:

    $(subst .o,.c,a.o b.o c.o)
    # becomes a.c b.c c.c

Since, as with GNU make, all whitespace gets ignored in the expression
I<as written>, and the commas cannot be quoted, you need to use variable
expansion for some scenarios:

    comma = ,
    empty =
    space = $(empty) $(empty)
    foo = a b c
    bar = $(subst $(space),$(comma),$(foo))
    # bar is now "a,b,c"

=head2 patsubst

Like L</subst>, but only operates when the pattern is at the end of
a word.

=head2 mktmp

Like the dmake macro, but does not support a file argument straight
after the macro-name.

The text after further whitespace is inserted in a temporary file,
whose name is returned. E.g.:

    $(mktmp $(shell echo hi))
    # becomes a temporary filename, and that file contains "hi"

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1996-1999 Nick Ing-Simmons.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
