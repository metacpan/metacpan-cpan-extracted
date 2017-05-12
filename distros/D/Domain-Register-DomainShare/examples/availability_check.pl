#!/usr/bin/perl -W -Ilib

use Domain::Register::DomainShare;
use Data::Dumper;

my $email = '<your email registered with domainshare>';
my $password = '<your password> for domainshare>';

my $c = Domain::Register::DomainShare->new();

@r = $c->availability_check( { 
        email => $email,
        password => $password,
        domainname => 'TESTDOMAIN.TK' 
    } 
);

print Dumper(\@r);

