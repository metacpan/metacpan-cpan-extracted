# test if all core modules can be loaded

use strict;
use warnings;

use Test::More tests => 24;

#list generated using:
# find -type f -iname "*pm" | perl -ne '$line = $_; $line = substr($line, 2, length($line)-6); $line =~ s/\//::/g; print "use_ok(\"$line\");\n"' | sort

BEGIN {
	use_ok("Konstrukt");
	use_ok("Konstrukt::Attributes");
	use_ok("Konstrukt::Cache");
	use_ok("Konstrukt::DBI");
	use_ok("Konstrukt::Debug");
	use_ok("Konstrukt::Event");
	use_ok("Konstrukt::File");
	use_ok("Konstrukt::Handler");
	
    SKIP: {
        eval {
			require Apache::Constants;
			require Apache::Cookie;
        };

        skip "Apache::Constants and/or Apache::Cookie not installed but needed to test for mod_perl", 1 if $@;
        
		$ENV{MOD_PERL} = 1;
		use_ok("Konstrukt::Handler::Apache");
    }
	
    SKIP: {
        eval {
			require Apache2::RequestRec;
			require Apache2::RequestIO;
			require Apache2::RequestUtil;
			require Apache2::Const;
			require Apache2::Cookie;
        };

        skip "At least one of Apache2::RequestRec, Apache2::RequestIO, Apache2::RequestUtil, Apache2::Const or Apache2::Cookie not installed but needed to test for mod_perl 2", 1 if $@;
        
		$ENV{MOD_PERL} = 2;
		$ENV{MOD_PERL_API_VERSION} = 2;
		use_ok("Konstrukt::Handler::Apache");
    }
    
	use_ok("Konstrukt::Handler::CGI");
	use_ok("Konstrukt::Handler::File");
#	use_ok("Konstrukt::Handler::Test");
	use_ok("Konstrukt::Lib");
	use_ok("Konstrukt::Parser");
	use_ok("Konstrukt::Parser::Node");
	use_ok("Konstrukt::Plugin");
	use_ok("Konstrukt::PrintRedirector");
	use_ok("Konstrukt::Request");
	use_ok("Konstrukt::Response");
	use_ok("Konstrukt::Session");
	use_ok("Konstrukt::Settings");
	use_ok("Konstrukt::SimplePlugin");
	use_ok("Konstrukt::TagHandler");
	use_ok("Konstrukt::TagHandler::Plugin");
}
