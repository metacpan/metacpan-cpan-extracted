#!/usr/bin/perl

package main;
use strict;
#use diagnostics;
use Test::More tests=>10;
use lib 'lib';
use lib 't/testlib';
use base 'Fry::Error';
#use Data::Dumper;

Fry::Error->setup;
#$DefaultDieLevel=7;
#$GlobalLevel = 0

my $err = Fry::Error->new(from=>'warn',arg=>'woah');
is_deeply([sort keys %$err],[qw/arg caller from id level/],'&setErrObj: correct keys');

#parseWarnArgs,parseDieArgs
	my %warn = (ref=>['done',{qw/species man/}], many=>['beep',1,'nonsense','blah']);
	my %out = __PACKAGE__->parseWarnArgs(@{$warn{ref}});
	is_deeply(\%out,{arg=>['done'],qw/species man/},'&parseWarnArgs: hashref');
	%out = __PACKAGE__->parseWarnArgs(@{$warn{many}});
	is_deeply(\%out,{qw/arg beep level 1 tags nonsense/},'&parseWarnArgs: aliased args');


#SigHandler
	#die
	#can't test non-eval level>7 case
	eval {die('woah',{qw/level 6/}) };
	ok($@,'die: dies for lower level eval-wrapped die');
	die({qw/arg woah level 6/});
	ok(1,"doesn't die for level < dielevel");

	#warn
	warn('woah');
	is($Fry::Error::Called,1,'warn: called when level >= global');
	warn('woah',2);
	is($Fry::Error::Called,0,'warn: not called when level < global');

#default die and warn
	$Fry::Error::DefaultDie = 1;
	eval { die('again') };
	is($Fry::Error::Called,0,'$DefaultDie works');
	$Fry::Error::DefaultDie = 0;

	$Fry::Error::DefaultWarn = 1;
	warn('once again');
	is($Fry::Error::Called,0,'$DefaultWarn works');
	$Fry::Error::DefaultWarn = 0;

my @warn;
sub warnsub {@warn = @_ }
main->setup;
warn('testing');
is($warn[1],'testing','subclassed warnsub called'); 

exit;
#stack related
my @stack = main->stack;
is(main->stack,5,'&stack: correct number of errors returned');

main->flush(2);
is(main->stack,3,'&flush: spliced correctly');
main->flush;
is(main->stack,0,'&flush: reset stack');

#print main->stringify_stack;
