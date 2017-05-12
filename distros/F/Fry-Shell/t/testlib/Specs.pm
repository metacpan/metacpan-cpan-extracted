package Specs;
sub subs {
	my $sub = shift->getKey(@_);
	return &{$sub};
}
sub getKey {
	my $sub;
	if ($_[1] =~ /Fry::Dump/) { $sub = 'dump'; }
	elsif ($_[1] =~ /Fry::ReadLine/) { $sub = 'readline'; }
	elsif ($_[1] =~ /Fry::View/) { $sub = 'view'; }
	else {
		$_[1] =~ /::(\w+)$/;
		$sub = lc($1);
	}
	return $sub;
}
sub leftover {
	print "yooo\n";
	my $key = shift->getKey(@_);
	return @{$left{$key}}
}


#SPECS
#parents
	sub shell {
		my @redefine = qw/loopDefault preLoop postLoop setPrompt parseLine autoView getInput postQuit/;
		return (Specs->shell_script,Specs->shelli,Specs->base,@redefine);
	}
	sub shell_script { qw/shell once new loadPlugins loadFile initLibs runCmd/ }
	sub shelli { return (qw/ varMany saveArray listAll List call/)
	}
	sub base { return qw/var lib cmd opt sub obj sh type 
		setVar Var setFlag Flag listCore
		Caller Sub Config Dump Error Rline View view dumper/
	}
	sub list {  return qw/new manyNew Obj objExists unloadObj get set getMany setMany attrExists
		allAttr listIds listAliasAndIds listAlias findAlias anyAlias pushArray findIds defaultNew
		indexObj defaultSet/
	}
#core-all have isa:list,base
	sub lib { return (qw/defaultNew runLibInits fullName getLibData readLibObj setAllObj
		 unloadLib
		loadLib loadDependencies loadLibs initLibs/)
	}
	sub var { return qw/setOrMakeVar defaultNew defaultSet Var setVar/ }
	sub opt { return qw/defaultNew setOptions Opt findSetOptions resetOptions preParseCmd/ }
	sub cmd { return qw/defaultNew argAlias checkArgs runTest runCmd defaultTestName/ }
	sub sub { return qw/parseEval parseChunks parseMultiline parseOptions parseNormal parseMenu
		parseNum cmdList empty
		call defaultNew subHook
		chooseItems _require useThere spliceArray defaultTest/
	}
	sub obj {qw/defaultNew/}
#plugins-all have isa:base
sub readline { return qw/setup prompt stdin/} #shelli
sub error { return qw/setup sigHandler new setLevel flush stringify_stack/ }
sub dump { return qw/setup dump/}
sub view { return qw/setup view list hash/ }
#others CmdClass

#ISA
	#list,base: easy
	#shelli: shell,lib,readline,CmdClass
	#CmdClass: all libs xcept default + core
	#Sub::_Methods- all sub libs
#leftover
our %left = (
	list=>[qw/list setId setHashDefault convertScalarToHash/, #internal
		qw/setOrMake setObj getObj manyNewScalar callSubAttr/ #todo
	],
	var=>[qw/list/],
	lib=>[qw/list reloadLibs/],
	sub=>[qw/list/],
	cmd=>[qw/list/],
	opt=>[qw/list/],
	obj=>[qw/list/],
	shell=>[
		qw/import/, #hidden
		qw/wrap Dumper/,#other
	],
	dump=>[qw/CreateChainingFilter DumpTree DumpTrees/, #treedumper
		'Dumper', #datadumper
	],
	error=>[qw/stack newwarn newdie/],
	readline=>[qw/addhistory complete completeCmdArgs/], #hidden
	view=>[qw/arrayOfArrays file objAoH objAoH_dt/], #unsure
);
1;
