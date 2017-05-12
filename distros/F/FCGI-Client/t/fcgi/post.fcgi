#!/usr/bin/env perl
use FCGI;

my $req = FCGI::Request();
while ($req->Accept() >= 0) {
    my $line = <STDIN>;
    print("Content−type: text/html\r\n\r\nhello: $line");
}

