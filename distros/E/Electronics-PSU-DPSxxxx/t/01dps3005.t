#!/usr/bin/perl

use v5.14;
use warnings;

use Future::AsyncAwait;

use Test::More;
use Test::Future::IO 0.04;

use Electronics::PSU::DPSxxxx;

my $test_fio = Test::Future::IO->controller;

my $psu = Electronics::PSU::DPSxxxx->new( fh => "FH" );

# Read model/version
{
   $test_fio->expect_syswrite_anyfh( "\x01\x03\x00\x0B\x00\x01\xF5\xC8" );
   $test_fio->expect_sysread_anyfh( 7 )
      ->will_done( "\x01\x03\x02\x0B\xBD\x7F\x05" );

   is( await $psu->read_model, 3005, '$psu->read_model yields model' );

   $test_fio->check_and_clear( '->read_model' );

   $test_fio->expect_syswrite_anyfh( "\x01\x03\x00\x0C\x00\x01\x44\x09" );
   $test_fio->expect_sysread_anyfh( 7 )
      ->will_done( "\x01\x03\x02\x00\x0E\x39\x80" );

   is( await $psu->read_version, 14, '$psu->read_version yields version' );

   $test_fio->check_and_clear( '->read_version' );
}

# Read UIN
{
   $test_fio->expect_syswrite_anyfh( "\x01\x03\x00\x05\x00\x01\x94\x0B" );
   $test_fio->expect_sysread_anyfh( 7 )
      ->will_done( "\x01\x03\x02\x09\x93\xFE\x79" );

   is( await $psu->read_input_voltage, 24.51, '$psu->read_input_voltage yields voltage' );

   $test_fio->check_and_clear( '->read_input_voltage' );
}

# Set output settings
{
   $test_fio->expect_syswrite_anyfh( "\x01\x06\x00\x00\x03\xFF\xC9\x7A" );
   $test_fio->expect_sysread_anyfh( 8 )
      ->will_done( "\x01\x06\x00\x01\x01\xC8\xD8\x0C" );
   $test_fio->expect_syswrite_anyfh( "\x01\x06\x00\x01\x01\xC8\xD8\x0C" );
   $test_fio->expect_sysread_anyfh( 8 )
      ->will_done( "\x01\x06\x00\x01\x01\xC8\xD8\x0C" );

   await $psu->set_voltage( 10.23 );
   await $psu->set_current( 0.456 );

   $test_fio->check_and_clear( '->set_voltage / ->set_current' );

   $test_fio->expect_syswrite_anyfh( "\x01\x06\x00\x09\x00\x01\x98\x08" );
   $test_fio->expect_sysread_anyfh( 8 )
      ->will_done( "\x01\x06\x00\x09\x00\x01\x98\x08" );

   await $psu->set_output_state( 1 );

   $test_fio->check_and_clear( '->set_output_state' );
}

# Measure output
{
   $test_fio->expect_syswrite_anyfh( "\x01\x03\x00\x02\x00\x01\x25\xCA" );
   $test_fio->expect_sysread_anyfh( 7 )
      ->will_done( "\x01\x03\x02\x03\xFE\x39\x34" );
   $test_fio->expect_syswrite_anyfh( "\x01\x03\x00\x03\x00\x01\x74\x0A" );
   $test_fio->expect_sysread_anyfh( 7 )
      ->will_done( "\x01\x03\x02\x00\x18\xB8\x4E" );

   is( await $psu->read_output_voltage, 10.22, '->read_output_voltage yields voltage' );
   is( await $psu->read_output_current, 0.024, '->read_output_current yields current' );

   $test_fio->check_and_clear( '->read_output_voltage / ->read_output_current' );
}

# Output state
{
   $test_fio->expect_syswrite_anyfh( "\x01\x03\x00\x08\x00\x01\x05\xC8" );
   $test_fio->expect_sysread_anyfh( 7 )
      ->will_done( "\x01\x03\x02\x00\x00\xB8\x44" );

   is( await $psu->read_output_mode, "CV", '->read_output_mode yields mode' );

   $test_fio->check_and_clear( '->read_output_mode' );
}

# Read multiple
{
   $test_fio->expect_syswrite_anyfh( "\x01\x03\x00\x02\x00\x02\x65\xCB" );
   $test_fio->expect_sysread_anyfh( 9 )
      ->will_done( "\x01\x03\x04\x01\xF9\x00\x14\x2B\xF1" );

   is_deeply( [ await $psu->read_multiple(qw( output_voltage output_current )) ],
              [ 5.05, 0.02 ],
              '->read_multiple yields both values' );

   $test_fio->check_and_clear( '->read_multiple' );
}

done_testing;
