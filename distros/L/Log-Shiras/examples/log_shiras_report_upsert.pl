use lib '../lib';
use Modern::Perl;
use Log::Shiras::Unhide qw( :InternalReportPostgreS :InternalReporTUpserT );
use Log::Shiras::Switchboard;
use Log::Shiras::Telephone;
use Log::Shiras::Report;
use Log::Shiras::Report::PostgreSQL;
use Log::Shiras::Report::Upsert;
use Log::Shiras::Report::Stdout;
$ENV{hide_warn} = 1;
$| = 1;
my	$operator = Log::Shiras::Switchboard->get_operator(
		name_space_bounds =>{
			UNBLOCK =>{
				to_db => 'info',# for info and more urgent messages
###InternalReportPostgreS	log_file => 'trace',# for info and more urgent messages
			},
		},
		reports =>{
###InternalReportPostgreS	log_file =>[{
###InternalReportPostgreS		superclasses =>[ 'Log::Shiras::Report::Stdout' ],
###InternalReportPostgreS		roles =>[ 'Log::Shiras::Report' ],
###InternalReportPostgreS	}],
		}
	);
	$operator->add_reports(# Added later to ensure the switchboard is turned on
		to_db =>[{
			package => 'PostgreSQL::TableLoader',
			superclasses =>[ 'Log::Shiras::Report::PostgreSQL' ],
			add_roles_in_sequence =>[ 
				'Log::Shiras::Report::Upsert',
				'Log::Shiras::Report' 
			],# additional line and class checking
			table_name => 'test_table',
			# connection_file => '../../postgresql_db_settings.jsn',# Not included in the package
			# for my PostgreSQL installation the file looks something like this (all must be one line)
			# ["dbi:Pg:database=MyDataBase;host=localhost;port=5432","power_user","cool_password", .
			# {"RaiseError":1,"AutoCommit":1,"PrintError":1,"LongReadLen":65000,"LongTruncOk":0}]
			merge_rules => 'merge_rules.json',
			merge_modify => { 
			
		}],
	);
my	$telephone = Log::Shiras::Telephone->new( report => 'to_db' );
	$telephone->talk( level => 'info', message => 'A new line' );
	$telephone->talk( level => 'trace', message => 'A second line' );
	$telephone->talk( level => 'warn', message =>[ {
		header_0 => 'A third line',
		new_header => 'new header starts here' } ] );