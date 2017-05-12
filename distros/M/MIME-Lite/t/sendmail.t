#!/usr/bin/perl

use lib "lib", "t";
use MIME::Lite;
use Test::More tests => 2;

use_ok('MIME::Lite') or exit 1;

# set up dummy sendmail args.
MIME::Lite->send('sendmail', '/foo/bar/sendmail -x -y -z');

# retrieve the settings.
my @prev = MIME::Lite->send(sendmail => '/foo/bar/sendmail');

is_deeply \@prev, ['sendmail', '/foo/bar/sendmail -x -y -z'],
    'sendmail args updated';
