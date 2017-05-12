#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use File::Basename;
use File::Spec;
use Cwd;


my $class  = 'Distribution::Guess::BuildSystem';
my $method = '_setting';

use_ok( $class );
can_ok( $class, $method );

{
my $guesser = $class->new(
	perl_binary => 'foo',
	);

is( $guesser->_setting( 'perl_binary' ), 'foo', 
	'perl_binary setting is right from constructor value' );
$guesser->_setting( 'perl_binary', 'bar' );
is( $guesser->_setting( 'perl_binary' ), 'bar', 
	'perl_binary setting is right from new value' );
}
