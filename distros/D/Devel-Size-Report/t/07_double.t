#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  $| = 1; 
  plan tests => 4;
  chdir 't' if -d 't';
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  }

use Devel::Size::Report qw/ report_size /;

#############################################################################
# create a hash, were all the keys point to the same scalar in memory

use Array::RefElem qw/hv_store av_push/;

my $hash = {}; my $a = undef;

hv_store (%$hash, 'a' , $a);
hv_store (%$hash, 'b' , $a);
hv_store (%$hash, 'c' , $a);

#############################################################################
# do a report on it (without tracking doubles)

my $double = report_size( $hash, { addr => 1 } );

unlike ($double, qr/double scalar.*0 bytes(.|\n)*double scalar.*0 bytes/i, 'dont see two doubles');

#############################################################################
# do a report on it (with tracking doubles)

$double = report_size( $hash, { addr => 1, doubles => 1} );

like ($double, qr/double scalar.*0 bytes(.|\n)*double scalar.*0 bytes/i, 'seen two doubles');

#############################################################################
# create an array, were all the entries point to the same scalar in memory

my $array = [];

av_push (@$array, $a);
av_push (@$array, $a);
av_push (@$array, $a);

#############################################################################
# do a report on it (without tracking doubles)

$double = report_size( $array, { addr => 1 } );

unlike ($double, qr/double scalar.*0 bytes(.|\n)*double scalar.*0 bytes/i, 'dont see two doubles');

#############################################################################
# do a report on it (with tracking doubles)

$double = report_size( $hash, { array => 1, doubles => 1} );

like ($double, qr/double scalar.*0 bytes(.|\n)*double scalar.*0 bytes/i, 'seen two doubles');

