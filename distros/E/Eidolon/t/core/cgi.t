#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/core/cgi.t - CGI tests
#
# ==============================================================================  

use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More tests => 33;
use ETests_CGI;
use warnings;
use strict;

my ($cfg, $cgi, $e);

# ------------------------------------------------------------------------------
# BEGIN()
# test initialization
# ------------------------------------------------------------------------------
BEGIN
{
    use_ok("Eidolon::Core::Exceptions");
    use_ok("Eidolon::Core::Config");
    use_ok("Eidolon::Core::CGI");
}

# methods
ok( Eidolon::Core::CGI->can("decode_string"),   "decode_string method" );
ok( Eidolon::Core::CGI->can("get"),             "get method"           );
ok( Eidolon::Core::CGI->can("post"),            "post method"          );
ok( Eidolon::Core::CGI->can("get_query"),       "get_query method"     );
ok( Eidolon::Core::CGI->can("get_file"),        "get_file method"      );
ok( Eidolon::Core::CGI->can("receive_file"),    "receive_file method"  );
ok( Eidolon::Core::CGI->can("get_param"),       "get_param method"     );
ok( Eidolon::Core::CGI->can("get_cookie"),      "get_cookie"           );
ok( Eidolon::Core::CGI->can("set_cookie"),      "set_cookie"           );
ok( Eidolon::Core::CGI->can("generate_string"), "generate_string"      );
ok( Eidolon::Core::CGI->can("start_session"),   "start_session"        );
ok( Eidolon::Core::CGI->can("destroy_session"), "destroy_session"      );
ok( Eidolon::Core::CGI->can("session_started"), "session_started"      );
ok( Eidolon::Core::CGI->can("set_session"),     "set_session"          );
ok( Eidolon::Core::CGI->can("get_session"),     "get_session"          );
ok( Eidolon::Core::CGI->can("header_sent"),     "header_sent"          );
ok( Eidolon::Core::CGI->can("add_header"),      "add_header"           );
ok( Eidolon::Core::CGI->can("redirect"),        "redirect"             );
ok( Eidolon::Core::CGI->can("send_header"),     "send_header"          );

# GET request
$ENV{"QUERY_STRING"}   = "i=ve&got=a&poison=i&ve=got&a=remedy";
$ENV{"REQUEST_METHOD"} = "GET";

$cfg = Eidolon::Core::Config->new("CGI test", 0);
$cgi = Eidolon::Core::CGI->new;

is( $cgi->get("i"),       "ve", "GET parameters passing #1"                    );
is( $cgi->get("poison"),  "i",  "GET parameters passing #2"                    );
is( $cgi->get_param("i"), "ve", "GET parameters passing: (alternative syntax)" );

undef $cgi;

{
    no warnings;
    undef $Eidolon::Core::CGI::INSTANCE;
}

# POST request
$ENV{"QUERY_STRING"}   = "";
$ENV{"REQUEST_METHOD"} = "POST";
$ENV{"CONTENT_LENGTH"} = length($ETests_CGI::post);
$ENV{"CONTENT_TYPE"}   = "application/x-www-form-urlencoded";
tie *STDIN, "ETests_CGI";

$cgi = Eidolon::Core::CGI->new;

is( $cgi->post("i"),      "ve", "POST parameters passing #1"                   );
is( $cgi->post("poison"), "i",  "POST parameters passing #2"                   );
is( $cgi->get_param("i"), "ve", "POST parameters passing (alternative syntax)" );

undef $cgi;

{
    no warnings;
    undef $Eidolon::Core::CGI::INSTANCE;
}

# POST request (multipart/form-data)
$ENV{"QUERY_STRING"}   = "";
$ENV{"REQUEST_METHOD"} = "POST";
$ENV{"CONTENT_LENGTH"} = length($ETests_CGI::post_multipart);
$ENV{"CONTENT_TYPE"}   = "multipart/form-data; boundary=\"peoplecanfly\"";
tie *STDIN, "ETests_CGI";

$cgi = Eidolon::Core::CGI->new;

is
(
    $cgi->post("astral"),
    "projection",
    "POST parameters passing (multipart/form-data)"
);

is
(
    $cgi->get_file("text")->{"name"}, 
    "base_001.txt", 
    "POST file upload (filename)"
);

like
(
    $cgi->get_file("text")->{"tmp"}, 
    qr/^\/tmp/, 
    "POST file upload (temporary path)"
);

is
(
    $cgi->get_file("text")->{"ext"},   
    "txt",      
    "POST file upload (extension detection)"
);

is
(
    ${ $cgi->receive_file("text") },   
    "All your base are belong to us.", 
    "POST file upload (reading file contents)"
);

