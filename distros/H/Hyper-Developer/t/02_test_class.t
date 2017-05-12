#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use File::Spec;

BEGIN {
    require lib;
    lib ->import(
        map {
            my $path = dirname(__FILE__) . "/$_";
            -d $path ? $path : ();
        } qw(../lib/ lib)
    );
}
our %PATH_OF = (
    t    => dirname(__FILE__),
    libs => [
        map {
            my $path = dirname(__FILE__) . "/$_";
            -d $path ? $path : ();
        } qw(../lib/ lib)
    ],
);

use Test::Class::Hyper::Developer;
use Test::Hyper::Developer::Generator::Control::Flow;

Test::Class::Hyper::Developer->runtests();
