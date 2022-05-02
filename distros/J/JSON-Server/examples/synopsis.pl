#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Server;
my $js = JSON::Server->new (handler => \& hello, port => '7777', data => 'OK');
while (1) {
    $js->serve ();
}

sub hello
{
    my ($data, $input) = @_;
    return {%$input, hello => 'world', data => $data};
}

