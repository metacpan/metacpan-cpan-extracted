#!perl

use strict;
use warnings;

use Test::More tests => 6;

use Mac::NSGetExecutablePath 'NSGetExecutablePath';

my $path = NSGetExecutablePath();

ok defined($path), 'NSGetExecutablePath() does not return undef';
cmp_ok length($path), '>', 0,
                   'NSGetExecutablePath() returns something of positive length';

my $v = `$path -v`;

ok   defined($v), '`NSGetExecutablePath() -v` returns something';
like $v, qr/This is perl\b/, 'NSGetExecutablePath() points to a perl';

$v = `$path -le 'print "\$]"'`;
ok defined($v), q{`NSGetExecutablePath() -le 'print "$]"'` returns something};
1 while chomp $v;
is $v, "$]", 'NSGetExecutablePath() points to the same perl version';
