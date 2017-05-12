#!/usr/bin/env perl
use FCGI;

my $req = FCGI::Request();
while ($req->Accept() >= 0) {
    my $read = read(STDIN, my $buf, $ENV{CONTENT_LENGTH}) or die $!;
    print STDERR "len: $read, $ENV{CONTENT_LENGTH}\n";
    print("Content−Type: $ENV{CONTENT_TYPE}\r\nContent-Length: $ENV{CONTENT_LENGTH}\r\n\r\n$buf");
}

