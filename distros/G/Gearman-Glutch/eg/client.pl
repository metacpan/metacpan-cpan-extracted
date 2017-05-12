#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;

use Gearman::Client;

my $client = Gearman::Client->new();
$client->job_servers(qw/127.0.0.1:9999/);
my $ret = $client->do_task('echo', "foo");
if (ref $ret) {
    warn $$ret;
} else {
    warn $ret;
}
