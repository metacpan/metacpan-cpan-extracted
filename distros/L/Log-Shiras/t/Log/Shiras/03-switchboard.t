#!perl
#########1 Initial Test File for Log::Shiras::Switchboard   6#########7#########8#########9
my ( $lib, $test_file );
BEGIN{
	use Test2::Bundle::Extended qw( !meta );
	use Test2::Plugin::UTF8;
	use Test::Moose;
	plan( 90 );
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
	$SIG{__WARN__} = sub{ print longmess $_[0]; };
	$ENV{hide_warn_for_test} = 1;
}
$| = 1;
use Data::Dumper;
use lib $lib,;
#~ use Log::Shiras::Unhide qw( :debug  :InternalSwitchboarD );
###InternalSwitchboarD	use Log::Shiras::Report::Test2Note;
use Log::Shiras::Switchboard;

my(
			$ella_peterson, 		$mary_printz,			$name_space_ref,
			$report_placeholder_1,	$report_placeholder_2,	$report_ref, 
			$add_ref_source, 		$add_ref_report,		$error_message,
			$print_message,			$connection,			$second_call,
			$printed_data,			$main_phone,			$test_class,
);

my  		@attributes = qw(
				reports				name_space_bounds	logging_levels		all_buffering
			);

my  		@switchboard_methods = qw(
				get_operator		get_reports			get_report			send_buffer_to_output
				remove_reports		get_name_space		has_log_levels		remove_name_space_bounds
				remove_log_levels	has_no_reports		import				get_operator
				master_talk			add_reports			get_log_levels		add_name_space_bounds	
				has_buffer			clear_buffer		stop_buffering		set_all_buffering
				start_buffering		add_log_levels
			);

note 'Log-Shiras easy questions';
ok			$name_space_ref = {
				main =>{
					UNBLOCK =>{
						report1	=> 'ELEVEN',
						report2	=> 'trace',
						run		=> 'warn',
						WARN	=> 'debug',
					},
					caller_test =>{
						UNBLOCK =>{
							report1	=> 'debug',
							run		=> 'fatal',
						}
					},
				},
				Check =>{
					Print =>{
						add_line =>{
							UNBLOCK =>{
								log_file => 'eleven',
							},
						},
					},
				},
###InternalSwitchboarD	UNBLOCK =>{ # All setting available for source filtering below are currently set to not report for passing
###InternalSwitchboarD		log_file => 'warn',
###InternalSwitchboarD	},
###InternalSwitchboarD	Log =>{
###InternalSwitchboarD		Shiras =>{
###InternalSwitchboarD			Switchboard =>{
###InternalSwitchboarD				get_operator =>{
###InternalSwitchboarD					UNBLOCK =>{
###InternalSwitchboarD						log_file => 'info',
###InternalSwitchboarD					},
###InternalSwitchboarD				},
###InternalSwitchboarD				get_caller =>{
###InternalSwitchboarD					UNBLOCK =>{
###InternalSwitchboarD						log_file => 'warn',
###InternalSwitchboarD					},
###InternalSwitchboarD				},
###InternalSwitchboarD				master_talk =>{
###InternalSwitchboarD					_add_meta_data =>{
###InternalSwitchboarD						UNBLOCK =>{
###InternalSwitchboarD							log_file => 'warn',
###InternalSwitchboarD						},
###InternalSwitchboarD					},
###InternalSwitchboarD					_can_communicate =>{
###InternalSwitchboarD						UNBLOCK =>{
###InternalSwitchboarD							log_file => 'warn',
###InternalSwitchboarD						},
###InternalSwitchboarD					},
###InternalSwitchboarD					_convert_level_name_to_number =>{
###InternalSwitchboarD						UNBLOCK =>{
###InternalSwitchboarD							log_file => 'warn',
###InternalSwitchboarD						},
###InternalSwitchboarD					},
###InternalSwitchboarD					_buffer_decision =>{
###InternalSwitchboarD						UNBLOCK =>{
###InternalSwitchboarD							log_file => 'trace',
###InternalSwitchboarD						},
###InternalSwitchboarD					},
#~ ###InternalSwitchboarD					_is_fatal =>{
#~ ###InternalSwitchboarD						UNBLOCK =>{
#~ ###InternalSwitchboarD							log_file => 'trace',
#~ ###InternalSwitchboarD						},
#~ ###InternalSwitchboarD					},
###InternalSwitchboarD				},
###InternalSwitchboarD			},
###InternalSwitchboarD		},
###InternalSwitchboarD	},
			},							"Build initial sources for testing";
ok			$report_placeholder_1 = Check::Print->new, 		
										"Build a report stub";
ok			$report_placeholder_2 = Check::Cluck->new,
										"Build a second report stub";
ok 			$report_ref = {
				run	=> [], # Sending empty reports since it is not tested here
###InternalSwitchboarD	log_file =>[ Log::Shiras::Report::Test2Note->new ],
			},							"Build initial reports for testing";
ok( lives{
			$ella_peterson = Log::Shiras::Switchboard->get_operator(
				name_space_bounds => $name_space_ref,
				reports	=> 	$report_ref,
			)
	},									"Get a switchboard operator (with settings)")
										or note($@);
map{
has_attribute_ok
			$ella_peterson, $_,			"Check that the new instance has the -$_- attribute",
}			@attributes;
map{									#Check that the new instance can use all methods
can_ok		$ella_peterson, $_,
}			@switchboard_methods;

note 'Log-Shiras-Switchboard harder questions';
is			$ella_peterson->get_name_space, $name_space_ref,			
										"Check that the sources were loaded to this instance";
is			$ella_peterson->get_reports, $report_ref,			
										"Check that the reports were loaded to this instance";
ok(	lives{ 	$mary_printz = Log::Shiras::Switchboard->get_operator },
										"Start a concurrent instance of Log::Shiras with no input" ) or note($@);
is			$mary_printz->get_name_space, $name_space_ref,			
										"Check that the sources are available to the copy of the instance";
is			$mary_printz->get_reports, $report_ref,			
										"Check that the reports are available to the copy of the instance";
ok  		$add_ref_source = { 
				second_life =>{
					dancer=>{
						UNBLOCK =>{
							run => 'info',
						},
					}
				}
			},							"Build an add_ref for testing source changes";
ok  		$name_space_ref->{second_life} = {
				dancer=>{
					UNBLOCK =>{
						run => 'info',
					},
				},
			},							"Update the master source variable for testing";
ok( lives{ 	$ella_peterson->add_name_space_bounds( $add_ref_source ) },
										"Add a source to the second instance" ) or note($@);
is		 	$mary_printz->get_name_space, $name_space_ref,	
										"Check that the new source is combined with the old source";
ok			$add_ref_report = {
				run => [ $report_placeholder_1, $report_placeholder_2 ],
###InternalSwitchboarD	log_file =>[ Log::Shiras::Report::Test2Note->new ],
			},							"Build an add_ref for testing report changes";
ok( lives{ 	$mary_printz->add_reports( $add_ref_report ) },
										"Add a report to the second instance" ) or note($@);
is		 	$ella_peterson->get_reports(), $add_ref_report,
										"Check that the new report element is available (along with the old one) in the other instance", 
											Dumper( $ella_peterson->get_reports() ), Dumper( $add_ref_report );
ok  		delete $name_space_ref->{second_life},	
										"Update the master source variable (by removing a section) for testing";
ok( lives{	$ella_peterson->remove_name_space_bounds( {	second_life =>{} }  ) },
										"Try to remove the second instance source through the first instance" ) or note($@);
is			$mary_printz->get_name_space, $name_space_ref,
										"Check that the second instance source was affected";
ok( lives{ 	$ella_peterson->remove_reports( 'run', ) },
										"Try to remove the shared report instance source through the first instance" ) or note($@);
ok			delete $report_ref->{run},	"Update (remove an element) the report ref for testing";
is			$mary_printz->get_reports, $report_ref,
										"Check that the second instance sources were not affected in the global variable";
ok			!($mary_printz = undef),	"Clear the Mary Printz handle on the singleton to test re-setup";
ok( lives{
			$mary_printz = Log::Shiras::Switchboard->get_operator(
				name_space_bounds =>{ 
					test_sub =>{ 
						UNBLOCK =>{
							run => 'debug',
						},
					},
					Log =>{
						UNBLOCK =>{
							log_file => 'warn',
						},
					},
					Log =>{
						Shiras =>{
							Switchboard =>{
								_attempt_to_report =>{
									UNBLOCK =>{
										log_file => 'trace',
									},
								},
							},
							Telephone =>{
								talk =>{
									UNBLOCK =>{
										log_file => 'trace',
									},
								},
							},
						},
					},
				},
				reports	=> 	{ # Sending empty reports since they are not tested here
					report1 => [],
					report2 => [],
					run	=> [],
###InternalSwitchboarD	log_file => [ Log::Shiras::Report::Test2Note->new, ],
				},
				all_buffering =>{ 'report2' =>[] },
			);
},										"Set Mary Printz back up with some data to ensure that it works" ) or note($@);
ok( lives{
			$mary_printz->add_log_levels(
				report1 => [ qw( special all  ) ],
			);
},										"Test adding log levels to another report name" ) or note($@);
is			$ella_peterson->get_log_levels( 'report1' ), [ 'special', 'all' ],
										"... and test that the data loaded correctly";
ok( lives{
			$mary_printz->remove_log_levels( 'report1' );
},										"Test removing the same custom levels" ) or note($@);
is			$ella_peterson->get_log_levels( 'report1' ),
			[ 'trace', 'debug', 'info', 'warn', 'error', 'fatal', undef, undef, undef, undef, undef, 'eleven', ],
										"... and test that the levels are back to the default";
is 			$Log::Shiras::Test2::last_buffer_position, undef,
										"Check that the Test::Log::Shiras buffer is not active";
ok 			require Log::Shiras::Test2, "Load Test::Log::Shiras";
is 			$Log::Shiras::Test2::last_buffer_position, 11,
										"Check that the Test::Log::Shiras buffer is NOW active";
ok( lives{	$test_class = Log::Shiras::Test2->new },
										"Build a test class for reading messages from the bat phone" ) or note($@);;
ok( lives{
			$ella_peterson->master_talk({ # Use Ella Petersons bat phone
				name_space => 'main', report => 'report1', level => 'eleven', 
				message =>[ 'Hello World' ], });
},										"Test making a call (with Ella Petersons bat phone)" ) or note($@);
$test_class->match_message( 'report1', "Hello World",
										"... and check the output" );
ok( lives{
			$ella_peterson->master_talk({
				name_space => 'main', report => 'run', level => 'debug',
				message =>[ 'Hello World' ], });
},										"Test making a call with too low of a level" ) or note($@);
$test_class->cant_match_message( 'report1', 'Hello World',
										"... and check the output" );
like( dies{	$mary_printz->master_talk({
				name_space => 'main', report => 'run', level => 'fatal',  }) },
				qr/Fatal call sent to the switchboard /,
										"Test calling fatal (from Mary Printz's bat phone) and check that it has the right obituary" );
is 			$mary_printz->master_talk({ 
				 name_space => 'main::report1', report => 'report 1', level => 'fatal', }), -3,
										"Test calling fatal when it is OUT of the namespace to ensure it lives";
ok 			$mary_printz->start_buffering( report1 => 1, ),
										"Turn on buffering for 'report1'";
ok( lives{
			$mary_printz->master_talk({
				name_space => 'main', report => 'report1', level => 'eleven',
				message =>[ 'Hello World 11' ], }) },
										"Test making a (buffered) call" ) or note($@);
$test_class->cant_match_message( 'report1', 'Hello World 11',
										"... and check that the output was buffered" );
is			$mary_printz->send_buffer_to_output( 'report1' ), 0,# 0 since the report is empty
										"... then check sending the buffer to output";
$test_class->match_message( 'report1', "Hello World 11",
										"... and check the output" );
ok( lives{
			$ella_peterson->master_talk({
				name_space => 'main', report => 'report1', level => 'eleven', 
				message =>[ 'Hello World 10' ], });
},										"Test making another call" ) or note($@);
$test_class->cant_match_message( 'report1', 'Hello World 10',
										"... and check that the output was buffered" );
ok			$mary_printz->clear_buffer( 'report1' ),
										'Clear the buffer';
is			$mary_printz->send_buffer_to_output( 'report1' ), 0,
										"...flush the buffer";
$test_class->cant_match_message( 'report1', "Hello World 10",
										"... and check the output for a failed match" );
$test_class->buffer_count( 'report1', 0,
										"... then check there is nothing left in the buffer" );
ok( lives{
			$ella_peterson->master_talk({
				name_space => 'main', report => 'report2', level => 'eleven', 
				message =>[ 'Hello World 12' ], });
},										"Test making a call to an init buffer" ) or note($@);
$test_class->cant_match_message( 'report2', 'Hello World 12',
										"... and check that the output was buffered" );
is			$mary_printz->send_buffer_to_output( 'report2' ), 0, # Flush returns 0 actions since there are no report elements in the list
										"...flush the buffer";
$test_class->match_message( 'report2', "Hello World 12",
										"... and check the output" );
ok			$mary_printz->stop_buffering( 'report2' ),
										"Turn the buffer off for report2";
ok( lives{
			$ella_peterson->master_talk({
				name_space => 'main', report => 'report2', level => 'eleven', 
				message =>[ 'Hello World 13' ], });
},										"Test making a call to a stopped buffer" ) or note($@);
$test_class->match_message( 'report2', "Hello World 13",
										"... and check the output made it out" );
ok			$mary_printz->start_buffering( 'report2' ),
										"Turn the buffer back on for report2";
ok( lives{
			$ella_peterson->master_talk({
				name_space => 'main', report => 'report2', level => 'eleven', 
				message =>[ 'Hello World 14' ], });
},										"Test making a call to the restarted buffer" ) or note($@);
$test_class->cant_match_message( 'report2', 'Hello World 14',
										"... and check that the output was buffered" );
ok( lives{
			$ella_peterson = Log::Shiras::Switchboard->get_operator(
				all_buffering => {},
			)
	},									"Reset Ella Peterson as a switchboard operator (with no buffers)");
$test_class->match_message( 'report2', "Hello World 14",
										"... and check the buffer was sent to output" );
ok( lives{
			$ella_peterson->master_talk({
				name_space => 'main', report => 'report2', level => 'eleven', 
				message =>[ 'Hello World 15' ], });
},										"Test making a call to a report with no buffer" ) or note($@);
$test_class->match_message( 'report2', "Hello World 15",
										"... and check the output made it out" );
note									"... Test Done";
done_testing;
#~ Test clearing a buffer from an attribute setting in get_operator, stop_buffering, and send a message afterward (report2?)
package Check::Cluck;
sub new{
	bless {}, __PACKAGE__;
}
sub add_line{ ## Nothing happens here!
}

package Check::Print;
sub new{
	bless {}, __PACKAGE__;
}
sub add_line{ ## Nothing happens here!
}