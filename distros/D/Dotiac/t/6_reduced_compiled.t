package CompiledTemplate;


our $params = {var=>1};
use strict;
use warnings;

sub string() {
	return "BA".$tester::var."AB";
}

sub print() {
	print "BA";
	print $tester::var;
	print "AB";
}

package tester;
use File::Temp qw/ :POSIX /;
use Test::More tests=>8;
eval {
	require Test::NoWarnings;
	Test::NoWarnings->import();
	1;
} or do {
	SKIP: {
		skip "Test::NoWarnings is not installed", 1;
		fail "This shouldn't really happen at all";
	};
};
use strict;
use warnings;
require Dotiac::DTL::Reduced;

our $var="C";
chdir "t";
sub nor {
	my $value=shift;
	return $value unless $value;
	$value=~s/\r//g;
	return $value;
}


my $source="test_include.html";
my $t;
eval {
	$t=Dotiac::DTL->new($source);
};
if ($@) {
	Test::More::fail("Template loading reduced $source:$@");
	undef $@;
}
else {
	Test::More::pass("Template loading reduced $source");
}
is_deeply([$t->param()],['inc_object'],"Saved parameters from compiled template");
$source="justtext.html";
eval {
	my $x=Dotiac::DTL->new($source);
};
if ($@) {
	Test::More::pass("Template not loading unparsed $source:$@");
	undef $@;
}
else {
	Test::More::fail("Template not loading unparsed $source");
}

$source="test_include.html";
my $expected="ABACABA"; #No \n :)
my $param={inc_object=>Dotiac::DTL->compiled("CompiledTemplate")};
is_deeply([$param->{inc_object}->param()],['var'],"Saved parameters from custom package");
my $res=nor($t->string($param));
Test::More::is($res,$expected,"String output from reduced template: $source");

my $file = tmpnam();
open FH,">",$file;
binmode FH;
select FH;
$t->print($param);
select STDOUT;
close FH;
open FH,"<",$file;
binmode FH;
unlink $file;
Test::More::is(nor(do {local $/;<FH>}),$expected,"Print output from reduced template: $source");
close FH;

eval {
	my $x=Dotiac::DTL::Tag::load->new()
};
if ($@) {
	Test::More::pass("Loading tag load:$@");
	undef $@;
}
else {
	Test::More::fail("Loading tag load");
}
