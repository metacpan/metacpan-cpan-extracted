#!/usr/bin/perl

use strict;
use warnings;
use blib;
use Dumbbench;
use Cookie::Baker     ();
use Cookie::Baker::XS ();
use HTTP::XSCookies   ();

exit main();

sub main {
    my %cookies = (
        short   => 'foo=bar; path=/',
        long    => 'DV=; expires=Mon, 01-Jan-1990 00:00:00 GMT; path=/webhp; domain=www.google.com',
        longer  => 'whv=MtW_XszVxqHnN6rHsX0d; expires=Wed, 07 Jan 2026 11:10:40 GMT; domain=.wikihow.com; path=',
        encoded => '%2bBilbo%26Frodo%2b=%23Foo%20Bar%23; path=%2bMERRY%2b;',
    );

    if ($#ARGV < 0) {
        for my $name (sort keys %cookies) {
            my $cookie = $cookies{$name};
            run_benchmark($name, $cookie);
        }
    } else {
        for (my $pos = 0; $pos <= $#ARGV; ++$pos) {
            my $name = $ARGV[$pos];
            next if !exists($cookies{$name});
            run_benchmark($name, $cookies{$name});
        }
    }

    return 0;
}

sub run_benchmark {
    my ($name, $cookie) = @_;

    my $iterations = 1e5;
    my $bench = Dumbbench->new(
        target_rel_precision => 0.005,
        initial_runs         => 20,
    );

    $bench->add_instances(
        # Dumbbench::Instance::PerlSub->new(
        #     name => get_name('Cookie::Baker', $name),
        #     code => sub {
        #         for(1..$iterations){
        #             Cookie::Baker::crush_cookie($cookie);
        #         }
        #     },
        # ),

        Dumbbench::Instance::PerlSub->new(
            name => get_name('Cookie::Baker::XS', $name),
            code => sub {
                for(1..$iterations){
                    Cookie::Baker::XS::crush_cookie($cookie);
                }
            },
        ),

        Dumbbench::Instance::PerlSub->new(
            name => get_name('HTTP::XSCookies', $name),
            code => sub {
                for(1..$iterations){
                    HTTP::XSCookies::crush_cookie($cookie);
                }
            },
        ),
    );

    $bench->run;
    $bench->report;
}

sub get_name {
    my ($class, $cookie) = @_;

    my $max = 25;
    my $l = length($class);
    my $b = int(($max - $l) / 2);
    my $a = $max - $l - $b;
    return sprintf("%s %s %s - %-10s",
                   '=' x $b, $class, '=' x $a, $cookie);
}
