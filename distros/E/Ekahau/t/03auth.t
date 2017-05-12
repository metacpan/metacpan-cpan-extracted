#!/usr/bin/perl -w
 
use strict;
 
use Test::More tests => 19;

BEGIN {
  use_ok('Ekahau::Server::Test');
  use_ok('Ekahau');
}

my($client_sock,$client);

# Failed Login
$client_sock = Ekahau::Server::Test::Background->start(Password => 'Password');
ok($client_sock,'starting background server 1');
$client_sock
    or die "Couldn't create background server: ",Ekahau::Server::Test::Background->lasterror,"\n";

$client = Ekahau->new(Socket => $client_sock,
		      Timeout => 10,
		      );
ok(!$client,'client with bad password');
close($client_sock); # probably already closed
ok(wait,'wait for server 1');

# Simple Login
$client_sock = Ekahau::Server::Test::Background->start(Password => 'Password');
ok($client_sock,'starting background server 2');
$client_sock
    or die "Couldn't create background server: ",Ekahau::Server::Test::Background->lasterror,"\n";

$client = Ekahau->new(Socket => $client_sock,
		      Timeout => 10,
		      Password => 'Password',
		      );
isa_ok($client,'Ekahau');
$client
    or die "Couldn't create Ekahau client: ",Ekahau->lasterror(),"\n";
ok($client->get_device_list,'getting device list');
undef $client;
close($client_sock); # probably already closed
ok(wait,'wait for server 2');

# License Login
$client_sock = Ekahau::Server::Test::Background->start(Password => 'Password',
						       LicenseFile => 't/license.xml',
						       );
ok($client_sock,'starting background server 3');
$client_sock
    or die "Couldn't create background server: ",Ekahau::Server::Test::Background->lasterror,"\n";

$client = Ekahau->new(Socket => $client_sock,
		      Timeout => 10,
		      Password => 'Password',
		      LicenseFile => 't/license.xml',
		      );
isa_ok($client,'Ekahau','creating Ekahau client');
$client
    or die "Couldn't create Ekahau client\n";
ok($client->get_device_list,'getting device list');
undef $client;
close($client_sock); # probably already closed
ok(wait,'wait for server 3');

# License Failure 1
$client_sock = Ekahau::Server::Test::Background->start(Password => 'Password',
						       LicenseFile => 't/license.xml',
						       );
ok($client_sock,'starting background server 3');
$client_sock
    or die "Couldn't create background server: ",Ekahau::Server::Test::Background->lasterror,"\n";

$client = Ekahau->new(Socket => $client_sock,
		      Timeout => 10,
		      Password => 'Wrong',
		      LicenseFile => 't/license.xml',
		      );
ok(!$client,'licensed client with bad password');
close($client_sock); # probably already closed
ok(wait,'wait for server 4');

# License Failure 2
$client_sock = Ekahau::Server::Test::Background->start(Password => 'Password',
						       LicenseFile => 't/license.xml',
						       );
ok($client_sock,'starting background server 3');
$client_sock
    or die "Couldn't create background server: ",Ekahau::Server::Test::Background->lasterror,"\n";

$client = Ekahau->new(Socket => $client_sock,
		      Timeout => 10,
		      Password => 'Password',
		      LicenseFile => 't/badlicense.xml',
		      );
ok(!$client,'client with bad license');
close($client_sock); # probably already closed
ok(wait,'wait for server 5');
