#!/usr/bin/perl

use strict;
use warnings;

use Benchmark qw(cmpthese);
use Method::WeakCallback qw(weak_method_callback
                            weak_method_callback_cached
                            weak_method_callback_static);
use curry::weak;

sub new {
    bless { foo => 1 };
}

sub foo { shift->{foo} }

for my $n (1, 2, 5, 10, 100, 1_000, 10_000, 100_000) {

    cmpthese -1, { "create_cache$n" => sub {
                       my $o = main->new;
                       weak_method_callback_cached($o, 'foo') for 1..$n;
                   },
                   "create_static$n" => sub {
                       my $o = main->new;
                       weak_method_callback_static($o, 'foo') for 1..$n;
                   },
                   "create_nocache$n" => sub {
                       my $o = main->new;
                       weak_method_callback($o, 'foo') for 1..$n;
                   },
                   "create_curry$n" => sub {
                       my $o = main->new;
                       $o->curry::weak::foo for 1..$n;
                   },
                 };

    cmpthese -1, { "call_cache$n" => sub {
                       my $o = main->new;
                       my $cb = weak_method_callback_cached($o, 'foo');
                       &$cb for 1..$n;
                   },
                   "call_static$n" => sub {
                       my $o = main->new;
                       my $cb = weak_method_callback_static($o, 'foo');
                       &$cb for 1..$n;
                   },
                   "call_nocache$n" => sub {
                       my $o = main->new;
                       my $cb = weak_method_callback($o, 'foo');
                       &$cb for 1..$n;
                   },
                   "call_curry$n" => sub {
                       my $o = main->new;
                       my $cb = $o->curry::weak::foo;
                       &$cb for 1..$n;
                   },
                 };

    cmpthese -1, { "combined_cache$n" => sub {
                       my $o = main->new;
                       weak_method_callback_cached($o, 'foo')->() for 1..$n;
                   },
                   "combined_static$n" => sub {
                       my $o = main->new;
                       weak_method_callback_static($o, 'foo')->() for 1..$n;
                   },
                   "combined_nocache$n" => sub {
                       my $o = main->new;
                       weak_method_callback($o, 'foo')->() for 1..$n;
                   },
                   "combined_curry$n" => sub {
                       my $o = main->new;
                       $o->curry::weak::foo->() for 1..$n;
                   },
                 }
}
