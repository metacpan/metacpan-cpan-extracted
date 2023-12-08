#!perl -T

use Test::More tests => 8;
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Unpack2;
use Data::Dumper;

my $u = File::Unpack2->new();
my $r = $u->exclude(vcs => 1, add => ['*.orig', 'a*a'], re => 1);

ok("/var/tmp.svn/foo"   !~ m{$r}, "vcs !~ tmp.svn/");
ok("/var/tmp/.svn/foo"  =~ m{$r}, "vcs =~ tmp/.svn/");
ok("/var/tmp/.svn"      =~ m{$r}, "vcs =~ tmp/.svn");
ok("/var/tmp/test.orig" =~ m{$r}, "*.orig =~ test.orig");
ok("/var/tmp/ashaba"    =~ m{$r}, "a*a =~ /ashaba");
ok("/var/tmp/ash/ba"    !~ m{$r}, "a*a =~ /ash/ba");
ok("/var/tmp/kashaba"   !~ m{$r}, "a*a !~ /kashaba");
ok("/var/tmp/ashab"     !~ m{$r}, "a*a !~ /ashab");

# diag(Dumper $r, $u);	# WHOOPS, $u kills Data::Dumper???
