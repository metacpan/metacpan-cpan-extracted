#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Method::WeakCallback qw(weak_method_callback
                            weak_method_callback_cached);


my $inc_count;
my $destroy_count;

sub new {
    bless { foo => 1 };
}

sub inc {
    $inc_count++;
}

sub DESTROY {
    $destroy_count++;
}

my $obj = main->new;
my $cb = weak_method_callback $obj, 'inc';
$cb->();
is($inc_count, 1);
$cb->();
is($inc_count, 2);
undef $obj;
is($destroy_count, 1);
$cb->();
is($inc_count, 2);

$obj = main->new;
$cb = weak_method_callback_cached $obj, 'inc';
my $cb1 = weak_method_callback_cached $obj, 'inc';
my $obj1 = main->new;
my $cb2 = weak_method_callback_cached $obj1, 'inc';
is ($cb, $cb1, "callbacks are cached");
isnt ($cb, $cb2, "callbacks to different objects are cached independently");
$cb->();
is($inc_count, 3);
$cb->();
is($inc_count, 4);
undef $obj;
is($destroy_count, 2);
is($inc_count, 4);
$cb2->();
is($inc_count, 5);
undef $obj1;
is($destroy_count, 3);
$cb2->();
$cb1->();
$cb->();
is($inc_count, 5);
