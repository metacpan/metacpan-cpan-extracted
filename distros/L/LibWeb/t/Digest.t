# -*- perl -*-

# $Id: Digest.t,v 1.3 2000/07/08 14:38:45 ckyc Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use lib '..','../blib/lib','../blib/arch';

# Test to see if dependencies have been installed.
eval "use Digest";
if ($@) {
    warn "Digest modules not installed.\n";
    print "1..0\n";
    exit;
}

print "1..6\n";

# Set up a CGI environment
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{QUERY_STRING}    = 'game=chess&game=checkers&weather=dull';
$ENV{PATH_INFO}       = '/somewhere/else';
$ENV{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}     = '/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT}     = 8080;
$ENV{SERVER_NAME}     = 'the.good.ship.lollypop.com';
$ENV{REQUEST_URI}     = "$ENV{SCRIPT_NAME}$ENV{PATH_INFO}?$ENV{QUERY_STRING}";
$ENV{HTTP_LOVE}       = 'true';
$ENV{DOCUMENT_ROOT}   = '/home/puffy/public_html';
$ENV{HTTP_HOST}       = 'www.puffy.dom';

# rc
my $rc =  './eg/dot_lwrc';

# Subroutines.
sub test {
    local($^W) = 0;
    my($num, $true, $msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

# test_LibWeb_Digest
eval "use LibWeb::Digest";
test(1, !$@, "Could not load LibWeb::Digest module.  $@");

my $digest;
eval { $digest = LibWeb::Digest->new(); };
test(2, !$@, "LibWeb::Digest could not be instantiated.  $@");

if ($digest) {
    my $digest_algo = 'Digest::SHA1';
    my $is_generate_mac_pos_ok;
    eval { $is_generate_mac_pos_ok = $digest->generate_MAC(
							   -data => 'hello world',
							   -key => '1234abcd',
							   -algorithm => $digest_algo,
							   -format => 'b64'
							  )
	     eq $digest->generate_MAC(
				      -data => 'hello world',
				      -key => '1234abcd',
				      -algorithm => $digest_algo,
				      -format => 'b64'
				     );
       };
    test(3, $is_generate_mac_pos_ok, 'LibWeb::Digest::generate_MAC positively failed.');
    
    my $is_generate_mac_neg_ok;
    eval { $is_generate_mac_neg_ok = $digest->generate_MAC(
							   -data => 'hello world',
							   -key => '1234abcd',
							   -algorithm => $digest_algo,
							   -format => 'b64'
							  )
	     ne $digest->generate_MAC(
				      -data => 'hello world',
				      -key => '1234abce',
				      -algorithm => $digest_algo,
				      -format => 'b64'
				     );
       };
    test(4, $is_generate_mac_neg_ok, 'LibWeb::Digest::generate_MAC negatively failed.');
    
    my $is_generate_digest_pos_ok;
    eval { $is_generate_digest_pos_ok = $digest->generate_digest(
								 -data => 'hello world',
								 -key => '1234abcd',
								 -algorithm => $digest_algo,
								 -format => 'b64'
								)
	     eq $digest->generate_digest(
					 -data => 'hello world',
					 -key => '1234abcd',
					 -algorithm => $digest_algo,
					 -format => 'b64'
					);
       };
    test(5, $is_generate_digest_pos_ok, 'LibWeb::Digest::generate_digest positively failed.');
    
    my $is_generate_digest_neg_ok;
    eval { $is_generate_digest_neg_ok = $digest->generate_digest(
								 -data => 'hello world',
								 -key => '1234abcd',
								 -algorithm => $digest_algo,
								 -format => 'b64'
								)
	     ne $digest->generate_digest(
					 -data => 'hello world',
					 -key => '1234abce',
					 -algorithm => $digest_algo,
					 -format => 'b64'
					);
       };
    test(6, $is_generate_digest_neg_ok, 'LibWeb::Digest::generate_digest negatively failed.');
}


