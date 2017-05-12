#!/usr/bin/env perl
use FCGI;

my $req = FCGI::Request();
while ($req->Accept() >= 0) {
    print STDERR "hello, stderr\n";
    print("Content−type: text/html\r\n\r\nhello\n$ENV{QUERY_STRING}");
}

