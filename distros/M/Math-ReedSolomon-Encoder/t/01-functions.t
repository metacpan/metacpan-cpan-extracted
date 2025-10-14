#!/usr/bin/env perl
use strict;
use Test::More;
use Math::ReedSolomon::Encoder qw< :all >;

# tests from:
# https://en.wikiversity.org/wiki/Reed%E2%80%93Solomon_codes_for_coders
my @tests = (
   [ [ 0x12, 0x34, 0x56, 0x37 ], [ 0xe6, 0x78, 0xd9 ] ],
   [
      [
         0x40, 0xd2, 0x75, 0x47, 0x76, 0x17, 0x32, 0x06,
         0x27, 0x26, 0x96, 0xc6, 0xc6, 0x96, 0x70, 0xec,
      ],
      [ 0xbc, 0x2a, 0x90, 0x13, 0x6b, 0xaf, 0xef, 0xfd, 0x4b, 0xe0 ]
   ]
);

for my $test (@tests) {
   my ($message_aref, $exp_eccs_aref) = $test->@*;
   my $nsym = $exp_eccs_aref->@*;

   is_deeply rs_correction($message_aref, $nsym), $exp_eccs_aref,
      'rs_correction';
   is_deeply rs_encode($message_aref, $nsym),
      [ $message_aref->@*, $exp_eccs_aref->@* ], 'rs_encode';

   my $message_str = join '', map { chr($_) } $message_aref->@*;
   my $exp_eccs_str = join '', map { chr($_) } $exp_eccs_aref->@*;
   is rs_correction_string($message_str, $nsym), $exp_eccs_str,
      'rs_correction_string';
   is rs_encode_string($message_str, $nsym), $message_str . $exp_eccs_str,
      'rs_encode_string';
}

done_testing();
