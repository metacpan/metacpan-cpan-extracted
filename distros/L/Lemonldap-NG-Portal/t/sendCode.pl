#!/usr/bin/perl
use strict;
use warnings;

my ( $swt1, $user, $swt2, $code ) = @ARGV;
if ( $ENV{llngtmpfile} ) {
    open( FH, '>', $ENV{llngtmpfile} ) or die $!;
    print FH $code;
    close FH;
}

exit !($swt1 eq '-uid'
    && $user eq 'dwho'
    && $swt2 eq '-code'
    && defined $code );
