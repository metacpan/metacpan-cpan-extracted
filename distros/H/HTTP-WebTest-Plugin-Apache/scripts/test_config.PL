#!/usr/bin/perl -w

# $Id: test_config.PL,v 1.1.1.1 2002/11/15 21:47:13 m_ilya Exp $

use strict;

use Data::Dumper;

my %CONFIG;

unless(check_config()) {
    # verify standard input and output are attached to a terminal
    if(-t STDIN and -t STDOUT) {
	$CONFIG{APACHE_EXEC} = apache_exec_setup();
    }

    print "\n";

    write_config();
}

# checks if config file exists
sub check_config {
    return(-f '.config');
}

# dumps config params hash
sub write_config {
    local *FILE;
    open FILE, '> .config' or die "Can't write to file '.config': $!";

    print FILE Data::Dumper->Dump([\%CONFIG], [qw(*CONFIG)]);

    close FILE;
}


# finds where apache binary is located
sub apache_exec_setup {
    my $apache_exec = undef;

    # verify that we don't run on Win32 system. Local web files
    # test mode is not supported on that platform
    if($^O ne 'MSWin32') {
	while(1) {
	    print_prompt(<<TEXT);

HTTP-WebTest automated test suite contains tests for local web files
test mode. Running these tests requires Apache web server. If you do
not have Apache you can skip these tests.

Run local web files test mode tests during 'make test'? [Y/n]:
TEXT

	    my $response = <STDIN>;
	    chomp($response);
	    if($response =~ /^(?:y(?:es)?|)$/i) {
		# user asked to run tests
		$apache_exec = $ENV{'APACHE'} || which('apache') ||
		               which('httpd') || '/usr/lib/httpd/httpd';

		print_prompt(<<TEXT);

Please enter filename of Apache executable file.

Filename? [$apache_exec]:
TEXT

		my $response = <STDIN>;
		chomp($response);
		$apache_exec = $response if $response;
		last if -x $apache_exec;
		print STDOUT <<TEXT;

ERROR: $apache_exec is not a valid executable file
TEXT
	    } else {
		last;
	    }
	}
    }

    return $apache_exec;
}

# finds executable in PATH (code is stolen from Apache::test)
sub which {
    foreach (map { "$_/$_[0]" } split /:/, $ENV{PATH}) {
        next unless m,^/,;
        return $_ if -x;
    }
}

sub print_prompt {
    my $text = shift;
    chomp $text;
    print STDOUT $text, ' ';
}
