#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use Cwd;
use GD::SecurityImage;

plan tests => 5;

my $i = GD::SecurityImage->new;

my $gt = $i->_versiongt('2.0');
my $lt = $i->_versionlt('3.0');
ok( defined $gt, 'GT defined' );
ok( defined $lt, 'LT defined' );

GT: {
   local $GD::VERSION = '1.19';
   ok( $i->_versiongt('1.18'), 'GT 1.18' );
   ok( $i->_versiongt('1.19'), 'ok. _versiongt() if greater or equal to 1.19' );
   ok( $i->_versionlt('3.0' ), 'but this means "smaller than"' );
}