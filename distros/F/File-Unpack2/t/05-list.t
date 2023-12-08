#!perl -T

use Test::More tests => 1;
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Unpack2;
use Data::Dumper;

my $u = File::Unpack2->new();
my $s = join '', map { sprintf $_->[0],$_->[1],$_->[2] } $u->list();

ok($s !~ m{CODE\(0x}s, "list() must not have CODE(0x...), expand _my_shell_quote to fix");
