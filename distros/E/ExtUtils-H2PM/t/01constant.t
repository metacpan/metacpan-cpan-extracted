#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ExtUtils::H2PM;

sub evalordie
{
   my $code = shift;
   my $ret = eval $code;
   $@ and die $@;
   $ret;
}

my $code;

$code = do {
         module "TEST";
         include "t/test.h", local => 1;
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
      'Simple constant' );

ok( evalordie("no strict; $code"), 'Code evaluates successfully' );

$INC{"TEST.pm"} = '$code';

is( evalordie("TEST::DEFINED_CONSTANT()" ),
    10,
    'Code exports a constant of the right value' );

$code = do {
         module "TEST";
         include "t/test.h", local => 1;
         constant "DEFINED_CONSTANT", name => "CONSTANT";
         gen_output;
      };

is_deeply( [ split m/\n/, $code ],
    [ split m/\n/, <<"EOPERL" ],
package TEST;
# This module was generated automatically by ExtUtils::H2PM from $0

push \@EXPORT_OK, 'CONSTANT';
use constant CONSTANT => 10;

1;
EOPERL
      'Simple constant renamed' );

$code = do {
         module "TEST";
         include "t/test.h", local => 1;
         no_export;
         constant "DEFINED_CONSTANT";
         gen_output;
      };

is_deeply( [ split m/\n/, $code ],
    [ split m/\n/, <<"EOPERL" ],
package TEST;
# This module was generated automatically by ExtUtils::H2PM from $0

use constant DEFINED_CONSTANT => 10;

1;
EOPERL
      'No-export constant' );

$code = do {
         module "TEST";
         include "t/test.h", local => 1;
         constant "ENUMERATED_CONSTANT";
         gen_output;
      };

is_deeply( [ split m/\n/, $code ],
    [ split m/\n/, <<"EOPERL" ],
package TEST;
# This module was generated automatically by ExtUtils::H2PM from $0

use constant ENUMERATED_CONSTANT => 20;

1;
EOPERL
      'Enumerated constant' );

$code = do {
         module "TEST";
         include "t/test.h", local => 1;
         constant "STATIC_CONSTANT";
         gen_output;
      };

is_deeply( [ split m/\n/, $code ],
    [ split m/\n/, <<"EOPERL" ],
package TEST;
# This module was generated automatically by ExtUtils::H2PM from $0

use constant STATIC_CONSTANT => 30;

1;
EOPERL
      'Static constant' );

$code = do {
         module "TEST";
         use_export;
         include "t/test.h", local => 1;
         constant "MISSING_CONSTANT", ifdef => "MISSING_CONSTANT";
         gen_output;
      };

is_deeply( [ split m/\n/, $code ],
    [ split m/\n/, <<"EOPERL" ],
package TEST;
# This module was generated automatically by ExtUtils::H2PM from $0


1;
EOPERL
      'Missing constant' );

done_testing;
