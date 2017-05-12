use ExtUtils::MakeMaker;

# It is clear that the version numbers given here are not the whole
# story.  Corrections are definitely appreciated.

WriteMakefile( NAME => "Link_Controller",
               VERSION_FROM => "lib/WWW/Link_Controller/Version.pm",
               dist => { COMPRESS => "gzip",
			 SUFFIX => "gz" },
	       #prerequisites levels have not generally been checked.
	       PREREQ_PM =>
	       {
		Carp => 0,
		CDB_File::BiIndex => 0.030,
		CDB_File::BiIndex::Generator => 0.30,
		CGI::Carp => 1.09,
		CGI::Request => 2.0,
		CGI::Response => 0,
		Cwd => 0,
		Data::Dumper => 0,
		DB_File => 0,
		English => 0,
		Exporter => 0,
		Fcntl => 0,
		File::Copy => 0,
		File::Find => 0,
		File::Path => 0,
		Getopt::Function => 0.017,
		HTML::LinkExtor => 0,
		HTML::Stream => 0,
		HTML::Tagset => 0,
		HTTP::Date => 0,
		HTTP::Status => 0,
		LWP::Debug => 0,
		LWP::MediaTypes => 0,
		LWP::RobotUA => 0,
		LWP::UserAgent => 0,
		MLDBM => 0,
		Schedule::SoftTime => 0.030,
		Search::Binary => 0,
		Sys::Hostname => 0,
		URI => 0,
		WWW::Link => 0.034,
		WWW::Link::Repair => 0,
		WWW::Link::Repair::Substitutor => 0,
		WWW::Link::Reporter::Compile => 0,
		WWW::Link::Reporter::HTML => 0,
		WWW::Link::Reporter::LongList => 0,
		WWW::Link::Reporter::RepairForm => 0,
		WWW::Link::Reporter::Text => 0,
		WWW::Link::Selector => 0,
		WWW::Link::Tester::Adaptive => 0,
		WWW::RobotRules::AnyDBM_File => 0,
	       },
	     );



