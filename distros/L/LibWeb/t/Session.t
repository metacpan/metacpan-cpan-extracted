# -*- perl -*-

# $Id: Session.t,v 1.5 2000/07/08 14:38:45 ckyc Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use lib '..','../blib/lib','../blib/arch';

eval "use Digest";
if ($@) {
    warn "Digest modules not installed.\n";
    print "1..0\n";
    exit;
}

eval "use Crypt::CBC";
if ($@) {
    warn "Crypt::CBC module not installed.\n";
    print "1..0\n";
    exit;
}

my $cipher_algo;
eval "use Crypt::IDEA"; $cipher_algo = 'Crypt::IDEA' if !$@;
eval "use Crypt::DES"; $cipher_algo = 'Crypt::DES' if !$@;
eval "use Crypt::Blowfish"; $cipher_algo = 'Crypt::Blowfish' if !$@;
unless ( defined $cipher_algo ) {
    warn "Crypt::Blowfish/Crypt::DES/Crypt::IDEA module not installed.\n";
    print "1..0\n";
    exit;
}

print "1..2\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

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

# test_LibWeb_Session
eval "use LibWeb::Session";
test(1, !$@, "Could not load LibWeb::Session module.  $@");

my $session;
eval { $session = LibWeb::Session->new( $rc ); };
test(2, !$@, "LibWeb::Session cannot be instantiated.  $@");
