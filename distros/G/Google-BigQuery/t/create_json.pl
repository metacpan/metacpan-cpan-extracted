#!/usr/bin/env perl
use strict;
use warnings;
use JSON qw(encode_json);

my $count = shift @ARGV || 100000;
my $data = "data-${count}.json";
open my $out, ">", $data;
for (my $i = 1; $i <= $count; $i++) {
  my $data = {};
  $data->{id} = $i;
  $data->{name} = "name${i}";
  if ($i % 3 == 0) {
    $data->{address} = 'TOKYO';
  }
  if ($i % 5 == 0) {
    $data->{phone} = 1234567890;
  }
  print $out encode_json($data), "\n";
}
close $data;
`gzip $data`;
