use strict;

# vim: ft=perl sw=4 ts=4

# run this test?
use File::Basename;
use open IN => ':crlf'; # auto-handle line endings

require Test::More;

my $test_bn = basename($0);
$test_bn =~ /^\d+-(.*)\.t/;
my $test_name = $1;

my %config;
# default configuration
$config{url} ||= 'http://site.com/exchange/username/Inbox';
$config{username} ||= 'DOMAIN\\username';

open my $config_fh, "<", "test.config" or die "Could not open test configuration!";
while(<$config_fh>) {
  chomp;
  my ($key, $value) = split /\s+/, $_, 2;
	$config{$key} = $value;
}
close $config_fh;

# create dummy test to keep the harness happy if we're not running this test
if(!$config{live_tests}) {
	import Test::More tests => 1;
	ok(1);
	exit;
}

# now the real tests begin
use Email::Folder::Exchange;
use UNIVERSAL qw(isa);

import Test::More tests => 6;

use_ok('Term::ReadKey');

print STDERR "\n";
print STDERR "URL to test [$config{url}]: ";
my $url = ReadLine(0);
chomp $url;
$config{url} = $url if $url;

print STDERR "Username to authenticate with [$config{username}]: ";
my $username = ReadLine(0);
chomp $username;
$config{username} = $username if $username;

print STDERR "Password to authenticate with [will not echo]: ";
ReadMode('noecho');
my $password = ReadLine(0);
chomp $password;
ReadMode('normal');

# save config
open $config_fh, ">", "test.config";
while(my($key, $value) = each(%config)) {
	print "$key $value \n";
  print $config_fh "$key $value\n";
}

ok(my $f = Email::Folder::Exchange->new($config{url}, $config{username}, $password), 'login');

ok(my $f2 = $f->next_folder, 'next_folder');

ok(isa($f2, 'Email::Folder::Exchange::EWS') || isa($f2, 'Email::Folder::Exchange::WebDAV'), 'folder_type');

ok(my $m = $f->next_message, 'next_message');

ok(isa($m, 'Email::Simple'), 'message_type');

1;
