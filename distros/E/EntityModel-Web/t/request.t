use strict;
use warnings;

use Test::More tests => 23;
use EntityModel::Web::Request;

my $req = new_ok('EntityModel::Web::Request');
$req = new_ok('EntityModel::Web::Request' => [
	method	=> 'get',
	path	=> '/',
	version	=> '1.1',
	header	=> [
		{ name => 'Host',	value => 'something.com' },
		{ name => 'User-Agent', value => 'EntityModel/0.1' },
	]
]);
is($req->method, 'get', 'method is correct');
is($req->path, '/', 'path is correct');
is($req->version, 1.1, 'version is correct');
is($req->hostname, 'something.com', 'host is correct');
is($req->uri->as_string, 'http://something.com/', 'URI is correct');
is($req->header_by_name->get('User-Agent')->value, 'EntityModel/0.1', 'UserAgent is correct');

$req = new_ok('EntityModel::Web::Request' => [
	method	=> 'get',
	version	=> '1.1',
	uri	=> URI->new('http://something.com/page.html'),
	header	=> [
		{ name => 'User-Agent', value => 'EntityModel/0.1' },
	]
]);
is($req->method, 'get', 'method is correct');
is($req->path, '/page.html', 'path is correct');
is($req->version, 1.1, 'version is correct');
is($req->hostname, 'something.com', 'host is correct');
is($req->uri->as_string, 'http://something.com/page.html', 'URI is correct');
is($req->header_by_name->get('User-Agent')->value, 'EntityModel/0.1', 'UserAgent is correct');

$req = new_ok('EntityModel::Web::Request' => [
	method	=> 'get',
	version	=> '1.1',
	uri	=> URI->new('http://something.com/page.html?thing=1'),
	header	=> [
		{ name => 'User-Agent', value => 'EntityModel/0.1' },
		{ name => 'Keepalive', value => '150' },
	]
]);
is($req->method, 'get', 'method is correct');
is($req->path, '/page.html', 'path is correct');
is($req->version, 1.1, 'version is correct');
is($req->hostname, 'something.com', 'host is correct');
is($req->uri->as_string, 'http://something.com/page.html?thing=1', 'URI is correct');
is($req->header_by_name->get('User-Agent')->value, 'EntityModel/0.1', 'UserAgent is correct');
is($req->header_by_name->get('Keepalive')->value, '150', 'Keepalive is correct');

