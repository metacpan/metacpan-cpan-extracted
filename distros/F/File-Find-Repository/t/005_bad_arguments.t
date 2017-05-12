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
local $Plan = {'bad arguments' => 14} ;

# send unexpected argument to new
lives_ok
	{
	new  File::Find::Repository
		(
		REPOSITORIES => [ 'hi' ],
		UNEXPECTED_ARGUMENT => 1,
		
		) ;
	} "unexpected argument to constructor are ignored" ;


my (@info_messages, @warn_messages, @die_messages);

my $info = sub {push @info_messages, [@_]} ;
my $warn = sub {push @warn_messages, [@_]} ;
my $die = sub {push @die_messages, [@_]; die @_} ;

my $locator= new File::Find::Repository
			(
			REPOSITORIES => [ 'hi' ],
			INTERACTION     => 
				{
				#~ INFO  => $info,
				#~ WARN  => $warn,
				DIE   => $die,
				},
				
			) ;
			
dies_ok
	{
	my $located_files = $locator->Find(FILES => 'scalar',) ;
	} "bad args to find" ;
	
dies_ok
	{
	my $located_files = $locator->Find(FILES => ['name'], REPOSITORIES => {},) ;
	} "bad args to find" ;

dies_ok
	{
	my $located_files = $locator->Find(FILES => [], REPOSITORIES => ['.'],) ;
	} "no FILES to find" ;

dies_ok
	{
	my $located_files = $locator->Find(FILES => ['name'], INVALID_ARGUMENT => 1,) ;
	} "invalid args to find" ;

dies_ok
	{
	$locator->Find(FILES => ['name']) ;
	} "void context" ;

dies_ok
	{
	my @context = $locator->Find(FILES => ['name']) ;
	} "array context" ;

throws_ok
	{
	my $located_files = $locator->Find(FILES => ['name'], REPOSITORIES => [{}],) ;
	} qr/Invalid repository type/, "invalid repository type in Find" ;

throws_ok
	{
	my $located_files = $locator->Find(REPOSITORIES => [{}],) ;
	} qr/No FILES/, "no FILES in Find" ;

throws_ok
	{
	my $located_files = $locator->Find(FILES => ['name'], AT_FILE => 'some file') ;
	} qr/Incomplete option AT_FILE::AT_LINE/, "Incomplete option AT_FILE::AT_LINE" ;

throws_ok
	{
	my $located_files = $locator->Find(FILES => ['name'], AT_LINE => 'some line') ;
	} qr/Incomplete option AT_FILE::AT_LINE/, "Incomplete option AT_FILE::AT_LINE" ;

#----------------------------------------

@die_messages = () ;

dies_ok
	{
	my $located_files = $locator->Find() ;
	} "no args to find" ;

use Data::TreeDumper ;

is(@die_messages, 1, "dying") or diag DumpTree \@die_messages ;
like($die_messages[0][0], qr~No argument~, "die message ok") ;

}

=comment

{
local $Plan = {'' => } ;

is(result, expected, "message") ;

dies_ok
	{
	
	} "" ;

lives_ok
	{
	
	} "" ;

like(result, qr//, '') ;

warning_like
	{
	} qr//i, "";

is_deeply
	(
	generated,
	[],
	'expected values'
	) ;
}

=cut
