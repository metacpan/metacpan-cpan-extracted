#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {    
    use_ok('IOC::Service::Literal');   
}

can_ok('IOC::Service::Literal', 'new');

my $s = IOC::Service::Literal->new('log_file' => '/var/www/log');
isa_ok($s, 'IOC::Service::Literal');
isa_ok($s, 'IOC::Service');

is($s->name(), 'log_file', '... got the name back');
is($s->instance(), '/var/www/log', '... got the instance value back');

ok(!defined($s->setContainer()), '... this is a no-op');
ok(!defined($s->removeContainer()), '... this is a no-op');

throws_ok {
   IOC::Service::Literal->new() 
} 'IOC::InsufficientArguments', '... got the error we expected';

throws_ok {
   IOC::Service::Literal->new('log_file') 
} 'IOC::InsufficientArguments', '... got the error we expected';