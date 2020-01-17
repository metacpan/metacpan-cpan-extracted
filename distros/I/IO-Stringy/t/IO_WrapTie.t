use strict;
use warnings;

use IO::Handle;
use IO::Scalar;
use IO::WrapTie;

use Test::More tests => 5;

my $hello = 'Hello, ';
my $world = "world!\n";

#### test
my $s = '';
my $SH = IO::WrapTie->new('IO::Scalar', \$s);
isa_ok($SH, 'IO::WrapTie::Master', 'new: got the object');

#### test
print {$SH} $hello, $world;
is($s, "$hello$world", 'print {FH} ARGS: tied string is correct');

#### test
$SH->print($hello, $world);
is($s, "$hello$world$hello$world", 'FH->print(ARGS): tied string is correct');

#### test
$SH->seek(0,0);

#### test
my @x = <$SH>;
ok(
    (($x[0] eq "$hello$world") && ($x[1] eq "$hello$world") && !$x[2]),
    "array = <FH>"
);

#### test
my $sref = $SH->sref;
ok($sref eq \$s, "FH->sref");
