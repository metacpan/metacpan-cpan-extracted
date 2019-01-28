#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use EPublisher::Target;

{
    my $error = '';
    eval {
        my $target = EPublisher::Target->new({});
    } or $error = $@;

    like $error, qr/No target type given/;
}

done_testing();
