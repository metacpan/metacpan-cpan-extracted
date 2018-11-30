#!/usr/bin/perl
use strict;
use warnings;

my ( $swt, $user ) = @ARGV;

exit !( $swt eq '-uid' && $user eq 'dwho' );
