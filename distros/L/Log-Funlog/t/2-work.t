#!/usr/bin/perl -w
use Test::More qw(no_plan);

# Test if its work
# Should always be good as these tests are rather dumbs...

BEGIN {
	use_ok('Log::Funlog',"error","0.1");
}

use Config;
if ( -c '/dev/null' and -w '/dev/null') {
	$file='/dev/null';
	$daemon=1;
} else {
	diag "** no /dev/null available (or not writable) **\n";
	$file='test4log-funlog.tmp',
	$daemon=0;
}
isa_ok( Log::Funlog->new(verbose => '1/1'), 'Log::Funlog','Object returned is a Log::Funlog object' );
*Log=Log::Funlog->new(
	verbose => '5/5',
	cosmetic => '*',
	caller => 'all',
	daemon => $daemon,
	file => $file,
	colors => {
		'date' => 'black',
		'caller' => 'green',
		'msg' => 'black'
	},
	header => ' ) %dd ( )>-%pp-<(O)>%l--l<( %s{||}s '
);
for ($j=1;$j<=5;$j++) {
	$sent="Log level $j";
	is( Log($j,$sent), $sent,$sent);
}
sub gna {
	for ($j=1;$j<=5;$j++) {
		$sent="Gna sub level $j";
		is( Log($j,$sent) ,$sent,$sent);
	}
	&gna2;
	like( error("An error occured here"),qr/An error occured here/, 'error in gna');
}
sub gna2 {
	for ($j=1;$j<=5;$j++) {
		$sent="Gna2 sub level $j";
		is( Log($j,$sent),$sent,$sent);
	}
	like( error("An error occured here"),qr/An error occured here/,'error in gna2');
	&gna3;
}
sub gna3 {
	for ($j=1;$j<=5;$j++) {
		$sent="Gna3 sub level $j";
		is( Log($j,$sent),$sent,$sent);
	}
	like( error("An error occured here"),qr/An error occured here/,'error in gna3');
}
gna;
ok( ! Log(6,"plop"), 'Log level 6 (which should not be printed)' );
#The next one MUST BE at the end
ok( eval{ use Log::Funlog; Log::Funlog->new( verbose => '1/1', daemon => '1', file => "$file"); Log(1,'test')}, 'Creation of log file' );
