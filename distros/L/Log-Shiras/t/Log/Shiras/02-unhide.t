#!perl
#########1 Initial Test File for Log::Shiras::Unhide        6#########7#########8#########9
my ( $lib, $examples_lib, $test_file );
BEGIN{
	use Test2::Bundle::Extended qw( !meta );
	my $file = (caller(0))[1];
	my 	$directory_ref = {
			t		=> './',# repo level
			Log		=> '../',# t folder level
			$file	=> '../../../',# test file level
		};
	for my $next ( <*> ){
		#~ diag $next;
		if( $next =~/^($file|t|Log)$/ ){
			my $return = $1;
			#~ diag $return;
			$lib 			= $directory_ref->{$return} . 'lib';
			$examples_lib	= $directory_ref->{$return} . 'examples';
			$test_file 		= $directory_ref->{$return} . 't/test_files/';
			#~ diag $lib;
			#~ diag $test_file;
			last;
		}
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ print longmess $_[0]; };
	$ENV{hide_warn} = 1;
}
$| = 1;
use Test2::Plugin::UTF8;
plan( 4 );
use lib $lib, $examples_lib;
#~ use Module::Runtime qw( require_module ) or diag $!;
use Log::Shiras::Unhide qw( :debug :Meditation  :Health :Family );
use Level1;
SKIP: {
	skip( "The filter module -Filter::Util::Call- is not installed", 3 ) if !$ENV{loaded_filter_util_call};
			my	$basic = 'Nothing';
	###LogSD 			$basic = 'Something';
	is		$basic, 'Something', 	"I can uncover 'Something'";
			my	$health = 'Sick';
	###Health 			$health = 'Health';
	is		$health, 'Health',		"The existence of Health is tested";
			my	$wealth = 'Broke';
	###Wealth		$wealth = 'Rich';
	isnt	$wealth, 'Rich',		"Attempting to find secret Wealth is tested (fails)";
}
use Level1; # Which uses Level2 which uses Level3
is(		Level1->check_return, 'Level3 Peace uncovered - Level2 Healing uncovered - Level1 Joy uncovered',
									"Test overriding lower level flags from the Unhide module");
note								"...Test Done";
done_testing;