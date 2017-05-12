#!perl
#########1 Initial Test File for Log::Shiras::Telephone     6#########7#########8#########9
my ( $lib, $test_file );
BEGIN{
	use Modern::Perl;
	use Test2::Bundle::Extended qw( !meta );
	use Test2::Plugin::UTF8;
	use Test::Moose;
	plan( 35 );
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
	$ENV{hide_warn_for_test} = 1;
}
$| = 1;
use Data::Dumper;
use lib $lib,;
use Log::Shiras::Unhide qw( :InternalSwitchboarD );
use Log::Shiras::Report::Test2Note;
use Log::Shiras::Switchboard;
use Log::Shiras::Telephone;
use Log::Shiras::Test2;
use Log::Shiras::Report::Test2Note;
my(
			$ella_peterson, 		$name_space_ref,		$report_ref,
			$test_class,			$main_phone,	
);	

my  		@attributes = qw(
				fail_over			name_space			report				level
				message				carp_stack			
			);

my  		@telephone_methods = qw(
				talk				set_name_space		get_name_space		set_report
				get_report			set_level			get_level			set_shared_message
				get_shared_message	set_fail_over		should_fail_over	set_carp_stack
				should_carp_longmess	
			);
			
note 									'Log::Shiras::Telephone easy questions';
ok			$name_space_ref = {
				main =>{
					UNBLOCK =>{
						report1	=> 'ELEVEN',
						report2	=> 'trace',
						run		=> 'warn',
						WARN	=> 'debug',
						log_file => 'fatal',
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
				Log =>{
					Shiras =>{
						Switchboard =>{
###InternalSwitchboarD		get_operator =>{
###InternalSwitchboarD			UNBLOCK =>{
###InternalSwitchboarD				log_file => 'info',
###InternalSwitchboarD			},
###InternalSwitchboarD		},
							master_talk =>{
								_can_communicate =>{
									UNBLOCK =>{
										log_file => 'info',
									},
								},
###InternalSwitchboarD			_add_caller =>{
###InternalSwitchboarD				UNBLOCK =>{
###InternalSwitchboarD					log_file => 'warn',
###InternalSwitchboarD				},
###InternalSwitchboarD			},
###InternalSwitchboarD			_add_carp_stack =>{
###InternalSwitchboarD				UNBLOCK =>{
###InternalSwitchboarD					log_file => 'trace',
###InternalSwitchboarD				},
###InternalSwitchboarD			},
							},
						},
###InternalTelephonE	Telephone =>{
###InternalTelephonE		talk =>{
###InternalTelephonE			UNBLOCK =>{
###InternalTelephonE				log_file => 'warn',
###InternalTelephonE			},
###InternalTelephonE		},
###InternalTelephonE	},
					},
				},
			},							"Build initial sources for testing";
ok 			$report_ref = {
				run	=> [], # Sending empty reports since it is not tested here
				#~ log_file =>[ Log::Shiras::Report::Test2Note->new ], #Raise visibility to the actions being tested
				#~ report1 =>[ Log::Shiras::Report::Test2Note->new ], #Raise visibility to the actions being tested
				log_file =>[Log::Shiras::Report::Test2Note->new],
			},							"Build initial reports for testing";
ok( lives{
			$ella_peterson = Log::Shiras::Switchboard->get_operator(
				name_space_bounds => $name_space_ref,
				reports	=> 	$report_ref,
			)
	},									"Get a switchboard operator (with settings)")
										or note($@);
ok		$test_class = Log::Shiras::Test2->new( test_buffer_size => 20 ),
										"Build a test class to test the Switchboard activity with max buffer at 20";

note									"Log::Shiras::Telephone Easy tests";
ok 			$main_phone = Log::Shiras::Telephone->new(),
										"Test getting a telephone";
map{
has_attribute_ok
			$main_phone, $_,			"Check that the new instance has the -$_- attribute",
}			@attributes;
map{									#Check that all exported methods are available
can_ok		$main_phone, $_,
}			@telephone_methods;

note									'Log::Shiras::Telephone harder methods';
ok( lives{	$main_phone->talk( 'Hello World 0' ) },
										"Test making a simple call")
										or note($@);
$test_class->match_message( 'log_file', "Hello World 0",
										"... and check the output" );
ok( lives{	$main_phone->talk( carp_stack => 1, report => 'report1', level => 'eleven', message =>[ 'Hello World 1' ], ) },
										"Test making a call with more detail definition of call handling")
										or note($@);
$test_class->set_match_retention( 1 );
$test_class->match_message( 'report1', qr/Hello World 1/,
										"... and check the output" );
$test_class->set_match_retention( 0 );
$test_class->match_message( 'report1', qr/Log::Shiras::Telephone::talk\(.{0,2}Log::Shiras::Telephone=HASH\(0x.{4,20}\).{0,2}, .{1,2}carp_stack.{1,2}, 1, .{1,2}report.{1,2}, .{1,2}report1.{1,2}, .{1,2}level.{1,2}, .{1,2}eleven.{1,2}, .{1,2}message.{1,2},/,
										"... Also check for some longmess called in the details of the message" );
ok( lives{	$main_phone->talk( report => 'run', level => 'debug', message =>[ 'Hello World 2' ], ) },
										"Test making a call with too low of a level")
										or note($@);
$test_class->cant_match_message( 'run', "Hello World 2",
										"... and check that there was no output" );
$test_class->match_message( 'log_file', 'The destination -run- is UNBLOCKed but not to the -debug- level at the name space: main',
										"... then check for a blocked message report" );
like( dies{
			$main_phone->talk( report => 'run', level => 'fatal',  ) },
			qr/Fatal call sent to the switchboard /,
										"Test calling fatal from a Telephone (with the proper permissions) to ensure it dies");
ok 			$main_phone = Log::Shiras::Telephone->new( name_space => 'main::report1' ),
										"Test getting a telephone that falls inside an UNBLOCKed name space";
is 			$main_phone->talk( report => 'report 1', level => 'fatal', ), -3, # Message blocked return
										"Test calling fatal when it is OUT of the namespace to ensure it lives";
done_testing();