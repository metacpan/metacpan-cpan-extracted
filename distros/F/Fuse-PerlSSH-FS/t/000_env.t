#!/usr/bin/perl

use lib 'lib';
use Test::More tests => 1;

## test for presence of our test_environment_variables
if( $ENV{PERLSSH_HOST} ){
	if( $ENV{PERLSSH_USER} ){
		pass("PERLSSH host values seem to be sound." );
	}else{
		fail("do we have ssh credentials via ENV variables? (HOST is required! You can pass ENV vars like this: make test PERLSSH_HOST=example.com PERLSSH_PORT=port PERLSSH_USER=user)" );
		BAIL_OUT('Required ENV VARS declared!');
	}
}else{
	ok(1);
}