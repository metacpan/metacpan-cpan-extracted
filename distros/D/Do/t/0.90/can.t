#!/usr/bin/env perl

use lib 't/lib';

use Do;
use Test::This;
use Test::More;

my $pod = Test::This->new;

for my $file (map $pod->file("$_"), @{$pod->paths}) {
  next unless -f $file->lib_file;

  for my $name (@{$file->can_files}) {
    my $exists = !! -f $name;
    ok $exists, "$name exists";

    next if !$exists;

    my $data = $file->parse($name);

    ok $data->content('name'), "$name has pod name section";
    ok $data->content('usage'), "$name has pod usage section";
    ok $data->content('description'), "$name has pod description section";
    ok $data->content('signature'), "$name has pod signature section";
    ok $data->content('type'), "$name has pod type section";
  }
}

ok 1 and done_testing;
