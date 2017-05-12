#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ExtUtils::H2PM;

use constant LITTLE_ENDIAN => (pack("s",1) eq "\1\0");
use constant BIG_ENDIAN    => (pack("s",1) eq "\0\1");
BEGIN { LITTLE_ENDIAN or BIG_ENDIAN or die "Cannot determine platform endian" }

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
         structure "struct point",
            no_length_check => 1,
            members => [
               x => member_numeric,
               y => member_numeric,
            ];
         gen_output;
      };

ok( evalordie("no strict; $code"), 'Code evaluates successfully' );

is_deeply( [ TEST::unpack_point( BIG_ENDIAN ? "\0\0\x12\x34\0\0\x56\x78\0\0\x9a\xbc" : "\x34\x12\0\0\x78\x56\0\0\xbc\x9a\0\0" ) ],
   [ 0x1234, 0x5678 ],
   'unpack_point()' );

done_testing;
