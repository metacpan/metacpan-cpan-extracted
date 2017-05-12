use File::Temp qw/ :POSIX /;
require Test::More;
require Dotiac::DTL;
use strict;
use warnings;
require Data::Dumper;

use Exporter;
our @EXPORT=qw/dtest/;

sub nor {
	my $value=shift;
	return $value unless $value;
	$value=~s/\r//g;
	return $value;
}

sub dtest {
	my $source=shift;
	my $expected=shift;
	my $param=shift;
	unlink "$source.pm";
	my $t;
	eval {
		$t=Dotiac::DTL->new($source,1);
	};
	if ($@) {
		Test::More::fail("Template generation $source: $@");
		undef $@;
	}
	else {
		Test::More::pass("Template generation $source");
	}
	my $res=nor($t->string($param));
	Test::More::is($res,$expected,"String output from file created template: $source");
	my $file = tmpnam();
	open FH,">",$file;
	binmode FH;
	select FH;
	$t->print($param);
	select STDOUT;
	close FH;
	open FH,"<",$file;
	binmode FH;
	Test::More::is(nor(do {local $/;<FH>}),$expected,"Print output from file created template: $source");
	close FH;
	eval {
		$t=Dotiac::DTL->new($source);
	};
	if ($@) {
		Test::More::fail("Template loading compiled $source:$@");
		undef $@;
	}
	else {
		if ($t->{first}->isa("Dotiac::DTL::Compiled")) {
			Test::More::pass("Template loading compiled $source");
		}
		else {
			Test::More::fail("Template loading compiled $source: is not compiled, but a $t->{first} ");
		}
	}
	Test::More::is(nor($t->string($param)),$expected,"String output from compiled template: $source");
	open FH,">",$file;
	binmode FH;
	select FH;
	$t->print($param);
	select STDOUT;
	close FH;
	open FH,"<",$file;
	binmode FH;
	Test::More::is(nor(do {local $/;<FH>}),$expected,"Print output from compiled template: $source");
	close FH;
	unlink $file;
	unlink "$source.pm";
	print STDERR "\n",Data::Dumper->Dump([$res,$expected],[qw/whatIgot expected/]) if $res ne $expected;
}
