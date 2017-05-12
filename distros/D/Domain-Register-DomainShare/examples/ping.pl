#!/usr/bin/perl -W -Ilib

use Domain::Register::DomainShare;
use Data::Dumper;

my $c = Domain::Register::DomainShare->new();
my @r = $c->ping();
print Dumper(\@r);

