#!perl

use Test::More tests => 3;

use strict;
use warnings;

use IO::File;
use HTTP::Request;
use HTTP::Request::AsCGI;

my $r = HTTP::Request->new( POST => 'http://www.host.com/');
$r->content('STDIN');
$r->content_length(5);
$r->content_type('text/plain');

my $c = HTTP::Request::AsCGI->new($r);
$c->stderr(IO::File->new_tmpfile);
$c->setup;

print STDOUT 'STDOUT';
print STDERR 'STDERR';

$c->restore;

is( $c->stdin->getline,  'STDIN',  'STDIN' );
is( $c->stdout->getline, 'STDOUT', 'STDOUT' );
is( $c->stderr->getline, 'STDERR', 'STDERR' );
