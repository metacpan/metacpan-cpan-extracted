#!/usr/bin/perl -w
#
# Construct a Kephra object, but don't start it
#
use strict;
use warnings;
BEGIN {
	$| = 1;
	unshift @INC, './lib', '../lib';
}

use Test::NoWarnings;
use Test::More tests => 1;

#use Test::Exception;
#use Kephra::App;
#use Kephra::Config;
#
#File::Spec->catdir($basedir, 'config');
#$Kephra::temp{path}{config} = './share/config';
#$Kephra::temp{path}{help} = './share/help';
#
#$Kephra::STANDALONE = 'dev';
#
#unlink 'share/config/global/autosaved.conf';
#unlink 'share/config/global/autosaved.conf~';
#
# Create the new Kephra object
#my $kephra = Kephra::App->new;
#isa_ok( $kephra, 'Kephra::App' );

exit(0);
