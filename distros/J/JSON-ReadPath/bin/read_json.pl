#!/usr/bin/env perl
my $app = qx{which read_json};
chomp $app;
require $app;
