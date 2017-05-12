#!/usr/bin/perl

package main;
use strict;
use Test::More tests=>17;
use lib 'lib';
use base 'Fry::Shell';
use lib 't/testlib';
use Fry::Lib::SampleLib;
use Data::Dumper;
use Test::Warn;
use MyWarn;

#setup
my $once;
sub once { $once++ }
#use Fry::Error::Carp;
#Fry::Error::Carp->setup;
#$Fry::Error::Carp::SHIFT = 8;

#FAKE SHELL
require MyBase;
my $o = {%MyBase::coreHash};
#{qw/lib Fry::Lib cmd Fry::Cmd var Fry::Var opt Fry::Opt sub Fry::Sub obj Fry::Obj type Fry::Type/};
bless $o,__PACKAGE__;
#$Fry::Error::GlobalLevel = 0;

#under &new
	$o->_initCoreClasses({});
	can_ok('Fry::Shell',qw/lib cmd var opt sub/,);
	print "\t&_initCoreClasses: defined core classes\n";
	eval { $o->_initCoreClasses({qw/lib yoyo/}); };
	ok($@,'&_initCoreClasses die: invalid class');

#main subs
	$o->setFlag(quit=>1);
	$o->shell;
	is($once,1,'&shell: &once called once w/ quit Flag set');

#General checks
	my $loaded_modules = [qw#Fry/Base.pm Fry/Cmd.pm Fry/Error.pm Fry/Lib.pm Fry/List.pm Fry/Opt.pm Fry/Shell.pm Fry/Var.pm#];
	sub check_modules { for (@$loaded_modules) { (exists $INC{$_})? 1: return 0 }; return 1 }
	#ok(&check_modules,'expected Fry modules in %INC');


#Fry::ShellI
	#Fry::List wrappers-should can errors die?
	#warning_like {$o->unloadGeneral('dodo','args') } qr//,"&unloadGeneral warning: invalid core class";
	#warn_count(sub {$o->unloadGeneral('dodo','args')},'unloadGeneral');
	#td: List,listAll
#misc
	Fry::Var->defaultNew(plugin_config=>'Fry::Config::Default');

	$o->loadFile('t/testlib/shell.conf');
	is($o->Var('top_secret'),'nothing','&loadFile: set a variable correctly');
	#warnings_like { $o->loadFile('blah')} qr//,'&loadFile warning: invalid file';
	warn_count(sub{$o->loadFile('blah')},'loadFile');
	Fry::Var->unloadObj('top_secret');

	#warnings_like {$o->loadPlugins('wawa')} qr//,'&loadPlugins warning: invalid module';
	warn_count(sub {$o->loadPlugins('wawa')},'loadPlugins');

#REAL SHELL
$o = main->new;
*once = *Fry::Shell::once;

#general checks
	is_deeply([sort $o->List('var')],[sort (qw/shell_class/, keys %{Fry::Lib::Default->_default_data->{vars} },
		keys %{main->_default_data->{vars}})],'core vars loaded');
	is_deeply([sort $o->List('opt')],[sort (keys %{main->_default_data->{opts}})],'core options loaded');
	is_deeply($o->Var('loaded_libs'),[qw/Fry::Shell Fry::Sub Fry::Lib::Default/],'libs loaded in right order in &loadLib');
	is_deeply([@CmdClass::ISA],[qw/Fry::ShellI Fry::Lib::Default/],'cmdclass ISA set in &loadLib'); 

#parse*
	$o->saveArray(qw/one cow fart equals thirty human farts/);
	my $menuinput = "scp -ra 2-5,7";
	my @results = $o->sub->parseMenu($menuinput);

	my $input = "-m=yeah yo man";
	is_deeply([$o->parseLine("-m $menuinput")],\@results,'&parseLine strips options and menu flag works');

#options
	my $menuinput = "scp -ra 2-5,7";
	#&parseCmd + parsecmd opt
		$o->setVar(parsecmd=>'m');
		is_deeply([$o->_parseCmd($menuinput)],\@results,'aliased parsecmd opt switched parse modes correctly');

		$o->setVar(parsecmd=>'menu');
		is_deeply([$o->_parseCmd($menuinput)],\@results,'unaliased parsecmd opt switched parse modes correctly');
		
		$o->setVar(parsecmd=>'blah');
		is_deeply([$o->_parseCmd($menuinput)],[$o->sub->parseNormal($menuinput)],'default parsecmd called on invalid parsecmd');
		$o->setVar(parsecmd=>'m');
#&once
	$o->lib->loadLib('Fry::Lib::SampleLib');

	$o->once("cmd1 |cmd2"); 
	is_deeply(\@Fry::Lib::SampleLib::called_cmds,[qw/cmd1 cmd2/],'piping via &once');
	@Fry::Lib::SampleLib::called_cmds=();
	$Fry::Lib::SampleLib::called_tests= 0;

	#td: strange cmds exeing out of order
	eval { $o->once('blah') };
	#ok (! $@,'invalid cmd doesn\'t fail via &once');
	eval {$o->once('') };
	#ok (! $@,'empty cmd doesn\'t fail via &once');

	$o->setFlag(skipcmd=>1);
	$o->setFlag(skiparg=>1);
	$o->once('cmd1');
	is_deeply(\@Fry::Lib::SampleLib::called_cmds,[],'option skipcmd worked');
	is($Fry::Lib::SampleLib::called_tests,0,'option skiparg worked');
	$o->setFlag(skipcmd=>0);
	$o->setFlag(skiparg=>0);

	#*parseLine = sub { die "now" } ;
	#$o->once('cmd1');
	#is($warn,1,'&once warning:');
	#warnings_like {$o->once('cmd1')} qr//,'&once warning: die converted to warning';
