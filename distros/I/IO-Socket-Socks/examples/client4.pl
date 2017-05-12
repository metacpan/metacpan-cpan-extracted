#!/usr/bin/env perl

# Simple socks4 client
# gets google.com main page
# implemented with IO::Socket::Socks

use lib '../lib';
use strict;
use IO::Socket::Socks;

# uncomment line below if you want to use socks4a
#$IO::Socket::Socks::SOCKS4_RESOLVE = 1;

my $socks = new IO::Socket::Socks(ProxyAddr=>"127.0.0.1",
                                  ProxyPort=>"1080",
                                  ConnectAddr=>"www.google.com",
                                  ConnectPort=>80,
                                  Username=>"oleg", # most socks4 servers doesn't needs userid, you can comment this
                                  SocksDebug=>1, # comment this if you are not interested in the debug information
                                  SocksVersion => 4, # default is 5
                                  Timeout=>10,
                                 )
or die $SOCKS_ERROR;

$socks->syswrite (
    "GET / HTTP/1.0\015\012".
    "Host: www.google.com\015\012\015\012"
);

while($socks->sysread(my $buf, 1024))
{
    print $buf;
}

# tested with server4.pl
