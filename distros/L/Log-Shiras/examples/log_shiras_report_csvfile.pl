use lib '../lib';
use Modern::Perl;
#~ use Log::Shiras::Unhide qw( :InternalReporTCSV );
use Log::Shiras::Switchboard;
use Log::Shiras::Telephone;
use Log::Shiras::Report;
use Log::Shiras::Report::CSVFile;
$ENV{hide_warn} = 1;
$| = 1;
my	$operator = Log::Shiras::Switchboard->get_operator(
		name_space_bounds =>{
			UNBLOCK =>{
				to_file => 'info',# for info and more urgent messages
			},
		},
		reports =>{
			to_file =>[{
				superclasses =>[ 'Log::Shiras::Report::CSVFile' ],
				roles =>[ 'Log::Shiras::Report' ],# Effectivly an early class type check
				file => 'test.csv',
			}],
		}
	);
my	$telephone = Log::Shiras::Telephone->new( report => 'to_file' );
	$telephone->talk( level => 'info', message => 'A new line' );
	$telephone->talk( level => 'trace', message => 'A second line' );
	$telephone->talk( level => 'warn', message =>[ {
		header_0 => 'A third line',
		new_header => 'new header starts here' } ] );