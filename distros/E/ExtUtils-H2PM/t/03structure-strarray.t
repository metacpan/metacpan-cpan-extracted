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
         structure "struct idname",
            members => [
               id   => member_numeric,
               name => member_strarray,
            ];
         gen_output;
      };

is_deeply( [ split m/\n/, $code ],
    [ split m/\n/, <<"EOPERL" ],
package TEST;
# This module was generated automatically by ExtUtils::H2PM from $0

use Carp;
push \@EXPORT_OK, 'pack_idname', 'unpack_idname';

sub pack_idname
{
   \@_ == 2 or croak "usage: pack_idname(id, name)";
   my \@v = \@_;
   pack "l Z12 ", \@v;
}

sub unpack_idname
{
   length \$_[0] == 16 or croak "unpack_idname: expected 16 bytes, got " . length \$_[0];
   my \@v = unpack "l Z12 ", \$_[0];
   \@v;
}

1;
EOPERL
      'Structure with string' );

ok( evalordie("no strict; $code"), 'Code evaluates successfully' );

$INC{"TEST.pm"} = '$code';

is( TEST::pack_idname(0x1234, "Hello"),
    BIG_ENDIAN ? "\0\0\x12\x34Hello\0\0\0\0\0\0\0" : "\x34\x12\0\0Hello\0\0\0\0\0\0\0",
    'pack_idname()' );

is_deeply( [ TEST::unpack_idname( BIG_ENDIAN ? "\0\0\x12\x34Hello\0\0\0\0\0\0\0" : "\x34\x12\0\0Hello\0\0\0\0\0\0\0" ) ],
   [ 0x1234, "Hello" ],
   'unpack_idname()' );

done_testing;
