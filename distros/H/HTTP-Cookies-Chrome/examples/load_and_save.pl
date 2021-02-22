#!perl
use v5.26;

use lib qw(lib);
use HTTP::Cookies::Chrome;

my $class    = 'HTTP::Cookies::Chrome';
my $path     = $class->guess_path;
my $password = $class->guess_password;

say <<~"HERE";
	File: $path
	Pass: $password
	HERE

my $old = $class->new(
	chrome_safe_storage_password => $password,
	ignore_discard => 0,
	file => $path,
	);
$old->load;

my $new_file = 'chrome_cookies.db';
unlink $new_file;
$old->save( $new_file );
