#!/usr/bin/perl
use 5.010001;
use strict;
use warnings;

use File::Spec::Functions qw/rel2abs/;
use IO::File;

my @examples;
BEGIN { @examples = glob 't/examples/*.pl' };
use Test::More tests => 1 + @examples;
BEGIN { use_ok('Mafia') }

for my $example (@examples) {
	my $out;
	close STDOUT;
	open STDOUT, '>', \$out;
	clean;

	do(rel2abs($example));
	$example =~ s/\.pl$//;
	my $ok = join '', IO::File->new("$example.out", '<')->getlines;
	is $out, $ok, substr $example, length 't/examples/'
}
