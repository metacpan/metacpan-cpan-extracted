#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ExtUtils::H2PM;

my $code;

$code = do {
         module "TEST";
         include_path "t";
         include "test.h", local => 1;
         constant "DEFINED_CONSTANT";
         gen_output;
      };

is_deeply( [ split m/\n/, $code ],
    [ split m/\n/, <<"EOPERL" ],
package TEST;
# This module was generated automatically by ExtUtils::H2PM from $0

push \@EXPORT_OK, 'DEFINED_CONSTANT';
use constant DEFINED_CONSTANT => 10;

1;
EOPERL
      'include_path' );

done_testing;
