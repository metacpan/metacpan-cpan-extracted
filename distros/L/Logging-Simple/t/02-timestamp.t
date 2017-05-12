#!/usr/bin/perl
use strict;
use warnings;

use Logging::Simple;
use Test::More;

my $mod = 'Logging::Simple';

{ # return

    my $log = $mod->new;
    my $time = $log->timestamp;

    like (
        $time,
        qr/^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\.\d{3}/,
        "timestamp() returns correctly"
    );
}
done_testing();

