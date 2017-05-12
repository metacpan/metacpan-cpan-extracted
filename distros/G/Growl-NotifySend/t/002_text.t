#!perl -w
use strict;
use utf8;
use Test::More;

use Growl::NotifySend;

Growl::NotifySend->show(
    summary => 'Testing Growl::NotifySend',
    body    => 'こんにちはこんにちは！' . "\n",
);

pass;

done_testing;
