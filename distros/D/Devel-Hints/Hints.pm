package Devel::Hints;
$VERSION = '0.21';

use strict;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
use 5.006;

require Exporter;
require DynaLoader;

@ISA		= qw( Exporter DynaLoader );
%EXPORT_TAGS	= ( all => \@EXPORT_OK );
@EXPORT_OK	= ( qw(
    cop_label
    cop_stash	cop_stashpv
    cop_file	cop_filegv
    cop_seq
    cop_arybase
    cop_line
    cop_warnings
    cop_io
    ),
);

__PACKAGE__->bootstrap($VERSION);

1;

__END__

=encoding utf8

=head1 NAME

Devel::Hints - Access compile-time hints at runtime

=head1 VERSION

This document describes version 0.21 of Devel::Hints, released
November 10, 2010.

=head1 SYNOPSIS

    use Devel::Hints ':all';

    LABEL:
    print cop_label();	    # 'LABEL'
    # cop_label is only settable on Perl 5.8 or below
    cop_label(0 => 'FOO');  # "goto FOO;" is valid after this point!

    print cop_file();	    # same as __FILE__
    print cop_filegv();	    # same as \$::{'_<' . __FILE__}
    print cop_stashpv();    # same as __PACKAGE__
    print cop_stash();	    # same as \%{__PACKAGE__ . '::'}
    print cop_seq();	    # an integer
    print cop_arybase();    # same as $[
    print cop_line();	    # same as __LINE__

    # cop_warnings() is only available to Perl 5.8 or below
    use warnings;
    print cop_warnings();   # same as compile-time ${^WARNING_BITS}

    # cop_io() is only available to Perl 5.7 and Perl 5.8
    use open IO => ':utf8';
    print cop_io();	    # same as compile-time ${^OPEN}

    {
	use IO => ':raw';
	print cop_io(1);    # access one uplevel; still ":utf8\0:utf8"
    }

=head1 DESCRIPTION

This module exports the C<cop> (code operator) struct as individual
functions; callers can call them to find out the lexical-scoped hints
that its block (or statement) is compiled under.

No functions are exported by default.  Each function may take an
optional positive integer as argument, indicating how many blocks
it should walk upward to obtain the C<cop> members.

Functions can also take another optional argument, which (if specified)
I<becomes the new value> for the hint, affecting the current statement
or block's behaviour.

On perl 5.10 or greater, the first argument to these functions can also be a
coderef. In that case, they return the value for the first statement in the
coderef's body, and if an argument is passed, they set the value for the entire
coderef body. C<cop_line> and C<cop_file> are slightly special here - #line
directives within the coderef will still be respected, and the line will be
offset by the correct amount within the sub.

=head1 FUNCTIONS

=over 4

=item cop_label

Label for the current construct.

=item cop_file

File name for the current source file.

=item cop_filegv

Glob reference to the current source filehandle.

=item cop_stashpv

The current package name.

=item cop_stash

Hash reference to the current symbol table.

=item cop_seq

Parse sequencial number.

=item cop_arybase

Array base the calling line was compiled with.

=item cop_line

The line number.

=item cop_warnings

Lexical warnings bitmask, a.k.a. C<${^WARNING_BITS}>.  If no lexical
warnings are in effect, returns the global warning flags as an integer.

=item cop_io

Lexical IO defaults, a.k.a. C<${^OPEN}>.  If no lexical IO layers
are in effect, an empty string is returned.  Always returns C<undef>
under pre-5.7 versions of Perl.

=back

=head1 ACKNOWLEDGMENTS

Thanks to Rafael Garcia-Suarez for demonstrating how to do this with
the elegant B<Inline::C> code on p5p, which I adapted to this
less elegant XS implementation.

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to Devel-Hints.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
