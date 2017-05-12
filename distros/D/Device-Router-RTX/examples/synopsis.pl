#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Device::Router::RTX;
my $rtx = Device::Router::RTX->new (
    address => '12.34.56.78',
    password => 'pwd',
    admin_password => 'admin_pwd',
);
$rtx->connect ();
