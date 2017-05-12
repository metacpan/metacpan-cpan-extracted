use strict;
use warnings;
use Test::More;

use Locale::PO::Callback;
use File::Slurp;

my $filename = 't/demo.po';

my $result='';
my $storer = sub { $result .= $_[0]; };
my $rebuilder = Locale::PO::Callback::rebuilder($storer);

my $set_date = Locale::PO::Callback::set_date($rebuilder);

my $po = Locale::PO::Callback->new($set_date);
$po->read($filename);

my $expected = read_file($filename);

my @expected = split(/\n/, $expected);
my @result = split(/\n/, $result);

plan tests => scalar(@expected)+2;

is(scalar(@expected),
   scalar(@result),
   "number of lines didn't change");

for (my $i=0; $i<scalar(@expected); $i++) {
    if ($result[$i] =~ /^"po-revision-date/i) {
       ok($expected[$i] =~ m/^"po-revision-date/i,
          "date line begins with date header");
       isnt($result[$i], $expected[$i],
	    "date line was updated");
    } else {
	is($result[$i], $expected[$i], $expected[$i]);
    }
}

