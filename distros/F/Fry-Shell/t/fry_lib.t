#!/usr/bin/perl
use strict qw/vars subs/;

use Test::More tests=>16;
use lib 'lib';
use lib 't/testlib';

use base 'MyBase';
use base 'Fry::Lib';
require Fry::Sub;
require Fry::Var;
require Fry::Obj;

my @libs = qw/:Test1 Fry::Lib::Woah/;

is_deeply([main->fullName(@libs)],[qw/Fry::Lib::Test1 Fry::Lib::Woah/],'&fullName');

main->runLibInits('Fry::Lib::SampleLib');
is_deeply(&Fry::Lib::SampleLib::_initLib,'CmdClass','&runLibInits requires library and sets shell object correctly');

#loadLib(getLibData,loadDependencies,setAllObj,addToCmdClass,setLibObj)

	is_deeply(main->_getLibData('Fry::Lib::SampleLib'),Fry::Lib::SampleLib->_default_data,
		'&_getLibData: returns _default_data');

	#setup
	Fry::Var->defaultNew(loaded_libs=>[],cmd_class=>'CmdClass');	
	require Fry::Opt;
	require Fry::Cmd;
	main->loadLib('Fry::Lib::SampleLib');

	is_deeply(main->Var('loaded_libs'),[qw/Fry::Lib::EmptyLib Fry::Lib::SampleLib/],
		'&loadDependencies/&loadLib: libs loaded in right order');
	is_deeply([@CmdClass::ISA],[qw/Fry::Lib::EmptyLib Fry::Lib::SampleLib/],'cmdclass ISA set in &loadLib'); 

	#&_readLibObj
	my ($varlist,$optlist,$cmdlist) =  main->_readLibObj(Fry::Lib::SampleLib->_default_data);
	is_deeply([sort @$varlist],[qw/var1 var2/],'&_readLibObj: correct varlist');
	is_deeply([sort @$optlist],[],'&_readLibObj: correct optlist');
	is_deeply([sort @$cmdlist],[qw/cmd1 cmd2/],'&_readLibObj: correct cmdlist and tests lib attr');

	is(main->loadLib('Blah'),0,'&loadLib: invalid lib exits early');
#other
	use Data::Dumper;
	#print Dumper(main->list);
	#print @CmdClass::ISA,"\n";
	#print @Fry::Sub::_Methods::ISA,"\n";
	ok(main->libsLoaded(':SampleLib',':EmptyLib'),'&libsLoaded: pass');
	ok(! main->libsLoaded(':PhoneyLib'),'&libsLoaded: fail');
	main->unloadLib('Fry::Lib::SampleLib');
	main->unloadLib('Fry::Lib::EmptyLib');
	is_deeply([@CmdClass::ISA],[],'unloadLib: shell ISA cleaned');
	is_deeply([@{"$Fry::Sub::LibClass\::ISA"}],[],'unloadLib: sub ISA cleaned');
	is_deeply(Fry::Cmd->list,{},'unloadLib: cmds have been deleted');
	is_deeply([sort keys %{Fry::Var->list}],[qw/cmd_class loaded_libs/],'unloadLib: vars have been deleted');
	is_deeply(main->list,{},'unloadLib: libs have been deleted');
