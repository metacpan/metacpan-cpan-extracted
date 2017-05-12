#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ExtUtils::H2PM;

my $code;

$code = do {
         module "TEST";
         include "t/test.h", local => 1;
         constant "ENUMERATED_CONSTANT";
         structure "struct idname",
            members => [
               id   => member_constant("ENUMERATED_CONSTANT"),
               name => member_strarray,
            ];
         gen_output;
      };

is_deeply( [ split m/\n/, $code ],
           [ split m/\n/, <<"EOPERL" ],
package TEST;
# This module was generated automatically by ExtUtils::H2PM from t/04structure-constant.t

use Carp;
push \@EXPORT_OK, 'ENUMERATED_CONSTANT', 'pack_idname', 'unpack_idname';
use constant ENUMERATED_CONSTANT => 20;

sub pack_idname
{
   \@_ == 1 or croak "usage: pack_idname(name)";
   my \@v = \@_;
   splice \@v, 0, 0, ENUMERATED_CONSTANT;
   pack "l Z12 ", \@v;
}

sub unpack_idname
{
   length \$_[0] == 16 or croak "unpack_idname: expected 16 bytes, got " . length \$_[0];
   my \@v = unpack "l Z12 ", \$_[0];
   splice( \@v, 0, 1 ) == ENUMERATED_CONSTANT or croak "expected id == ENUMERATED_CONSTANT";
   \@v;
}

1;
EOPERL
      'Simple structure with a constant' );

done_testing;
