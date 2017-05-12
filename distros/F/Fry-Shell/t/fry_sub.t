#!/usr/bin/perl

package main;
use strict;
use Test::More tests=>15;
use lib 'lib';
use lib 't/testlib';
use base 'Fry::Sub';
#use Test::Warn;
use MyWarn;
#use Data::Dumper;
#use diagnostics;

my $cls = "Fry::Sub"; 

package FakeSubLib;
our @foaf;
sub foaf { @foaf = @_ }
*foaf2 = *foaf;
package main; 
#subs
	$cls->defaultNew(foaf=>{qw/sub foaf/},[module=>'FakeSubLib']);
	ok(grep(/FakeSubLib/,@Fry::Sub::_Methods::ISA) > 0,'&defaultNew: ISA set correctly');
	$cls->call('foaf','yo','yo');
	is_deeply([@FakeSubLib::foaf],[qw/Fry::Sub yo yo/],'&call: defined sub in path called');
	$cls->call('foaf2','yo','yo');
	is_deeply([@FakeSubLib::foaf],[qw/Fry::Sub yo yo/],'&call: undefined sub in path called');

#util subs
	my @args = qw/one two four/;
	$cls->spliceArray(\@args,'two');
	is_deeply([sort @args],[qw/four one/],'&spliceArray');

	#warning_like {$cls->_require('Blah',{qw/warn 1/})} qr//,'&_require warns';
	warn_count(sub { $cls->_require('Blah',{qw/warn 1/})},'_require');
	$cls->_require('FakeSh');
	is(exists $INC{'FakeSh.pm'},1,'&_require: required moduled in %INC');
	eval {$cls->_require('Blah.pm')};
	ok($@,'&_require dies');

	$cls->useThere('Fry::Lib::SampleLib','main');
	is($Fry::Lib::SampleLib::use[-1],'Fry::Lib::SampleLib','&useThere calls useclass import');
	require Fry::Lib::SampleLib;
#Parse subs
	Fry::Base->_core(var=>'Fry::Var');
	require Fry::Var;
	Fry::Var->defaultNew(lines=>[],pipe_char=>'\s*\|\s*',eval_splitter=>',,');	

	#parseMenu(parsenum)
	Fry::Var->set('lines','value',[qw/one cow fart equals thirty human farts/]);
	my $menuinput = "scp -ra 2-5,7";
	my @results = $cls->parseMenu($menuinput);
	is_deeply(\@results,[qw/scp -ra cow fart equals thirty farts/],"&parseMenu + &parsenum");

	is_deeply([sort $cls->parseNormal("just testing away")],[qw/away just testing/],'&parseNormal');

	is_deeply([sort $cls->parseChunks("well |man| woah")],[qw/man well woah/],'&parseChunks');

	my $input = "-m=yeah yo man";
	is_deeply({$cls->parseOptions(\$input)},{qw/m yeah/},'&parseOptions: returns parsed options');
	
	$input = "testing\n this\n piece";
	$cls->parseMultiline(\$input);
	is($input,"testing this piece",'&parseMultiline');

	is_deeply([$cls->parseEval("ok that,,{qw/is cool/}")],[qw/ok that/,{qw/is cool/}],'&parseEval');
	eval {$cls->parseEval('ok well,,{[}]') }; ok($@,'&parseEval dies on invalid syntax');
