use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'HTTPD::ADS',
      license         => 'gpl',
      requires => {
	Class::DBI =>'0.94',
	Class::DBI::AbstractSearch =>'0.03',
	  CLASS =>'0.91',
	  CGI::Carp =>'1.26',
	  IO::Socket::UNIX =>'1.20',
	  Date::Calc =>'5.3',
	  Class::Accessor =>'0.18',
	  Class::Constructor =>'1.1.3',
	  Class::DBI::Pg =>'0.03',
	Net::IP::Route::Reject =>'0.3',
	HTTPD::Log::Filter =>'1.07',
	Compress::Zlib =>'1.22',
	IO::Zlib =>'1.01',
	IPC::Cmd =>'0.04',
	DBD::Pg => '1.31',
	HTTP::Date =>'1.46'
	},
      script_files =>[ "scripts/DefenseServer.pl","scripts/LogReader.pl","scripts/LogTailer.pl"],
create_makefile_pl => 'passthrough',
      sign =>1
    )->create_build_script;
