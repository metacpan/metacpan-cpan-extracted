#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use JSON;

my $perl = $^X;

my $root   = dirname(__FILE__)."/..";
my $script = "$root/example/02-request.pl";
-f $script or die "Failed to find $script, possibly renamed";

$ENV{PERL5LIB} = $ENV{PERL5LIB} ? "$root/lib:$ENV{PERL5LIB}" : "$root/lib";
$ENV{DOCUMENT_ROOT}="/usr/fake/noexist/htdocs";
$ENV{GATEWAY_INTERFACE}="CGI/1.1";
$ENV{HTTP_ACCEPT}="text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8";
$ENV{HTTP_ACCEPT_CHARSET}="ISO-8859-1,utf-8;q=0.7,*;q=0.7";
$ENV{HTTP_ACCEPT_ENCODING}="gzip, deflate";
$ENV{HTTP_ACCEPT_LANGUAGE}="en-us,en;q=0.5";
$ENV{HTTP_CONNECTION}="keep-alive";
$ENV{HTTP_HOST}="example.com";
$ENV{HTTP_USER_AGENT}="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:5.0) Gecko/20100101 Firefox/5.0";
$ENV{PATH_INFO}="/02/request/and/beyond";
$ENV{QUERY_STRING}="as_json=1";
$ENV{REMOTE_ADDR}="127.0.0.1";
$ENV{REMOTE_PORT}="63555";
$ENV{REQUEST_METHOD}="GET";
$ENV{REQUEST_URI}="$ENV{PATH_INFO}?$ENV{QUERY_STRING}";
$ENV{SCRIPT_FILENAME}=$script;
$ENV{SCRIPT_NAME}="/02/request";

my $pid = open (my $fd, "-|", $perl, $script)
    or die "Failed to read from '$perl $script': $!";

local $/;
my ($rawhead, $content) = split /\s*\n\s*\n/s, <$fd>, 2;

note "HEADER";
note $rawhead;

like $rawhead, qr/^Status: 200\s/s, "Status = 200";
like $rawhead, qr/Content-Type: application\/json/, "Content type present";

my %head = split /:\s*|\s*\n/, $rawhead;

is $head{'Content-Length'}, length $content, "Content length didn't lie";

note "CONTENT";
note $content;

my $ref = eval { decode_json( $content ) };
is ref $ref, 'HASH', "Json hash returned";

is $ref->{method}, "GET", "Method detected";

done_testing;
