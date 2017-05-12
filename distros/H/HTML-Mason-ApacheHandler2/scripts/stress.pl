#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;

my $uri = $ARGV[0] || usage();
my $limit = $ARGV[1] || 0;
usage() unless $limit =~ /^\d+$/;

$uri = 'http://' . $uri unless $uri =~ m#^http://#;

my $ua = LWP::UserAgent->new(env_proxy => 1,
			     keep_alive => 1,
			     timeout => 30,
                             );

my $count = 0;
while( 1 ) {
    last if $limit && $count >= $limit;
    my $response = $ua->get($uri);
    unless( $response->is_success ) {
	print STDERR "\nError while getting ", $response->request->uri,
	" -- ", $response->status_line, "\nAborting";
	exit 8;
    }

    unless( $response->{_content} ) {
	print STDERR "\n$uri has no content\n";
	exit 12;
    }
    $count++;
    $| = 1;
    printf "%s\r  $count %s ...",
    ' ' x 60, $response->status_line;
}

print "\n";

sub usage
{
    print STDERR "usage: perl stress.pl <uri> [limit]\n";
    exit 4;
}


