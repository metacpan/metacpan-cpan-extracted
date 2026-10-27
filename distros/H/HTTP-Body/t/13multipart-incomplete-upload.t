#!perl

use strict;
use warnings;

use Test::More tests => 2;

use HTTP::Body;
use File::Temp qw/ tempdir /;

my $head = qq{--x\r\nContent-Disposition: form-data; name="f"; filename="a.txt"\r\n\r\n} . ( 'a' x 1000 );

{
    my $dir  = tempdir( CLEANUP => 1 );
    my $body = HTTP::Body->new( 'multipart/form-data; boundary=x', length $head );
    $body->tmpdir($dir);
    $body->add($head);
    undef $body;
    opendir my $dh, $dir or die $!;
    is( scalar( grep { !/^\.\.?$/ } readdir $dh ), 0, 'temporary file of an incomplete upload is deleted' );
}

{
    my $dir  = tempdir( CLEANUP => 1 );
    my $raw  = "$head\r\n--x--\r\n";
    my $body = HTTP::Body->new( 'multipart/form-data; boundary=x', length $raw );
    $body->tmpdir($dir);
    $body->add($raw);
    undef $body;
    opendir my $dh, $dir or die $!;
    is( scalar( grep { !/^\.\.?$/ } readdir $dh ), 1, 'completed upload is left to the caller' );
}
