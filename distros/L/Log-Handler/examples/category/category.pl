#!/usr/bin/perl
use strict;
use warnings;
use Log::Handler;

my $log = Log::Handler->new();

$log->add(
    screen => {
        maxlevel => "info",
        category => "Foo"
    }
);

$log->info("Hello World!");

package Foo;
$log->info(__PACKAGE__);

package Foo::Bar;
$log->info(__PACKAGE__);

package Foooo;
$log->info(__PACKAGE__);
