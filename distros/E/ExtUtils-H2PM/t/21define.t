#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use ExtUtils::H2PM;

my $code;

$code = do {
         module "TEST";
         include "t/test.h", local => 1;
         define "EXTERNAL_CONSTANT", 40;
         constant "EXTERNAL_CONSTANT";
         gen_output;
      };

is_deeply( [ split m/\n/, $code ],
    [ split m/\n/, <<"EOPERL" ],
package TEST;
# This module was generated automatically by ExtUtils::H2PM from $0

push \@EXPORT_OK, 'EXTERNAL_CONSTANT';
use constant EXTERNAL_CONSTANT => 40;

1;
EOPERL
      'define' );

done_testing;
