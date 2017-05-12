# -*- perl -*-

# $Id: ThemesD.t,v 1.5 2000/07/08 14:38:45 ckyc Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use lib '..','../blib/lib','../blib/arch';

BEGIN {$| = 1; print "1..8\n"; $^W = 1; }
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

# test_LibWeb_Themes_Default
eval "use LibWeb::Themes::Default";
test(2, !$@, "Could not load LibWeb::Themes::Default module.  $@");
my $theme;
eval { $theme = LibWeb::Themes::Default->new( $rc ); };
test(3, !$@, "LibWeb::Themes::Default cannot be instantiated.  $@");
my($bordered_table, $table, $titled_bordered_table, $titled_table,
   $titled_table_enlighted) =
  (
   $theme->bordered_table(), $theme->table(),
   $theme->titled_bordered_table(), $theme->titled_table(),
   $theme->titled_table_enlighted()
  );
test(4, $bordered_table, 'LibWeb::Themes::Default::bordered_table failed.');
test(5, $table, 'LibWeb::Themes::Default::table failed.');
test(6, $titled_bordered_table, 'LibWeb::Themes::Default::titled_bordered_table failed.');
test(7, $titled_table, 'LibWeb::Themes::Default::titled_table failed.');
test(8, $titled_table_enlighted, 'LibWeb::Themes::Default::titled_table_enlighted failed.');
