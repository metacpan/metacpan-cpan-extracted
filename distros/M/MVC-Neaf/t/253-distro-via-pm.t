#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

use lib __FILE__.'.lib';
use My::Project;

subtest 'static data' => sub {
    my ($status, $head, $content) = neaf->run_test('/files/robots.txt');
    is $status, 200, "file found";
    like $content, qr/robots/, "content as expected";
};

subtest 'template' => sub {
    my ($status, $head, $content) = neaf->run_test('/index.html');
    is $status, 200, "file found";
    like $content, qr/Hello, wo/, "content as expected";
};

done_testing;


