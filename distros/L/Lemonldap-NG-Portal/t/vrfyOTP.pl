#!/usr/bin/perl
use strict;
use warnings;

my ( $swt1, $user, $swt2, $code ) = @ARGV;

exit !($swt1 eq '-uid'
    && $user eq 'dwho'
    && $swt2 eq '-code'
    && $code eq '123456' );
