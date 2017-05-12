#!perl -w
use strict;
use Test::More;

use Growl::NotifySend;

Growl::NotifySend->show(
    summary => 'Testing Growl::NotifySend',
    body    => 'Hello, world!' . "\n",
);

pass;

done_testing;
