#!/usr/bin/env perl
use LWP::Online qw(:skip_all);
use Test::More;
use common::sense;

require_ok(q{ICANN::RST});

my $url = ICANN::RST::Spec->current_version;
isa_ok($url, q{URI});

done_testing;

