#!perl
use v5.10;
use strict;
use warnings;

use File::FindLib qw(lib);
use Mojo::Util qw(dumper);

use HTTP::Cookies::Chrome;

my $class    = 'HTTP::Cookies::Chrome';
my $path     = $class->guess_path;
my $password = $class->guess_password;

say <<~"HERE";
	File: $path
	Pass: $password
	HERE

my $cookies = HTTP::Cookies::Chrome->new(
	chrome_safe_storage_password => $password,
	ignore_discard => 0,
	);
$cookies->load( $path );

$cookies->scan( \&summary );

sub summary {
	state $previous_domain = '';
	my( @cookie ) = @_;
	say $cookie[4] unless $cookie[4] eq $previous_domain;
	$previous_domain = $cookie[4];
	printf "\t%-5s %-16s %s\n", map { $_ // '' } @cookie[3,1,2];
	}
