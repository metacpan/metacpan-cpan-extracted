#!/usr/bin/perl
use FCGI;

my %env;
my $req = FCGI::Request(\*STDIN, \*STDOUT, \*STDOUT, \%env, 0, &FCGI::FAIL_ACCEPT_ON_INTR);
while ($req->Accept() >= 0) {
    print("Content−type: text/html\r\n\r\nhello");
}
