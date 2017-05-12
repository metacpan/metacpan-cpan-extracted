#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );
use Config::INI::Reader;
use Config::INI::Writer;
use INI_File;

{
  my ($fh, $filename) = tempfile();
  tie(my %test,'INI_File',$filename);
  %test = (
    _ => { value => 1 },
    a => { value => 2 },
    b => { value => 3 }
  );
  my %copy_test = %test;
  untie(%test);
  is_deeply(\%copy_test,Config::INI::Reader->read_file($filename),'Data is saved');
  tie(my %load_test,'INI_File',$filename);
  is_deeply(\%copy_test,\%load_test,'Data is loaded');
}

{
  my ($fh, $filename) = tempfile();
  Config::INI::Writer->write_file({
    _ => { value => 1 },
    a => { value => 2 },
    b => { value => 3 }
  },$filename);
  tie(my %test,'INI_File',$filename);  
  $test{c} = { other_value => 2 };
  $test{a} = { value => 3 };
  delete $test{b};
  my %copy_test = %test;
  untie(%test);
  is_deeply(\%copy_test,Config::INI::Reader->read_file($filename),'Modified data is saved');
}

done_testing;