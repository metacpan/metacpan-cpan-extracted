#!/usr/bin/perl

use strict;
use warnings;
use FabForce::DBDesigner4::DBIC;

my $dbic = FabForce::DBDesigner4::DBIC->new();
$dbic->namespace( 'Test' );
$dbic->create_scheme( 'Datenbank.xml' );