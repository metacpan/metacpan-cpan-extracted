use warnings;
use strict;
use lib 'lib';
use HTTP::Server::Simple::Kwiki;

chdir "my-kwiki"; 
my $server = HTTP::Server::Simple::Kwiki->new();
#$server->host('192.168.43.249');
$server->run();
