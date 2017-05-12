#! /usr/bin/perl -w

use strict;
use IO::Socket::INET;

my $cl = IO::Socket::INET->new( 
    Proto	=> 'tcp',
    PeerAddr	=> 'localhost',
    PeerPort	=> 9000,
);

print $cl "hello!\n";
print {$cl} <>;
print $cl "quit\n";
