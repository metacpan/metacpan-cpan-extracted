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
         structure "struct msghdr",
            with_tail => 1,
            members => [
               cmd  => member_numeric,
               vers => member_numeric,
            ];
         gen_output;
      };

is_deeply( [ split m/\n/, $code ],
    [ split m/\n/, <<"EOPERL" ],
package TEST;
# This module was generated automatically by ExtUtils::H2PM from $0

use Carp;
push \@EXPORT_OK, 'pack_msghdr', 'unpack_msghdr';

sub pack_msghdr
{
   \@_ >= 2 or croak "usage: pack_msghdr(cmd, vers, [tail])";
   my \@v = \@_;
   pack "l c x3a*", \@v;
}

sub unpack_msghdr
{
   length \$_[0] >= 8 or croak "unpack_msghdr: expected 8 bytes, got " . length \$_[0];
   my \@v = unpack "l c x3a*", \$_[0];
   \@v;
}

1;
EOPERL
      'Structure with tail' );

ok( evalordie("no strict; $code"), 'Code evaluates successfully' );

$INC{"TEST.pm"} = '$code';

is( TEST::pack_msghdr(0x1234, 0x56, "hello\0"),
    BIG_ENDIAN ? "\0\0\x12\x34\x56\0\0\0hello\0" : "\x34\x12\0\0\x56\0\0\0hello\0",
    'pack_point()' );

is_deeply( [ TEST::unpack_msghdr( BIG_ENDIAN ? "\0\0\x12\x34\x56\0\0\0hello\0" : "\x34\x12\0\0\x56\0\0\0hello\0" ) ],
   [ 0x1234, 0x56, "hello\0" ],
   'unpack_point()' );

done_testing;
