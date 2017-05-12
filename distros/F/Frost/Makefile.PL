use 5.008008;
use ExtUtils::MakeMaker;
#	See lib/ExtUtils/MakeMaker.pm for details of how to influence
#	the contents of the Makefile that is written.
WriteMakefile
(
	NAME					=> 'Frost',
	VERSION_FROM		=> 'lib/Frost.pm',	#	finds $VERSION
	ABSTRACT_FROM		=> 'lib/Frost.pm',		#	retrieve abstract from module
	AUTHOR				=> 'Ernesto <ernesto@dienstleistung-kultur.de>',
	LICENSE				=> 'perl',
	PREREQ_PM			=>
	{
		'Carp'									=> 1.04,
		'Class::MOP'							=> 1.08,
		'Data::Dumper'							=> 1.125,
		'Data::UUID'							=> 1.202,
#		'DB_File'								=> 1.820,
		'BerkeleyDB'							=> 0.43,
		'Exporter'								=> 0,
		'Fcntl'									=> 1.05,
		'File::Path'							=> 2.04,
		'IO::File'								=> 0,
		'Log::Log4perl'						=> 1.24,
		'Moose'									=> 1.14,
		'Scalar::Util'							=> 0,
		'Storable'								=> 2.21,
		'Tie::Cache::LRU'						=> 20081023.2116,
		'Time::HiRes'							=> 1.9719,
	#	test only:
		'DateTime::Format::MySQL'			=> 0,
		'List::Util'							=> 0,
		'List::MoreUtils'						=> 0,
		'Test::Deep'							=> 0,
		'Test::Differences'					=> 0,
		'Test::Exception'						=> 0,
		'Test::More'							=> 0.88,		#	done_testing...
		'Test::Requires'						=> 0,
	#	checked in test -> skip:
	#	'Devel::Size'							=> 0.71,
	#	'Sys::MemInfo'							=> 0.91,
	#	'Declare::Constraints::Simple'	=> 0,
	#	'Regexp::Common'						=> 0,
	#	'Locale::US'							=> 0,
	},	#	e.g., Module::Name => 1.1
	test					=> { TESTS => 't/*/*.t', },
#	PL_FILES				=> {'check_db.PL' => 'check_db'},
);

