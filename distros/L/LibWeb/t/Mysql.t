# -*- perl -*-

# $Id: Mysql.t,v 1.5 2000/07/08 14:38:45 ckyc Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use lib '..','../blib/lib','../blib/arch';

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

# Test to see if dependencies have been installed.
eval "use DBI";
if ($@) {
    warn "DBI not installed.\n";
    print "1..0\n";
    exit;
}

# test_LibWeb_Database_Mysql
print "1..1\n";

eval "use LibWeb::Database::Mysql";
test(1, !$@, "Could not load LibWeb::Database::Mysql module.  $@");
