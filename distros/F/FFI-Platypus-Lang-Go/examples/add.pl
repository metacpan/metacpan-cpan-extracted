#!/usr/bin/env perl

use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new(
  api  => 2,
  lib  => './add.so',
  lang => 'Go',
);
$ffi->attach( add => ['goint', 'goint'] => 'goint' );

print add(1,2), "\n";  # prints 3
