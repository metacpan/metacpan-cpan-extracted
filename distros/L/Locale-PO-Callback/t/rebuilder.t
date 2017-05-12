use strict;
use warnings;
use Test::More;

use Locale::PO::Callback;
use File::Slurp;

plan tests => 1;

my $filename = 't/demo.po';

my $result='';
my $storer = sub { $result .= $_[0]; };
my $rebuilder = Locale::PO::Callback::rebuilder($storer);

my $po = Locale::PO::Callback->new($rebuilder);
$po->read($filename);

my $expected = read_file($filename);

$expected =~ s/\s*$//;
$result =~ s/\s*$//;

is($result, $expected, "Can rebuild files");

