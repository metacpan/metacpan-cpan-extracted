#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use EPublisher::Config;

my $error;
eval {
    my $config = EPublisher::Config->get_config('/tmp/epublisher-not-existant.yml');
} or $error = $@;

like $error, qr'No \(existant\) config file given!';


done_testing();
