#!/usr/bin/perl -w
#
# testing public methods of Kephra::Config::Tree 
#
BEGIN {
	chdir '..' if -d '../t';
	$| = 1;
}

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 7;
use Test::NoWarnings;
use Kephra::Config::Tree;

my $simple = {'a'=>{ 'very' => {'deep' => 'hash'}}};
my $sub = Kephra::Config::Tree::subtree($simple, 'a/very');
is_deeply( $sub, {'deep' => 'hash'}, 'subtree' );
is_deeply( Kephra::Config::Tree::copy($simple), $simple, 'copy' );

my $more = {'a'=>{ 'second' => {'very' => {'deeep' => 'hash'}}}};
my $merge = Kephra::Config::Tree::merge($simple, $more);
is_deeply( { 'a'=>{ 
	'very'   => {'deep' => 'hash'},
	'second' => {'very' => {'deeep' => 'hash'}},
},}, $merge, 'merge');

my $simpelmo = {'a'=>{ 'very' => {'deep' => 'trick', 'far' => 'out'}}};
my $update = Kephra::Config::Tree::update($simple, $simpelmo);
is_deeply( {'a'=>{'very' => {'deep' => 'trick'}}}, $update, 'update');

my $diff1 = Kephra::Config::Tree::diff($simple, $simpelmo);
my $moremo = {'a'=>{'very' => {'deep' => {second => 'trick'}, 'far' => 'out'}}};
my $diff2 = Kephra::Config::Tree::diff($moremo, $simpelmo);

is_deeply( $diff1, $simple, 'simple diff');
is_deeply( $diff2, {'a'=>{'very' => {'deep' => {second => 'trick'}}}}, 'complex diff');

exit(0);