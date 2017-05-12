#!/usr/bin/env perl

# Original authors: don
# $Revision: $


use strict;
use warnings;

use Test::More tests => 4;

use JSON::DWIW;

my $json = '{"a":"foo","b":true, "c":null, "d":5, "e":6.0e-9, "f":false}';
my $cb = sub { my ($val) = @_; return "'$val'" };
my $num_cb = sub { my ($val) = @_; return "'$val'" };

my $data = JSON::DWIW::deserialize($json, { parse_constant => $cb,
                                            parse_number => $num_cb});

ok($data, 'no crash with callbacks');

ok($data->{b} eq "'true'" && $data->{f} eq "'false'", 'booleans');

ok($data->{d} eq "'5'", 'integers');

ok($data->{e} eq "'6.0e-9'", 'floats');

