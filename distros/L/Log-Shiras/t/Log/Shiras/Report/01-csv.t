#!perl
#########1 Test File for Log::Shiras::TapPrint    5#########6#########7#########8#########9
my ( $lib, $test_file, );
BEGIN{
	use Modern::Perl;
	use Test2::Bundle::Extended qw( !meta );
	use Test2::Plugin::UTF8;
	use Test::Moose;
	plan( 57 );
	my $file = (caller(0))[1];
	my 	$directory_ref = {
			t		=> './',# repo level
			Log		=> '../',# t folder level
			$file	=> '../../../../',# test file level
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
	$SIG{__DIE__} = sub{ diag longmess $_[0]; };
}
$| = 1;
use MooseX::ShortCut::BuildInstance qw( build_class );
use File::Copy qw( copy );
use File::Temp;
use Test::File;
use lib $lib,;
#~ use Log::Shiras::Unhide qw( :InternalReporTCSV );# :InternalSwitchboarD :InternalTaPWarN :InternalTypeSHeadeR
use Log::Shiras::Switchboard;
use Log::Shiras::Telephone;
use Log::Shiras::Report::CSVFile;
use	Log::Shiras::Report::Test2Diag;
use Log::Shiras::TapWarn;
my  		@attributes = qw(
				file					headers					reconcile_headers
				test_first_row			
			);
my  		@methods = qw(
				get_file_name			get_file_name			set_headers
				get_headers				has_headers				number_of_headers
				add_line				set_reconcile_headers	should_reconcile_headers
				should_test_first_row
			);
my  (
			$csv_class, $csv_instance, $ella_peterson, $name_space_ref, $report_ref,
			$temp_file,	$test_class,
	);
my( $file_name_1, $file_name_2 ) = ( 'MyCSV.csv', ($test_file . 'csv_header.csv'), );
my $temp_dir = File::Temp->newdir( CLEANUP => 1 );
note 									"easy question first ...";
ok			$name_space_ref = {
				UNBLOCK =>{
					log_file => 'trace',
				},
				Log =>{
					UNBLOCK =>{
						log_file => 'trace',
					},
					Shiras =>{
						#~ TapWarn =>{
							#~ UNBLOCK =>{
								#~ log_file => 'trace',
							#~ },
						#~ },
						#~ Report =>{
							#~ CSVFile =>{
								#~ add_line =>{
									#~ UNBLOCK =>{
										#~ log_file => 'trace',
									#~ },
									#~ _build_message_from_arrayref =>{
										#~ UNBLOCK =>{
											#~ log_file => 'trace',
										#~ },
									#~ },
									#~ _find_the_actual_message =>{
										#~ UNBLOCK =>{
											#~ log_file => 'warn',
										#~ },
									#~ },
								#~ },
								#~ _build_message_from_arrayref =>{
									#~ UNBLOCK =>{
										#~ log_file => 'trace',
									#~ },
								#~ },
								#~ _add_headers_to_file =>{
									#~ UNBLOCK =>{
										#~ log_file => 'warn',
									#~ },
								#~ },
							#~ },
						#~ },
###InternalSwitchboarD	Switchboard =>{
###InternalSwitchboarD		master_talk =>{
###InternalSwitchboarD			_really_report =>{
###InternalSwitchboarD				UNBLOCK =>{
###InternalSwitchboarD					log_file => 'trace',
###InternalSwitchboarD				},
###InternalSwitchboarD			},
###InternalSwitchboarD		},
###InternalSwitchboarD		add_name_space_bounds =>{
###InternalSwitchboarD			UNBLOCK =>{
###InternalSwitchboarD				log_file => 'trace',
###InternalSwitchboarD			},
###InternalSwitchboarD		},
###InternalSwitchboarD	},
					},
				},
			},							"Build initial sources for testing";
ok 			$report_ref = {
###InternalReporTCSV		log_file =>[ Log::Shiras::Report::Test2Diag->new ], #Raise visibility to the actions being tested
			},							"Build initial reports for testing";
ok( lives{
			$ella_peterson = Log::Shiras::Switchboard->get_operator(
				name_space_bounds => $name_space_ref,
				reports	=> 	$report_ref,
			)
	},									"Get a switchboard operator (with settings)")
										or diag($@);
ok( lives{	$csv_class = build_class(
				package => 'CSVFile::Class',
				superclasses => [ 'Log::Shiras::Report::CSVFile' ],
			);
	},									"Build a CSVFile class")
										or diag($@);
map{
has_attribute_ok
			$csv_class, $_,			"Check that the new instance has the -$_- attribute",
}			@attributes;
map{									#Check that all exported methods are available
can_ok		$csv_class, $_,
}			@methods;
ok( lives{	$csv_instance = $csv_class->new( file => $file_name_1 ) },
										"Build a CSVFile instance - and auto vivify the file")
										or diag($@);
ok				-f $file_name_1,		"Check that the file exists";
is				$csv_instance = undef, undef,
										"Close the CSVFile";
ok( lives{		unlink( $file_name_1 ) or die $! },
										"Delete the test CSVFile: $file_name_1")
										or diag($@);
ok( lives{	$temp_file = $temp_dir . '/csv_header.csv';
			copy( $file_name_2, $temp_file ); },
										"Copy the file to the temp directory: $temp_file")
										or diag($@);
ok( lives{	$csv_instance = 	$csv_class->new(
									file => $temp_file,
									headers =>[ 'my', 'header', 'test', 'Value Header' ],
								) },	"Build a CSVFile instance - with a pre-built file containing data")
										or diag($!);
is				$csv_instance->get_headers, ['my', 'header', 'test', 'value_header', ],
										"...and insure that the headers match the request not the file";
is				$csv_instance->set_headers( [ 'Some', 'Different Header', 'header' ], ),
				{ 0 => 4, 1 => 5, 2 => 1 },	"Add two new headers (and get the order translation ref back)";
is				$csv_instance->get_headers, ['my', 'header', 'test', 'value_header', 'some', 'different_header', ],
										"...and insure that they were added at the end of the file headers";
eval 'use Log::Shiras::Test2';
ok				$ella_peterson->add_name_space_bounds({ # Added here since the test class wasn't 'use'd until now
					UNBLOCK =>{
						warn_log => 'trace',
					},
				}),						"Add a warn_log name space to trigger test capture";
ok				re_route_warn( report => 'warn_log' ),
										"Re-route warn statements to check for emited warnings";
is				$csv_instance->add_line({ message => [qw( another line for the file )] }), 1,
										"...add an array ref (not a message ref) with-out a sufficient number of columns";
ok				$test_class = Log::Shiras::Test2->new( test_buffer_size => 20 ),
										"Build a test class to test the Switchboard activity with max buffer at 20";
$test_class->match_message( 'warn_log', qr/The first added row has -5- items - but the report expects -6- items/,
										"... and check for the correct error message with the test buffer" );
is				$csv_instance->add_line({ message => [qw( here is another test line )] }), 1,
										"...and add another line without a sufficient number of columns";
$test_class->cant_match_message( 'warn_log', qr/The added first row has -5- items - but the report expects -6- items/,
										"... and check that the error message didnt re-appear" );
is				$csv_instance = undef, undef,
										"Close the csv instance connected to a pre-built copied file";
file_line_count_is( $temp_file, 4,		"Check for the expected number of lines in the file");
ok( lives{	$temp_file = $temp_dir . '/empty_file.csv'; },
										"Build a new temp file name: $temp_file")
										or diag($@);
ok( lives{	$csv_instance = 	$csv_class->new(
									file => $temp_file,
									headers =>[ 'my', 'header', 'test', 'Value Header' ],
								) },	"Build a new CSVFile instance - with requested headers in an empty file: $temp_file")
										or diag($@);
is				$csv_instance->add_line( { message =>[{ my => 'here', header => 'is', test => 'another', new_header => 'test line' }] } ), 1,
										"Add a test line with an unmatched header a sufficient number of columns";
$test_class->match_message( 'warn_log', qr/Adding headers from the first hashref \( new_header \)/,
										"... and check for the correct error message with the test buffer" );
is				$csv_instance->add_line( { message =>[{ different_header => 'test line' }] } ), 1,
										"Add a test line with an unmatched header and nothing else";
$test_class->match_message( 'warn_log', qr/found a hash key in the message that doesn\'t match the expected header \( different_header \)/,
										"... and check for the correct error message with the test buffer" );
is				$csv_instance->add_line( { message =>[{ my => 'here', header => 'is', test => 'another', new_header => 'test line' }] } ), 1,
										"..add the first line again to see if an empty row is left";
is				$csv_instance = undef, undef,
										"Close the csv instance from the initially new and empty file";
file_line_count_is( $temp_file, 4,		"Check for the expected number of lines in the file");
ok( lives{	$temp_file = $temp_dir . '/another_file.csv'; },
										"Build a new temp file name: $temp_file")
										or diag($@);
ok( lives{	$csv_instance = 	$csv_class->new(
									file => $temp_file,
								) },	"Build a new CSVFile instance - with out headers: $temp_file")
										or diag($@);
is				$csv_instance->add_line( { message =>[qw( A new line in the file )] } ), 1,
										"Add a test line (via array ref) to a file with no headers";
$test_class->match_message( 'warn_log', qr/Setting dummy headers \( header_0, header_1, header_2, header_3, header_4, header_5 \)/,
										"... and check for the correct error message with the test buffer" );
is				$csv_instance = undef, undef,
										"Close the csv instance from the empty header file";
file_line_count_is( $temp_file, 2,		"Check for the expected number of lines in the file");
ok( lives{	$temp_file = $temp_dir . '/hashref_file.csv'; },
										"Build a new temp file name: $temp_file")
										or diag($@);
ok( lives{	$csv_instance = 	$csv_class->new(
									file => $temp_file,
								) },	"Build a new CSVFile instance - with out headers to add hashrefs: $temp_file")
										or diag($@);
is				$csv_instance->add_line( { message =>[{ header_1 => 'new', header_2 => 'row', header_3 => 'value' }] } ), 1,
										"Add a test line (via hash ref) to a file with no headers";
$test_class->match_message( 'warn_log', qr/Adding headers from the first hashref \( header_/,# All three not shown since hashrefs are order independant
										"... and check for the correct error message with the test buffer" );
is				$csv_instance = undef, undef,
										"Close the csv instance from the empty header file";
file_line_count_is( $temp_file, 2,		"Check for the expected number of lines in the file");
note								"... Test Done";
done_testing;