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
            arg_style => "hashref",
            members => [
               x => member_numeric,
               y => member_numeric,
            ];
         gen_output;
      };

is_deeply( [ split m/\n/, $code ],
    [ split m/\n/, <<"EOPERL" ],
package TEST;
# This module was generated automatically by ExtUtils::H2PM from $0

use Carp;
push \@EXPORT_OK, 'pack_point', 'unpack_point';

sub pack_point
{
   ref(\$_[0]) eq "HASH" or croak "usage: pack_point(\\%args)";
   my \@v = \@{\$_[0]}{'x', 'y'};
   pack "l l ", \@v;
}

sub unpack_point
{
   length \$_[0] == 8 or croak "unpack_point: expected 8 bytes, got " . length \$_[0];
   my \@v = unpack "l l ", \$_[0];
   my %ret; \@ret{'x', 'y'} = \@v;
   \\%ret;
}

1;
EOPERL
      'Simple structure' );

ok( evalordie("no strict; $code"), 'Code evaluates successfully' );

$INC{"TEST.pm"} = '$code';

is( TEST::pack_point( { x => 0x1234, y => 0x5678 } ),
    BIG_ENDIAN ? "\0\0\x12\x34\0\0\x56\x78" : "\x34\x12\0\0\x78\x56\0\0",
    'pack_point()' );

is_deeply( TEST::unpack_point( BIG_ENDIAN ? "\0\0\x12\x34\0\0\x56\x78" : "\x34\x12\0\0\x78\x56\0\0" ),
   { x => 0x1234, y => 0x5678 },
   'unpack_point()' );

done_testing;
