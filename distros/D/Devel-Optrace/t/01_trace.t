#!perl -w

use strict;
use Test::More tests => 6;
use Devel::Optrace;

my $buff;
open local(*STDERR), '>', \$buff;

Devel::Optrace->enable();

foreach my $mod (qw(Math::BigInt Data::Dumper File::Copy CGI POSIX)) {
	(my $file = "$mod.pm") =~ s{::}{/}g;

	ok require $file, "require $mod";
}


ok $buff;

Devel::Optrace->disable();
