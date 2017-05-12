#!/usr/bin/perl

package main;
use strict;
use Test::More tests=>28;
use lib 'lib';
use lib 't/testlib';
#use Test::Warn;
use MyWarn;
#use diagnostics;
#use Data::Dumper;

use MyBase;
use base 'Fry::Cmd';
@Fry::Cmd::ISA = qw/Fry::List MyBase/;
use FakeSh;
require Fry::Var;
require Fry::Type;
Fry::Var->new(qw/id method_caller value 1/);
require Fry::Sub;

#to put tests in Shell's path
push (@FakeSh::ISA,'FakeLib');
push (@Fry::Sub::ISA,'FakeLib');
#package CmdClass;
#push (@CmdClass::ISA,'FakeLib');


package FakeLib;
sub t_var {  shift; @main::testvar = @_ ; return $FakeSh::Pass}
sub defaultTest {1}
*loopDefault = \&t_var;
*slow = \&t_var;
sub t_fail {0 };
sub defaultTest {1};
sub aliasargs { shift; return map { s/k/g/g; $_} @_ }
our @all;
sub allValues  { @all = @_ }

package CmdClass;
#h: this class shouldn't be here
*aliasargs=\&FakeLib::aliasargs;

package main;

my %obj = (scalar=>{qw/id scalar arg $var/,_sub=>\&scalar,aa=>\&aliasargs},
	array=>{qw/id array arg @var aa aliasargs/},hash=>{qw/id hash arg %var/}
	,other=>{qw/id other arg $blah/}); 
my @args = (qw/k1 v1 k2 v2/);
my %expected = (scalar=>['k1'],array=>[qw/k1 k2 v1 v2/],hash=>[qw/k1 k2/]);
our @testvar;
my @scalar;
sub scalar {@scalar = @_ if (@_)}
sub aliasargs { shift; return map { s/k/g/g; $_} @_ }

main->manyNew(%obj);
Fry::Sub->defaultNew(aliasargs=>{qw/sub aliasargs/},t_fail=>{qw/sub
t_fail/},defaultTest=>{qw/sub defaultTest/},{module=>'FakeLib'});

#warning_like { main->runTest('t_fail',@args)} qr//,'&runTest warning: invalid argument type';
warn_count (sub { main->runTest('t_fail',@args) },'runTest');

#argAlias
	#main->argAlias('scalar',\@args);
	#is_deeply([sort @args],[qw/g1 g2 v1 v2/],'&argAlias: coderef');
	#@args = (qw/k1 v1 k2 v2/);

	main->argAlias('array',\@args);
	is_deeply([sort @args],[qw/g1 g2 v1 v2/],'&argAlias: sub name');
	@args = (qw/k1 v1 k2 v2/);

	is(main->argAlias('hash',\@args),0,'&argAlias fails w/ 0');

#&checkArgs
	is(main->checkArgs('blah',@args),1,'&checkArgs exits w/ 1');
	#tests pass
	for my $cmd (qw/scalar array hash/) { 
		is(main->checkArgs($cmd,@args),1,'checkArgs passes');
		is_deeply([sort @testvar],$expected{$cmd},"correct arguments passed to test sub for $cmd");
		@args = (qw/k1 v1 k2 v2/);
	}

	#tests fail
	$FakeSh::Pass = 0;

	for my $cmd (qw/scalar array hash/) { 
		is(main->checkArgs($cmd,@args),0,'checkArgs fails');
		is_deeply([sort @testvar],$expected{$cmd},"correct arguments passed to test sub for $cmd");
		is(main->Flag('skipcmd'),1,'skipcmd flag set');
		@args = (qw/k1 v1 k2 v2/);
	}
	#warning_like {main->checkArgs('other',@args)} qr//,'&checkArgs warning: test sub not found';
	#td: warn_count(sub {main->checkArgs('other',@args) },'checkArgs');

#&runCmd cases
	@args = (qw/tested cmd/);
	main->runCmd('scalar',@args);
	is_deeply([sort @scalar],[qw/cmd tested/],'&runCmd: attribute sub used,called with correct arguments');
	#warning_like { main->runCmd('t_var',@args)} [qr//,qr//,qr//],'&runCmd warning: no _sub attr';
	warn_count(sub {main->runCmd('t_var',@args) },'runCmd');
	is_deeply([sort @testvar],[qw/cmd t_var tested/],'&runCmd: autoloaded sub used,called with correct arguments');
	#warning_like {main->runCmd('junk',@args)} [qr//,qr//,qr//],'&runCmd warning: not in path';
	warn_count(sub {main->runCmd('junk',@args)},'runCmd');
	is_deeply([sort @testvar],[qw/cmd junk tested/],'&runCmd: loopDefault called with correct arguments');

	Fry::Var->set(qw/method_caller value FakeLib/);
	main->runCmd('allValues',@args);
	is_deeply([sort @FakeLib::all],[qw/FakeLib cmd tested/],'&runCmd: autoloaded w/ caller from var method_caller');

	Fry::Var->set(qw/method_caller value Fry::Var/);
	#warnings_like { main->runCmd('allValues',@args) } [qr//,qr//,qr//],
		#'&runCmd warning: method_caller can\'t call method';
	#td: warn_count(sub {main->runCmd('allValues',@args) },'runCmd');
	Fry::Var->set(qw/method_caller value 1/);

#&defaultNew
	package main;
	my %newobj = (quick=>{qw/id quick/,_sub=>sub {}},slow=>{qw/id slow/});

	main->defaultNew(%newobj);
	ok(main->get('slow','_sub'),'&defaultNew: default _sub made');
	ok(main->get('slow','_sub'),'&defaultNew: default _arg made');
	@args = qw/check one two/;
	sort FakeSh->slow(@args);
	is_deeply([sort @testvar],[sort @args] ,'&defaultNew: default sub calls as a shell method'); 
