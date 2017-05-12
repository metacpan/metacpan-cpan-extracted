# -*- perl -*-

# $Id: Class.t,v 1.5 2000/07/08 14:38:45 ckyc Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use lib '..','../blib/lib','../blib/arch';

BEGIN {$| = 1; print "1..2\n"; $^W = 1; }
END {print "not ok 1\n" unless $loaded;}
$loaded = 1;
print "ok 1\n";


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

# test_LibWeb_Database
eval "use LibWeb::Class";
test(2, !$@, "Could not load LibWeb::Class module.  $@");
