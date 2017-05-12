#!/usr/bin/env perl

use lib '../lib';
use IO::Socket::Socks;
use strict;

# example of using socks bind with FTP active data connection

use constant
{
    FTP_HOST => 'host.net',
    FTP_PORT => 21,
    FTP_USER => 'root',
    FTP_PASS => 'lsdadp',
    SOCKS_HOST => '195.190.0.20',
    SOCKS_PORT => 1080
};

# create control connection
my $primary = IO::Socket::Socks->new(
    ConnectAddr => FTP_HOST,
    ConnectPort => FTP_PORT,
    ProxyAddr => SOCKS_HOST,
    ProxyPort => SOCKS_PORT,
    SocksVersion => 5,
    SocksDebug => 1,
    Timeout => 30
) or die $SOCKS_ERROR;

# create data connection
my $secondary = IO::Socket::Socks->new(
    BindAddr => FTP_HOST,
    BindPort => FTP_PORT,
    ProxyAddr => SOCKS_HOST,
    ProxyPort => SOCKS_PORT,
    SocksVersion => 5,
    SocksDebug => 1,
    Timeout => 30
) or die $SOCKS_ERROR;

# login to ftp
$primary->syswrite("USER ". FTP_USER ."\015\012");
$primary->getline();
$primary->syswrite("PASS ". FTP_PASS ."\015\012");
$primary->getline();

# get address where socks bind and pass it to the ftp server
my ($host, $port) = $secondary->dst();
$host = SOCKS_HOST if $host eq '0.0.0.0'; # RFC says that if host == '0.0.0.0' it means that it should be replaced by socks host
$primary->syswrite("PORT " . join(',', split (/\./, $host),  (map hex, sprintf("%04x", $port) =~ /(..)(..)/)) . "\015\012");
$primary->getline();
$primary->syswrite("LIST /\015\012");
$primary->getline();

# wait connection from ftp server
$secondary->accept()
    or die $SOCKS_ERROR;

# print all data received from ftp server
print while <$secondary>;

# close all connections
$secondary->close();
$primary->close();
