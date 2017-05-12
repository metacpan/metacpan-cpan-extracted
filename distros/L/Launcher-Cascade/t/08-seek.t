#!perl -T

use Test::More tests => 3;

use Launcher::Cascade::FileReader::Seekable;
my $f = new Launcher::Cascade::FileReader::Seekable
    -path => $0,
;

my $fh = $f->open();
my $line;
$line = <$fh> for 1 .. 3;

ok($line =~ /^use Test::More tests => \d+;/);
$f->close();

$fh = $f->open();
$line = <$fh>;
is($line, "\n");
$line = <$fh>;
is($line, "use Launcher::Cascade::FileReader::Seekable;\n");
