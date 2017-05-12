package Fry::Lib::Default;
use strict;
	sub _default_data {
		return {
			cmds=>{
				objectAct=>{a=>'o',u=>'$obj $libcmd @args',
					d=>'Executes given object\'s method with its arguments',
					cmpl=>\&cmpl_objact,
				},
				classAct=>{a=>'c',u=>'$lib $method @args',cmpl=>\&cmpl_classact,
					d=>'Executes class method with its arguments'},
				printVarObj=>{a=>'\pv',arg=>'@var', d=>'Dumps variable objects'},
				printCmdObj=>{a=>'\pc',arg=>'@cmd', d=>'Dumps command objects'},
				printOptObj=>{a=>'\po',arg=>'@opt', d=>'Dumps option objects' },
				printLibObj=>{a=>'\pl',arg=>'@lib', d=>'Dumps library objects'},
				printSubObj=>{a=>'\ps',arg=>'@sub', d=>'Dumps sub objects'},
				printObjObj=>{a=>'\pO',arg=>'@obj', d=>'Dumps obj objects'},
				printGeneralAttr=>{a=>'\pg',u=>'$sh_comp$attr@ids',
					d=>'Dumps an attribute of specified shell component'},
				#printErrObj=>{a=>'\pe',arg=>'@obj', d=>'Dumps error objects'},
				#listErrs=>
				#{d=>'List errors',u=>'',a=>'\le'},
				listVars=>
					{d=>'List variables',u=>'',a=>'\lv'},
				listOptions=> {d=>'List loaded options',
					u=>'',a=>'\lo'},
				listSubs=>{d=>'List subs',u=>'',a=>'\ls'},
				listObjs=>{d=>'List objs',u=>'',a=>'\lO'},
				#listErrors=>{d=>'List errors',u=>'',a=>'\le'}, 
				listCmds=>
					{d=>'List loaded commands',
					u=>'',a=>'\lc',} ,
				listLibs=>{a=>'\ll',d=>'List loaded libraries'},	
				varValue=>{a=>'\vv',d=>'Prints variable values',arg=>'@var'}, 
				helpUsage=>{d=>'Prints usage of function(s)',
					a=>'h',arg=>'@cmd'},
				helpDescription=>
					{d=>'Prints brief description of function(s)',
					,a=>'\h',arg=>'@cmd'},
				quit=>{d=>'Quits shell', u=>'',a=>'q'},
				findVar=>{a=>'\fv',d=>'Finds variables by attribute'},
				findOpt=>{a=>'\fo',d=>'Finds options by attribute'},
				findCmd=>{a=>'\fc',d=>'Finds commands by attribute'},
				findSub=>{a=>'\fs',d=>'Finds subs by attribute'},
				findLib=>{a=>'\fl',d=>'Finds libraries by attribute'},
				findObj=>{a=>'\fO',d=>'Finds objects by attribute'},
				unloadLib=>{a=>'\ul',arg=>'@lib',d=>'Unloads libraries'},
				unloadSub=>{a=>'\us',arg=>'@lib',d=>'Unloads subs'},
				unloadCmd=>{a=>'\uc',arg=>'@cmd',d=>'Unloads commands'},
				unloadOpt=>{a=>'\uo',arg=>'@opt',d=>'Unloads options'},
				unloadVar=>{a=>'\uv',arg=>'@var',d=>'Unloads variables'},
				unloadObj=>{a=>'\uO',arg=>'@obj',d=>'Unloads objects'},
				perlExe=>
					{d=>'Executes arguments as perl code with eval',
					u=>'$perl_code',a=>'\p'},
				initLibs=>{a=>'\lL',d=>'Loads and initializes libraries',u=>'@lib'},
				sysExe=>{a=>'!',d=>'Executes system calls via system()',u=>'$sysCmd'},
				reloadLibs=>{a=>'\rl',d=>'reload libraries',u=>'@libs'},
				#setVar=>{a=>'\sV',arg=>'%var',d=>'sets},
			},
			vars=>{
			},
			subs=>{}
			#special=>{setMany=>[qw/objectAct/]}
		}
	}
	#h: multiple aliases for help
	*help = \&helpDescription;
#core actions
	##list
	sub listErrs ($) { shift->listGen('err') }
	sub listObjs ($) { shift->listGen('obj') }
	sub listSubs ($) { shift->listGen('sub') }
	sub listLibs ($) { shift->listGen('lib') }
	sub listVars ($) { shift->listGen('var') }
	sub listOptions ($) { shift->listGen('opt') }
	sub listCmds  ($) { shift->listGen('cmd') }
	sub listGen ($$) {
		my ($cls,$core) = @_;
		my @list = sort $cls->List($core);
		$cls->saveArray(@list) if ($cls->Flag('menu'));
		#$cls->View->list(@list);
		return @list;
	}
	sub findVar ($$$$) { shift->findIdGen('var',@_) }
	sub findOpt ($$$$) { shift->findIdGen('opt',@_) }
	sub findCmd ($$$$) { shift->findIdGen('cmd',@_) }
	sub findSub ($$$$) { shift->findIdGen('sub',@_) }
	sub findLib ($$$$) { shift->findIdGen('lib',@_) }
	sub findObj ($$$$) { shift->findIdGen('obj',@_) }
	sub findIdGen ($$$$$) {
		my ($cls,$core,$attr,$searchtype,$value) = @_;
		do{ warn('Not enough arguments');return ()} if (@_ < 5);
		my @found_ids = $cls->$core->findIds($attr,$searchtype,$value); 
		$cls->printGeneralObj($core,@found_ids);
	}
	##print Obj
	sub printErrObj ($@) { shift->printGeneralObj('err',@_) }
	sub printObjObj ($@) { shift->printGeneralObj('obj',@_) }
	sub printSubObj ($@) { shift->printGeneralObj('sub',@_) }
	sub printLibObj ($@) { shift->printGeneralObj('lib',@_) }
	sub printVarObj ($@) { shift->printGeneralObj('var',@_) }
	sub printOptObj ($@) { shift->printGeneralObj('opt',@_) }
	sub printCmdObj ($@) { shift->printGeneralObj('cmd',@_) }
	sub printGeneralObj ($$@) {
		my ($cls,$core,@ids) = @_;
		my $output;
		#local $Data::Dumper::Deparse=1;
		local $Data::Dumper::Terse = 1;

		@ids = sort $cls->List($core) if (scalar(@ids) == 0);
		#my $sub = $core."Obj"; 
		for my $id (@ids) {
			$output->{$id} = $cls->dumper($cls->$core->Obj($id));
		}
		#$cls->View->hash($output,{quote=>1,sort=>1});
		$cls->setVar(view_options=>{quote=>1,sort=>1});
		return $output;
	}
	##print attribute
	sub printGeneralAttr ($$$@) {
		my ($cls,$core,$attr,@ids) = @_;
		if (@_ < 3) { warn('Not enough arguments'); return 0}
		my ($output,$quote);
		local $Data::Dumper::Terse = 1;
		no strict 'refs';

		@ids = sort $cls->List($core) if (scalar(@ids) == 0);
		for my $id (@ids) {
			if ($core eq "var") {
				$output->{$id} = $cls->dumper($cls->$core->get($id,$attr));
			}
			else {
				$output->{$id} = $cls->$core->get($id,$attr);
				$quote =1;
			}
		}
		$cls->setVar(view_options=>{quote=>$quote,sort=>1});
		return $output;
		#$cls->View->hash($output,{quote=>$quote,sort=>1});
	}
	sub helpDescription($@) { shift->printGeneralAttr('cmd','d',@_) }
	sub varValue($@) { shift->printGeneralAttr('var','value',@_) }
	sub helpUsage ($@) {
		my ($cls,@cmds) = @_;
		#$cls->view("Note: wrap <> around optional chunks\n\n");
		$cls->printGeneralAttr('cmd','u',@cmds);
	}
	##unload
	sub unloadLib ($@) { shift->lib->unloadLib(@_) }
	sub unloadCmd ($@) { shift->call('cmd','unloadObj',@_) }
	sub unloadSub ($@) { shift->call('sub','unloadObj',@_) }
	sub unloadOpt ($@) { shift->call('opt','unloadObj',@_) }
	sub unloadVar ($@) { shift->call('var','unloadObj',@_) }
	sub unloadObj ($@) { shift->call('obj','unloadObj',@_) }
#other
	#sub listErrors ($) {
		#my $cls = shift;
		#$cls->view($cls->Error->stringify_stack);
	#}
	sub reloadLibs ($@) { shift->lib->reloadLibs(@_) }
	sub initLibs ($@) { shift->lib->initLibs(@_) }
	sub sysExe ($@) {
		shift;
		system(@_);
	}
	sub perlExe ($@) { 
		#?: how does it set Data::Dumper::
		my $cls = shift;	
		my $code = "@_";
		eval "$code";
		#eval "@_";
	}
	sub quit ($) { $_[0]->setFlag(quit=>1) }
	sub objectAct ($$@) {
		my ($cls,$obj,$sub,@args) = @_;

		my @output = $cls->obj->get($obj,'obj')->$sub(@args);
		return @output;
	}
	sub classAct ($$$@) {
		#?:don't even need lib
		my ($o,$lib,$sub,@args) = @_;
		$lib = ($o->lib->fullName($lib))[0];

		my @output = $o->lib->get($lib,'class')->$sub(@args);
		#$o->view($o->dumper(\@output));
		return @output;
	}
	#maybe
	sub setCmdOpts($$) {
		my ($o,$cmd) = @_;
		if ($o->cmdObj($cmd)) {
			$o->view("Available options are:\n");
			$o->View->list(@{$o->cmdObj($cmd)->{opts}});
		}
	}
	#internals
	#test subs
	sub t_gen {
		my ($cls,$core,@ids) = @_;
		for (@ids) {
			#w: will break if obj accessors change
			return 0 if (not $cls->$core->objExists($_))
		}
		return 1
	}
	sub t_sub { shift->t_gen('cmd',@_); }
	sub t_cmd { shift->t_gen('cmd',@_); }
	sub t_opt { shift->t_gen('opt',@_); }
	sub t_var { shift->t_gen('var',@_); }
	sub t_lib { my $cls = shift; $cls->t_gen('lib',$cls->lib->fullName(@_)); }
	#sub t_libcmd { return 1 }
	#cmpl subs
	#was used with objectAct
	#sub cmpl_libcmd { my $cls = shift; return @{$cls->call(lib=>'Obj',$cls->Var('autolib'))->{cmds}} }
	sub cmpl_cmd { shift->List('cmd') }
	sub cmpl_opt { shift->List('opt') }
	sub cmpl_lib { shift->List('lib') }
	sub cmpl_var { shift->List('var') }
	sub cmpl_sub { shift->List('sub') }
	sub cmpl_objact { my $cls = shift; my ($obj) = $_[0] =~ /(\w+)/; 
		#print "\n$obj\n";
		if ($cls->obj->objExists($obj) && $cls->obj->attrExists($obj,'methods')) {
			return @{$cls->obj->get($obj,'methods') }
		}
		else { return ''}
       	}
	sub cmpl_classact { 
		my ($cls,$lib) = @_;
		$lib =~ s/\s*$//g;
		$lib = $cls->lib->fullName($lib);

		if ($cls->lib->objExists($lib) && $cls->lib->attrExists($lib,'methods')) {
			return @{$cls->lib->get($lib,'methods') }
		}
		else { return ''}
       	}
1;	

__END__	

=head1 NAME

Fry::Lib::Default -  Default library loaded by Fry::Shell

=head1 DESCRIPTION 

This library contains the basic commands to manipulate shell components: listing them,
dumping (printing) their objects,unloading them, loading them via a library and a few
general-purpose functions. Currently the commands are documented by their above definitions in
&_default_data ie their 'u' attribute describes what input they take and their 'd' attribute describes
them.

=head1 Autoloaded Libraries

There are currently two ways of using an autoloaded library via a library's class methods or a library's object
methods. These two ways use the commands classAct and objectAct respectively. Before using either
command you must load an autoload library via &initLibs.

=head2 &classAct

The only current autoload library for &classAct is Fry::Lib::Inspector. After
installing Class::Inspector, start a shell session and load this library (ie 'initLibs :Inspector').
You can now execute the class methods of Class::Inspector! Looking at the 'u' (usage) attribute of
classAct above you see that the first argument is a library followed by a method and then its
arguments. For example you could run the &resolved_filename method of Class::Inspector ie
'classAct :Inspector resolved_filename Class::Inspector'. Note that I don't have to
change the parsing of this line as the arguments neatly split on whitespaces (the default parser).
Also, the :$basename is a shorthand for libraries under Fry::Lib space.

=head2 &objectAct

We'll use Fry::Lib::DBI as our sample library. Installing DBI and load the library as before ie
'initLibs :DBI'. To establish your own database connection you need to define your own variables
for user, password (pwd),dbms (db) and database (dbname) in a separate config file (or just change
them in the module in &_initLib for a quick hack ;)). The former requires using &loadFile $filename
at the commandline. You can now act on methods of a basic database handle. The usage for &objectAct
indicates to pass the object name followed by its method and its arguments ie 'objectAct dbh tables' which
will print out all the database's tables. A more advanced command could be "-p=e objectAct dbh
selectall_arrayref,,'select * from perlfn' ". This commandline changes the parse subroutine to
&parseEval and executes an sql query on the perlfn table. You should have gotten a list of records.
You now have a simple DBI shell without having hardwritten any perl code!


=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
