#!/usr/bin/env perl

use IO::Prompt::Hooked;
use Scalar::Util qw( looks_like_number );
use Lingua::EN::Inflect qw( NO );

IO::Prompt::Hooked::prompt( {
  validate   => sub { looks_like_number($_[0]) && $_[0] >= 0 && $_[0] < 256 },
  message    => "\nPlease enter a number between 0 and 255:",
  error      => sub {
    $_[1] == 0 && return '';
    return   'Input must be numeric, and in the range of 0 .. 255. ('
           . NO( 'attempt', $_[1])
           . " remaining.)\n";
  },
  default    => '0',
  tries      => 5,
  escape     => sub { $_[0] =~ qr/(?i:X)/ },
} );
