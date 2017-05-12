#!/usr/bin/env perl

use RedisDB;
use Getopt::Std;

getopts( 'p:h:k:d:t:f:', \my %options );

my $database = defined $options{d} ? $options{d} : 0;
my $file     = defined $options{f} ? $options{f} : '-';
my $host     = defined $options{h} ? $options{h} : 'localhost';
my $key      = defined $options{k} ? $options{k} : 'LOG';
my $port     = defined $options{p} ? $options{p} : 6379;
my $timeout  = defined $options{t} ? $options{t} : 60;

my $redis_db = RedisDB->new(
    database => $database,
    host     => $host,
    key      => $key,
    port     => $port
);

my $fh;

if ( $file eq '-' ) {
    $fh = *STDOUT;
} else {
    open( $fh, ">>", $file ) or die "cannot open '$file' for append: $!";
    $fh->autoflush(1);
}

$SIG{HUP} = sub { $shutdown = 1 };

while ( !$shutdown ) {
    my $msg = $redis_db->blpop( $key, $timeout );
    $fh->print( $msg->[1], "\n" ) if $msg;
}

$fh->close;

exit;
