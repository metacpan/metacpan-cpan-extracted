#!/usr/bin/perl
use strict;
use warnings;

use Logging::Simple;
use Test::More;

my $mod = 'Logging::Simple';

{ # default
    my $log = $mod->new;

    my $ok = eval { $log->fatal("died!"); 1; };

    if (! $ok){
        like ($@, qr/died!/, 'a call to fatal() does the right thing');
    }
}
done_testing();

