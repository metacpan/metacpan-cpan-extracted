#!/usr/bin/perl

# Compile testing for jsan

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use File::Spec::Functions ':ALL';
use JSAN::Shell ();
use File::Remove;


BEGIN { File::Remove::remove( \1, 'temp' ) if -e 'temp'; }
END   { File::Remove::remove( \1, 'temp' ) if -e 'temp'; }

ok( mkdir('temp'), "Test directory 'temp' created" );


#####################################################################
# Creating shell 

my $shell = JSAN::Shell->new(
    configdir => 'temp'
);


#####################################################################
# Testing configuration file 

ok(!$shell->prefix, "Initial prefix is empty");

is_deeply($shell->read_config(), {}, "Initial 'read_config' returns empty hash");


#####################################################################
# Setting prefix 

$shell->prefix('temp');

ok($shell->prefix eq 'temp', "Prefix was set");


#####################################################################
# Remembering prefix 

$shell->remember_config_option('prefix', 'temp');


is_deeply($shell->read_config(), { prefix => 'temp' }, "Config file was updated");

