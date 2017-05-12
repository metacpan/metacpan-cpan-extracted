#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 2;
use File::Spec     ();
use Locale::Msgfmt ();

sub slurp {
	my $file = File::Spec->catfile(@_);
	local *FILE;
	open( FILE, '<', $file ) or die "open($file): $!";
	my @str = <FILE>;
	my $str = join "", @str;
	close FILE;
	return wantarray ? @str : $str;
}

my @all_bin = slurp("script", "msgfmt.pl");
my @all_pm  = slurp("lib", "Locale", "Msgfmt.pm");
my ($pm, $bin);
foreach( @all_bin ) {
	$_ =~ /^use Locale::Msgfmt (.*);$/;
	$bin = $1 if($1);
}
foreach( @all_pm ) {
	$_ =~ /^our \$VERSION = '(.*)';$/;
	$pm = $1 if($1);
}
is( $pm, $Locale::Msgfmt::VERSION );
is( $bin, $pm );
