#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use EPublisher::Source;

{
    my $error = '';
    eval {
        my $source = EPublisher::Source->new({});
    } or $error = $@;

    like $error, qr/No source type given/;
}

done_testing();
