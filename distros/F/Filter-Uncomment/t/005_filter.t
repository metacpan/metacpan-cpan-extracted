# filter test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);
use Test::Cmd ;

use File::Temp qw/ tempfile tempdir /;

#--------------------------------------------------------

my $multi_single = 'use Filter::Uncomment qw(multi single) ;' ;
my $multi = 'use Filter::Uncomment qw(multi) ;' ;

my $code = <<'EOC' ;

use Filter::Uncomment 
	GROUPS =>
		{
		multi  => ['multi_line', 'multi line with spaces'] ,
		single => ['single_line', 'single line with spaces'] ,
		all    => 
			[
			'multi_line', 'multi line with spaces',
			'single_line', 'single line with spaces',
			] ,
		};

print "script 0 and start\n" ;
=for multi_line

print "'multi_line 0'\n" ;
print "'multi_line 1'\n" ;

=cut
print "script 1\n" ;
=for multi line with spaces

print "'multi line with spaces 0'\n" ;
print "'multi line with spaces 1'\n" ;

=cut
print "script 2\n" ;
=for multi_linedie "**** error on 'multi line' ****\n" ;

=cut
print "script 3\n" ;
##single_line print "'single_line'\n" ;
print "script 4\n" ;
##single line with spaces print "'single line with spaces'\n" ;
print "script 5\n" ;
##single_linedie "**** error on 'single line' ****\n" ;
print "script 6 and end\n" ;
EOC

my $multi_single_result = <<'EOR' ;
script 0 and start
'multi_line 0'
'multi_line 1'
script 1
'multi line with spaces 0'
'multi line with spaces 1'
script 2
script 3
'single_line'
script 4
'single line with spaces'
script 5
script 6 and end
EOR

my $multi_result = <<'EOR' ;
script 0 and start
'multi_line 0'
'multi_line 1'
script 1
'multi line with spaces 0'
'multi line with spaces 1'
script 2
script 3
script 4
script 5
script 6 and end
EOR

my $none_result = <<'EOR' ;
script 0 and start
script 1
script 2
script 3
script 4
script 5
script 6 and end
EOR

{
local $Plan = {'in code uncommenting' => 1} ;

my ($fh, $filename) = tempfile();
print $fh $multi_single, $code ;
close $fh ;

my $test = Test::Cmd->new
		(
		prog => '',
		workdir => '',
		#~ verbose => 1,
		) ;
		
$test->run(interpreter => "perl -Mblib $filename",)	;
like($test->stdout(), qr/$multi_single_result/, "multi and single uncommenting") ;

$test->cleanup() ;
}

{
local $Plan = {'in code uncommenting' => 1} ;

my ($fh, $filename) = tempfile();
print $fh $multi, $code ;
close $fh ;

my $test = Test::Cmd->new
		(
		prog => '',
		workdir => '',
		#~ verbose => 1,
		) ;
		
$test->run(interpreter => "perl -Mblib $filename",)	;
like($test->stdout(), qr/$multi_result/, "multi uncommenting") ;

$test->cleanup() ;
}

{
local $Plan = {'in code uncommenting' => 1} ;

my ($fh, $filename) = tempfile();
print $fh $code ;
close $fh ;

my $test = Test::Cmd->new
		(
		prog => '',
		workdir => '',
		#~ verbose => 1,
		) ;
		
$test->run(interpreter => "perl -Mblib $filename",)	;
like($test->stdout(), qr/$none_result/, "no uncommenting") ;

$test->cleanup() ;
}
