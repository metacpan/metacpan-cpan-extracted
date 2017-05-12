# test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use File::Find::Repository ; 

{
local $Plan = {'Repositories' => 6} ;

dies_ok
	{
	new  File::Find::Repository
		(
		REPOSITORIES => {},
		) ;
	} "repositories not defined in array" ;

dies_ok
	{
	new  File::Find::Repository
		(
		REPOSITORIES => [ [] ],
		) ;
	} "invalid repositories" ;

dies_ok
	{
	new  File::Find::Repository
		(
		REPOSITORIES => [undef],
		) ;
	} "invalid repositories" ;
	
lives_ok
	{
	new  File::Find::Repository
		(
		REPOSITORIES => [ 'whatever', ''],
		) ;
	} "strange repositories" ;
	
lives_ok
	{
	new  File::Find::Repository
		(
		REPOSITORIES => [ '/' ],
		) ;
	} "root repository" ;

lives_ok
	{
	new  File::Find::Repository
		(
		REPOSITORIES => [ sub{undef}],
		) ;
	} "sub repository" ;

}