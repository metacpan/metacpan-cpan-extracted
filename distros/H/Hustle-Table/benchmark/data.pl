#Data set to use in benchmarking
#
#Crates a common set of matchers and samples to test
#
#In main script:
#use FindBin;
#my($matchers,$samples)=do "$FindBin::Bin/data.pl";
#
#
use common::sense;
use Math::Random;
use POSIX;
my $count=10000;
our @matchers=(
	qr|^/another/regex(\d+)|oa,
	qr|^/regex(\d+)|oa,
	"/exact",
	"/another/exact",
	"/one/more/exact",
	qr/maybe some(\d+) more/
);

my @uri=qw(
	/exact
	/another/exact
        /another/regexX
	/regexX
	/one/more/exact
	/maybe someX more
	asd
	);

say "Building samples";
my @samples=map {$_=0 if $_<0; $_=$#uri if $_> $#uri; $uri[$_]=~ s/X+/int($_)/er} random_normal($count, (@uri-1)/2, 1);
local $,=", ";

(\@matchers,\@samples);
