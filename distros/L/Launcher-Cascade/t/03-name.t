#!perl -T
use Test::More tests => 1;

use Launcher::Cascade::Base;

my $A = new Launcher::Cascade::Base -name => '03-name';
is("$A", '03-name');
