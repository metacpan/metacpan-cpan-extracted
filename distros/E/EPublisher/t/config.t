#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use EPublisher;
use EPublisher::Config;

my $error;
eval {
    my $config = EPublisher::Config->get_config('/tmp/epublisher-not-existant.yml');
} or $error = $@;

like $error, qr'No \(existant\) config file given!';

my $publisher = EPublisher->new;
is $publisher->config([]), undef;

is $publisher->_debug, undef;


done_testing();
