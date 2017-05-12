#!/usr/bin/perl

use strict;
use warnings;
use File::Find::Match;
use File::Find::Match::Util 'filename';
use lib 'blib';

my $finder = new File::Find::Match(
    filename('.svn') => sub { IGNORE },
	qr/_build/   => sub { IGNORE },
	qr/\bblib\b/ => sub { IGNORE },
	qr/\.pm$/    => sub {
		print "Perl module: $_[0]\n";
		return MATCH;
	},
	qr/\.pl$/ => sub {
		print "This is a perl script: $_[0]\n";
	},
	filename('filer.pl') => sub {
		print "this is filer.pl: $_[0]\n";
	},
	qr/filer\.pl$/ => sub {
		print "this is also filer.pl! $_[0]\n";
		return MATCH;
	},
	-d => sub {
		print "Directory: $_[0]\n";
		MATCH;
	},
);

$finder->find('.');
