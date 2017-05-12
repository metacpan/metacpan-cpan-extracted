#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib','t/lib';

use Test::More tests => 5;

use Log::Log4perl;

use Local::Foo;
use Local::Bar;
use Local::Twix;

Log::Log4perl->easy_init( { 
                            file     => ">/tmp/test-a1.log",
                            utf8     => 1,
                            category => "area1",
                            layout   => '%m%n' },

                            { 
                            file     => ">/tmp/test-a2.log",
                            utf8     => 1,
                            category => "area2",
                            layout   => '%m%n' }, 

                            { 
                            file     => ">/tmp/test-n.log",
                            utf8     => 1,
                            category => "",
                            layout   => '%m%n' }, 

 );



my $n = Local::Foo->new();

ok($n->test(),'log area1');
ok($n->test2(),'log area1');

my $log = Log::Log4perl->get_logger('area1');


ok($log->debug('fooobaaar'),'log classic');



my $n2 = Local::Bar->new();

ok($n2->test(),'log no category');


my $n3 = Local::Twix->new();

ok($n3->test(),'log default handle');


1;
