#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use Mail::Box::IMAP4::SSL;

my ($username,$password, $server);
{
    local $|; $|++;
    print "username: "; chomp($username = <>);
    print "password: "; chomp($password = <>);
    print "server  : "; chomp($server = <>);
}
    
my $imaps = Mail::Box::IMAP4::SSL->new(
    username => $username,
    password => $password,
    server_name => $server,
    folder => 'INBOX',
) or die "Problems creating IMAP4::SSL object\n";

print "Connected to $server.\n";

print $_->get('Subject') . "\n" for $imaps->messages();
