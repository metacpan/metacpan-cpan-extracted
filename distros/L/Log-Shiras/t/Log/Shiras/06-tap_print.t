#!perl
#########1 Test File for Log::Shiras::TapPrint    5#########6#########7#########8#########9
my ( $lib, $test_file );
BEGIN{
	use Modern::Perl;
	use Test2::Bundle::Extended qw( !meta );
	use Test2::Plugin::UTF8;
	plan( 25 );
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
			$test_file 		= $directory_ref->{$return} . 't/test_files/';
			#~ diag $lib;
			#~ diag $test_file;
			last;
		}
	}
	use Carp 'longmess';
	$SIG{__WARN__} = sub{ note longmess $_[0]; };
	$ENV{hide_warn} = 1;
}
$| = 1;
use lib $lib,;
use Capture::Tiny 0.12 qw( capture_stdout );
#~ use Log::Shiras::Unhide qw( :InternalTaPPrinT :InternalSwitchboarD );#
use Log::Shiras::Report::Test2Note;
use Log::Shiras::Switchboard;
use Log::Shiras::TapPrint;
use Log::Shiras::Test2;
my  		@tap_print_methods = qw(
				re_route_print
				restore_print
			);
my  ( 
			$test_instance, $ella_peterson, $capture, $name_space_ref, $report_ref,
			$test_class,
	);
note 									"easy question first ...";
map{									#Check that all exported methods are available
can_ok		'Log::Shiras::TapPrint', $_,
}			@tap_print_methods;
ok			$name_space_ref = {
				UNBLOCK =>{
					log_file => 'warn',
				},
				Log =>{
					UNBLOCK =>{
						log_file => 'warn',
					},
					Shiras =>{
						Switchboard =>{
							master_talk =>{
								_add_caller =>{
									UNBLOCK =>{
										log_file => 'warn',
									},
								},
							},
						},
						TapPrint =>{
							print =>{
								UNBLOCK =>{
									log_file => 'debug',
								},
							},
						},
					},
				},
				main =>{
					UNBLOCK =>{
						run		=> 'info',
					},
					yellow_submarine =>{
						UNBLOCK =>{
							run		=> 'warn',
						},
					},
					152 =>{
						UNBLOCK =>{
							run		=> 'warn',
						},
					}
				},
			},							"Build initial sources for testing";
ok 			$report_ref = {
				run	=> [], # Sending empty reports since it is not tested here
				log_file =>[ Log::Shiras::Report::Test2Note->new ], #Raise visibility to the actions being tested
			},							"Build initial reports for testing";
ok( lives{
			$ella_peterson = Log::Shiras::Switchboard->get_operator(
				name_space_bounds => $name_space_ref,
				reports	=> 	$report_ref,
			)
	},									"Get a switchboard operator (with settings)")
										or note($@);
ok		$test_class = Log::Shiras::Test2->new,# ( test_buffer_size => 100 ),
										"Build a test class to test the Switchboard activity";# with max buffer at 100";
note "confirm print works as expected prior to changes ...";
ok( lives{	$capture = capture_stdout{ print "Hello World 0\n"; }; },
										"Send a print statement that should be processed normally with no re-routing")
										or note($@);
like		$capture, qr/^Hello World 0$/,		
										"... and check that the output is not massaged or appended";
note									"turn on print statement capture ...";
ok			re_route_print(	report => 'run', ),
										"Initiating print re-routing";
ok( lives{	$capture = capture_stdout{ print "Hello World 1\n" } },
										"Send a basic print statement that should be routed to Log::Shiras::Switchboard rather than printed")
										or note($@);
is			$capture, '',		
										"... then check that nothing printed";
$test_class->match_message( 'run', 'Hello World 1',
										"... but the message was approved by the switchboard" );
ok(			re_route_print(
				fail_over => 1,
				report => 'run', 
			),							"Re-route print with fail_over turned on (There are no actual reports assigned to 'run' - future print calls should still print)");
ok( lives{	$capture = capture_stdout{ print "Hello World 2\n" } },
										"Send another print statement that should make it to STDOUT through the fail_over")
										or note($@);
like		$capture, qr/\nHello World 2$/,		
										"... and check that it did print";
ok( lives{
			$ella_peterson->add_reports(
				run =>[ { add_methods =>{ add_line => sub{} } } ],
			)
	},									"Add an actual report to the 'run' destination namespace")
										or note($@);
ok( lives{	$capture = capture_stdout{ print "Hello World 3\n" } },
										"Send another print statement that won't make it to STDOUT since there is no fail to recover")
										or note($@);
is			$capture, '',		
										"... and check that it did NOT print";
$test_class->match_message( 'run', 'Hello World 3',
										"...Then check that it was approved and routed (To the dummy report)" );
ok( lives{ 	$capture = capture_stdout{ yellow_submarine( "Hello World 4\n" ) } },
										"Send another print statement deeper in the main:: name-space that should be blocked due to a different permissions")
										or note($@);
is			$capture, '',		
										"... and check that it did NOT print";
$test_class->cant_match_message( 'run', 'Hello World 4',
										"...Then check that it got tossed altogether" );
ok( lives{	$capture = capture_stdout{ print "Hello World 5\n" } },
										"Send another print statement that is blocked by line number")
										or note($@);
is			$capture, '',		
										"... and check that it did NOT print";
$test_class->cant_match_message( 'run', 'Hello World 5',
										"...Then check that it got tossed altogether" );
note								"... Test Done";
done_testing;

sub yellow_submarine{
	print shift;
}