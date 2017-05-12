#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;

require 't/util.pl';
use Iterator::File::Status;

## Is IPC::Shareable present?  If not, don't bother testing it...
if(eval "use IO::Scalar; 1") {
  plan tests => 15;
} else {
  plan skip_all => 'IO::Scalar not installed...';
}



my $data = '';
my $fh = new IO::Scalar \$data;

{
  $data = '';
  my $status = new Iterator::File::Status(
                                          'status_filehandle' => $fh,
                                          'status_time_interval' => 1,
                                         );
  my $file = 't/data/status-fixed-interval.txt'; 
  my $expected = slurp( $file );
  
  my $i = 0;
  while ($i++ < 10000) {
    $status->emit_status_fixed_line_interval( $i );
  }

  is( $data, $expected, "emit_status_fixed_line_interval");
}



{
  $data = '';
  my $status = new Iterator::File::Status(
                                          'status_filehandle' => $fh,
                                          'status_time_interval' => 1,
                                         );
  my $file = 't/data/status-logarithmic.txt'; 
  my $expected = slurp( $file );
  
  my $i = 0;
  while ($i++ < 10000) {
    $status->emit_status_logarithmic( $i );
  }

  is( $data, $expected, "emit_status_logarithmic");
}



{
  $data = '';
  my $status = new Iterator::File::Status(
                                          'status_filehandle' => $fh,
                                          'status_time_interval' => 1,
                                         );
  
  my $i = 0;
  my $start = time;
  my $last = $start;
  my $fake_tests = 8;
  while (time - $start < 4) {
    $i++;

    ## So the test doesn't look hung...
    if (time - $last > 0) {
      $fake_tests--;
      pass(" ... emit_status_fixed_time_interval ...");
      $last = time;
    }
    
    $status->emit_status_fixed_time_interval( $i );
  }

  ## ... more hackery so tests didn't long hung.  Since when is hung a bad thing?
  while ($fake_tests >= 0) {
    $fake_tests--;
    pass(" ... emit_status_fixed_time_interval ...");
  }

  my $line_count = $data =~ s|\n|\n|g;
  ok( $line_count > 2, "emit_status_fixed_time_interval (>2)");
  ok( $line_count < 5, "emit_status_fixed_time_interval (<5)");
}



{

  $data = '';
  my $status = new Iterator::File::Status(
                                          'status_filehandle' => $fh,
                                          'status_time_interval' => 1,
                                         );

  my $file = 't/data/status-logarithmic.txt'; 
  my $expected = slurp( $file );
  
  my $i = 0;
  while ($i++ < 10000) {
    $status->emit_status( $i );
  }

  is( $data, $expected, "emit_status (logarithmic)");
}



{
  my $status;
  eval {
    $status = new Iterator::File::Status(
                                         'status_method' => 'notreal',
                                        );
  };

  ok( $@, "Invalid status_status_method");
}
