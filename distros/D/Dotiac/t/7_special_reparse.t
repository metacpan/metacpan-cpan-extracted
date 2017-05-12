use Test::More tests=>6;
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

chdir "t";
use Dotiac::DTL;

open FH,">test.html" or die "Can't open test.html for output: $!";
print FH "AAA";
close FH;
my $t=Dotiac::DTL->new("test.html");
is($t->string(),"AAA","Output from initial template");
sleep 1;
open FH,">test.html" or die "Can't open test.html for output: $!";
print FH "BBB";
close FH;
sleep 1;
$t=Dotiac::DTL->new("test.html",1);
is($t->string(),"BBB","Output from change template from the cache");
$t=Dotiac::DTL->new("test.html",1);
ok($t->{first}->isa("Dotiac::DTL::Compiled"),"Got compiled template");
is($t->string(),"BBB","Output from compiled template from the cache");
open FH,">test.html" or die "Can't open test.html for output: $!";
print FH "CCC";
close FH;

$t=Dotiac::DTL->new("test.html",1);
is($t->string(),"CCC","Output from rechange template from the cache");

unlink "test.html";
unlink "test.html.pm";
