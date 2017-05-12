use strict;
use sort 'stable';
use Test::More;
use File::Temp;
BEGIN {
	*CORE::GLOBAL::time = sub { 1446822558 } # fake time to prevent cookies discarding
}
use_ok('HTTP::Cookies::PhantomJS');

use constant COOKIES_CNT => 0x94;

my $c = HTTP::Cookies::PhantomJS->new(ignore_discard => 1);
ok($c, 'object created');
isa_ok($c, 'HTTP::Cookies::PhantomJS');

ok($c->load('t/cookies.txt'), 'cookies loaded');
my $cookies_cnt;
my %cookies_a;
$c->scan(sub {
	my ($version, $key, $val, $path, $domain) = @_;
	
	is($version, 0, 'version is always 0');
	ok(length($key), 'key always exists');
	ok(length($val), 'value always exists');
	ok(length($path), 'path always exists');
	ok($domain, 'domain always exists');
	
	my $rest = pop;
	$_[2] =~ s/^"//;
	$_[2] =~ s/"$//;
	$cookies_a{join(';', @_, sort keys %$rest)} = 1;
	
	$cookies_cnt++;
});
is($cookies_cnt, COOKIES_CNT, 'right cookies count');

my ($fh, $filename) = File::Temp::tempfile(undef, UNLINK => 1);
ok($c->save($filename), 'cookies saved');
$c = HTTP::Cookies::PhantomJS->new(file => $filename, ignore_discard => 1);
ok($c, 'new cookies object loaded from the file');
isa_ok($c, 'HTTP::Cookies::PhantomJS');

$cookies_cnt = 0;
my %cookies_b;
$c->scan(sub {
	my ($version, $key, $val, $path, $domain) = @_;
	
	is($version, 0, 'version is always 0');
	ok(length($key), 'key always exists');
	ok(length($val), 'value always exists');
	ok(length($path), 'path always exists');
	ok($domain, 'domain always exists');
	
	my $rest = pop;
	$_[2] =~ s/^"//;
	$_[2] =~ s/"$//;
	$cookies_b{join(';', @_, sort keys %$rest)} = 1;
	
	$cookies_cnt++;
});
is($cookies_cnt, COOKIES_CNT, 'right cookies count after reloading');

is_deeply(\%cookies_a, \%cookies_b, 'cookies are same after reloading');

done_testing;
