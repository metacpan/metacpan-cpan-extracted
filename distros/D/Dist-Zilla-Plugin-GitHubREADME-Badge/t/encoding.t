#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestBadges;

sub encoded_content {
  my $content  = pop;
  my $encoding = shift;
  return build_dist({}, {
    plugins => [
      $encoding ? ([Encoding => { match => 'README.*', encoding => 'utf-8' }]) : (),
    ],
    content => $content,
  })->{readme}->slurp_raw;
}

subtest 'no encoding' => sub {
  like encoded_content("x copy \xc2\xa9 x"), qr/x copy \xc2\xa9 x/,
    'utf-8 bytes preserved';
};

subtest 'bytes' => sub {
  skip_without_encoding;
  like encoded_content(bytes => "x copy \xa9 x"), qr/x copy \xa9 x/,
    'bytes preserved';
};

subtest 'encoding preserved' => sub {
  skip_without_encoding;
  like encoded_content(cp1252 => "x copy \x95 x"), qr/x copy \x95 x/,
    'non-unicode-compatible encoding preserved';
};

done_testing;
