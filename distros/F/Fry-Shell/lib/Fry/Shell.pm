#!/usr/bin/perl
#declarations
package Fry::Shell;
use strict;
use warnings;

BEGIN {
use Fry::Error;
}
use base 'Fry::Base';
#use Data::Dumper;
#use diagnostics;
#use Fry::Wrap;
our $VERSION = '0.15';
our $Count;
our @ISA;
#for saveArray,varMany
use base 'Fry::ShellI';
#use Data::Dumper;

#core data
	sub _default_data {
		return {
			opts=>{
				menu=>{qw/a m type flag tags counter/,
					action=> sub{ $_[0]->opt->setOptions(parsecmd=>'m');
					$_[0]->opt->preParseCmd(parsecmd=>'m')}},
				parsecmd=>{qw/a p type var default n tags counter/},
				cmdlist=>{qw/a cl type var default cn tags counter/},
				multiline=>{qw/a M type flag tags counter/},
				fh_file=>{qw/a f type var/,
					action=>sub{open(*F::FILE,'>',$_[0]->Var('fh_file')) or die "noo: $!";
					$_[0]->setVar(fh=>'F::FILE'); $_[0]->setFlag(closefh=>1) }},
				page=>{qw/a l type flag/,
					action=>sub { open(*F::PAGER,"| ".  $_[0]->Var('pager'));
					$_[0]->setVar(fh=>'F::PAGER');$_[0]->setFlag(closefh=>1) }},
				skiparg=>{qw/a S type flag noreset 1/},
				autoview=>{qw/a av type flag noreset 1 default 1/},
				method_caller=>{qw/a c type var default 1/}, 
				#detect_subs=>{qw/a ds type flag default 0/},
				#extra_cmds=>{qw/a ec type flag default 0 noreset 1/},
				#action_class=>{qw/a C type var noreset 1/}, 
				viewsub=>{qw/a v type var default 0/}, 
			},
			vars=>{
				defaultlib=>'Fry::Lib::Default',
				cmd_class=>'CmdClass',
				plugin_config=>'Fry::Config::Default',
				plugin_readline=>'Fry::ReadLine::Default',
				plugin_dump=>'Fry::Dump::Default',
				plugin_error=>'Fry::Error',
				plugin_view=>'Fry::View::CLI',
				defaultlibs=>[],
				parsecmd=>'n',
				cmdlist=>'cn',
				fh=>'STDOUT',
				view_options=>{},
				eval_splitter=>',,',
				field_delimiter=>',,',
				fh_file=>'',
				pager=>'less',
				mline_char=>';',
				pipe_char=>'\|\s*',
				prompt=>'!fry shell!:', 
				core_config=>$ENV{HOME}.'/.frycore',
				global_config=>$ENV{HOME}.'/.fryshellrc',
				lines=>[],
				loaded_libs=>[],
				method_caller=>'1',
				quit=>0,
				multiline=>0,
				page=>0,
				skiparg=>0,
				autoview=>1,
				menu=>0,
				closefh=>0,
				skipcmd=>0,
				viewsub=>'0',
				#base_class=>'baseClass',
				#detect_subs=>0,
				#extra_cmds=>0,
				#conf_dir=>$ENV{HOME}."/.shell/conf/",
			},
		}
	}

	sub import {
		my $class = shift;
		no strict 'refs';
		my $caller = (caller())[0];	
		*{"${caller}::shell"} = \&shell;
	}	
#script public methods
	sub new ($%) {
		my ($class,%arg) = @_;
		my %obj = (qw/lib Fry::Lib cmd Fry::Cmd var Fry::Var opt Fry::Opt sub Fry::Sub
		       	obj Fry::Obj type Fry::Type err Fry::Error::List/);

		my $o = bless \%obj,$class;
		#wrap;

		$o->_initCoreClasses(\%arg);
		$o->_setCoreData(\%arg);
		$o->_initISA;
		$o->loadPlugins($o->varMany( qw/plugin_readline plugin_dump
			plugin_view plugin_config plugin_error/));
		$o->_loadDefaultLibs(\%arg);

		$o->lib->setAllObj(%{delete $arg{load_obj}}) if (exists $arg{load_obj});

		#set options to their defaults 
		$o->opt->resetOptions({reset=>1});

		#td: shouldn't allow early_core_vars in this config
		$o->loadFile(delete $arg{global_config}|| $o->Var('global_config'));

		$o->var->setOrMake(%arg);
		
		$o->lib->runLibInits(@{$o->Var('loaded_libs')});

		#?:setCmdlineOpts
		#$o->setOptions(%{delete $arg{options}});

		return $o;
	}
	sub shell (;$) {
		my $o = shift || Fry::Shell->new;

		$o->once(@_);
		while (! $o->Flag('quit')) {
			$o->once;
		}
		$o->postQuit;
	}
	sub once ($@){
		my $o = shift;
		$Count++;
		#i:
		#print "loop $Count\n";

		eval {	
		$o->preLoop;	

		#input: if @_ defined, skips prompting
		my $input= (@_) ? "@_" : $o->getInput;
		return 0 if $input eq "";	

		my @lastargs;
		my @chunks = $o->sub->parseChunks($input);
		#W: print Dumper \@chunks;
		for my $chunk (@chunks) {
			my ($cmd,@args) = $o->parseLine($chunk);
			#@args = (@args,@lastargs); # unless ("@lastargs" ==1);# if (not @args);

			#keep here for autodetected commands
			$cmd = $o->cmd->anyAlias($cmd);
			#$o->cmd->cmdChecks($cmd,@args);
			$o->cmd->argAlias($cmd,\@args);
			if (! $o->Flag('skiparg') && $o->cmd->checkArgs($cmd,@args)) {
				@lastargs = $o->cmd->runCmd($cmd,@args) if (! $o->Flag('skipcmd')); 
			}
			#$o->saveArray(@lastargs) if ($o->Flag('{menu});
			$o->autoView($cmd,@lastargs) if ($o->Flag('autoview'))
		}
		close($o->Var('fh')) or die "can't close file: $! " if
		($o->Flag('closefh')); 

		$o->_resetAll;
		$o->postLoop;
		};
		warn("$@") if ($@);
	}
	sub loadFile ($$) {
		my ($o,$file) = @_;

		if (! -e $file) {
			warn("Didn't load file $file because it doesn't exist");
			return;
		}

		#td: safety until changin a plugin var requires it as well
		$o->sub->_require($o->Var('plugin_config'));

		#my $conf = $o->Config->read($file) || {}; 
		my $conf = $o->Var('plugin_config')->read($file) || {}; 
		#W:debug,dump? 
		warn($conf,0);
		$o->lib->setAllObj(%$conf);
	}
	sub loadPlugins($@) {
		my ($o,@plugins) = @_;

		for (@plugins) {
				$o->sub->_require($_,"$_ require failed:",{qw/warn 1/});
				$_->setup() if ($_->can('setup'));
		}
	}
	sub runCmd ($@) {shift->cmd->runCmd(@_) }
	sub initLibs ($@) { shift->lib->initLibs(@_) }
#private methods
	##new subs
	sub _initISA ($) {
		my $o = shift;
		#actions based on core var
		my $cmdClass = $o->Var('cmd_class');

		#using Fry::Sub::_Methods for now
		#my $subClass = $o->sub;
		#{ no strict 'refs';
		#push(@{"${subClass}::ISA"},$cmdClass);
		#}

		#done to avoid warnings in ISA searches
		eval "package $cmdClass";

		#load script level class into cmdClass
		{ 
			#change caller if this moves
			no strict 'refs';
			push (@{"${cmdClass}::ISA"},'Fry::ShellI');

			my $script_class = (caller(1))[0];
			#to prevent recursive ISA loop ie placing shell_class in its own @ISA
			if ($o->Var('shell_class') ne $script_class) {
				push (@{"${cmdClass}::ISA"},$script_class);
			}
		}
	}
	sub _detectPlugins {
		my $o = shift;
		#detect standard plugins
			eval {require Carp }; 
			if (! $@ ) {$o->setVar(plugin_error=>'Fry::Error::Carp') }
			#$o->setVar(plugin_error=>'Fry::Error::List');

			eval { require Data::Dumper};
			if (! $@ ) {$o->setVar(plugin_dump=>'Fry::Dump::DataDumper') }

			eval { require Term::ReadLine; require Term::ReadLine::Gnu};
			if (! $@ ) {$o->setVar(plugin_readline=>'Fry::ReadLine::Gnu') }
	}
	sub _setCoreData ($\%) {
		my ($o,$arg) = @_;

		#variables loaded in core config
		my @early_core_vars = (qw/core_config cmd_class
		plugin_config plugin_dump plugin_readline plugin_view default_lib
		defaultlibs/);

		#loadDefaultData
		$o->var->defaultNew(shell_class=>ref $o);
		#$o->setFlag(detect_subs=>0);
		$o->lib->loadLib(__PACKAGE__);
		$o->lib->loadLib('Fry::Sub');

		$o->_detectPlugins;

		#load var via file
		$o->loadFile(delete $arg->{core_config} || $o->Var('core_config'));
		
		#load var via script
			my %corehash;
			for my $core (@early_core_vars) {
				$corehash{$core} = delete $arg->{$core} if (exists $arg->{$core})
			}
			$o->setVar(%corehash);
	}
	sub _initCoreClasses ($\%) {
		my ($o,$arg) = @_;
		my %arg = %$arg;
		my @core = (qw/lib cmd var opt sub obj type/);

		#not necessary but here for regression sake
		for (@core) {
			$o->{$_} = delete $arg{$_} if (exists $arg{$_})
		}
		for (@core) {
			my $coreclass = $o->{$_};
			eval "require $coreclass ";
			die "Couldn't require core class '$coreclass': $@ " if $@;
		}

		#set core classes in Fry::Base
		for (@core) {
			Fry::Base->_core($_=>$o->{$_});
		}
	}
	sub _loadDefaultLibs ($\%) {
		my ($o,$arg) = @_;
		$o->lib->loadLibs($o->Var('defaultlib'));
		my $libref = (exists $arg->{libs}) ? delete $arg->{libs} :
			$o->Var('defaultlibs');
		if (ref $libref eq "ARRAY") {
			$o->lib->loadLibs(@$libref)
		}
		else { warn('Loading default libs skipped since it was not an array ref') }

			#$o->loadLibs(@{$o->Var('defaultlibs')});
			#$o->loadLibs(@{delete $arg{libs}}) if (exists $arg{libs});
	}
	##once subs
	#h: should be in View/
	sub autoView ($@) {
		my ($o,$cmd,@args) = @_;
		if ($o->Var('viewsub')) {
			#$o->${\$o->Var('viewsub')}(@args) ;
			$o->sub->subHook(args=>\@args,var=>'viewsub',default=>'empty');
			return;
		}
		#real autoview
		if (@args > 1) {
			my $ref = ref $args[0];
			#if an object
			if ($ref && $ref !~ /^(SCALAR|GLOB|LVALUE|CODE|HASH|ARRAY)$/) { 
				#h,?: allow other cases to be added w/o direct modification
				if ($o->Var('table_class')->isa('Class::DBI')) {
					$o->View->objAoH(\@args,$o->Var('action_columns')) }
			}
			elsif ($ref) { $o->view($o->dumper(\@args)) }
			else { $o->View->list(@args) }
		}
		elsif (@args == 1) {
			my $ref = ref $args[0];
			if ($args[0] =~ /^[01]$/) { 
				#$o->_warn("returned $args[0]\n");
			}	
			elsif ($ref eq "HASH") {
				$o->View->hash($args[0],$o->Var('view_options'));
			}
			elsif ($ref eq "ARRAY") {
				if (ref $args[0][0] eq "ARRAY") { 
					$o->View->arrayOfArrays(@{$args[0]});
				}
				else { $o->View->list(@{$args[0]}) }
			}
			#elsif ($ref =~ /^\w+/ && $ref !~ /^(SCALAR|GLOB|LVALUE|CODE|HASH|ARRAY)$/) { 
				##h: see above
				#if ($o->Var('table_class')->isa('Class::DBI')) { $o->View->objAoH(\@args,$o->Var('printcols')) }
			#}
			elsif (! ref $args[0]) { $o->view($args[0]) }
			else { $o->view($o->dumper($args[0])) }
		}
		#should be warning
		else { $o->view("No arguments returned\n") }
	}
	sub _resetAll ($) {
		my $o = shift;
		$o->opt->resetOptions;
		$o->setVar(fh=>'STDOUT');
		$o->setVar(view_options=>{});
		$o->setFlag(skipcmd=>0);
		$o->setFlag(closefh=>0);
	}
	sub _parseCmd($$) {
		my ($o,$input) = @_;
		$o->sub->subHook(args=>$input,var=>'parsecmd',default=>'normal')
	}
#SUBS/redefinable methods
	sub getInput ($) {
		my $o = shift;

		my $prompt = $o->setPrompt || '';
		my $input = $o->Rline->prompt($prompt);
		if ($o->Flag('multiline')) {
			my $mline_char = $o->Var('mline_char');
		       	while ($input !~ /$mline_char$/) {
				$input .= " " . $o->Rline->prompt($prompt);
			}
			$input =~ s/$mline_char$//;
			$o->sub->parseMultiline(\$input);
		}
		return $input;
	}
	sub parseLine ($$) {
		my ($o,$input) = @_;

		my %opt = $o->sub->parseOptions(\$input);

		$o->opt->setOptions(%opt);
		$o->opt->preParseCmd(%opt);

		#parse args
		return $o->_parseCmd($input);
	}
	sub setPrompt($) {
		my $o = shift;
		my %opt = $o->opt->findSetOptions;
		my $prompt;

		#options
		if (%opt) {
		$prompt .= "[ ";
		#$prompt .= "opt: ";
			while (my ($k,$v) = each %opt) {
				$prompt .= "$k=$v ";
			}
			#$prompt .= ",";
		$prompt .= "] ";
		}

		$prompt .= $o->Var('prompt');
	}
	sub loopDefault ($@) {
		my $o = shift;
		no warnings;	
		#my @arg = ("@_" !~ /^\s*$/) ? @_ : '';
		#print "blah\n" if ($_[0] eq '' && @_ == 1);
		#td: uninitialized warning, can't figure out a defined/nondefined argument
		 $o->view("Yo buddy, your command: '",join(' ',@_),"' isn't valid.\n"); 
	}
	sub preLoop ($) {}	
	sub postLoop ($) {}	
	sub postQuit {
		if (defined $Fry::ReadLine::Gnu::term) {
		$Fry::ReadLine::Gnu::term->WriteHistory($Fry::ReadLine::Gnu::HISTFILE) or
			die "couldn't write history file: $!\n";
		}
	}
1;
__END__

=head1 NAME

Fry::Shell - Flexible shell framework which encourages using loadable libraries of functions.

=head1 SYNOPSIS

	From the commandline: perl -MFry::Shell -eshell

	OR

	In a script:

	package MyShell;
	use Fry::Shell;

	#subs
	sub evalIt {
		my $cls = shift;
		my $code = ($cls->Flag('strict')) ? 'use strict;' : '';
		$code .= "@_";
		eval "$code";
	}
	sub listStations {
		my $cls = shift;
		my @stations = ( {name=>'high energy trance/techno',ip=>'http://64.236.34.196:80/stream/1003'},
			{name=>'macondo salsa',ip=>'http://165.132.105.108:8000'},
			{name=>'new age',ip=>'http://64.236.34.67:80/stream/2004'},
		);
		$cls->saveArray(map{$_->{ip}} @stations);
		return map {$_->{name}} @stations;
	}

	#set shell prompt
	my $prompt = "Clever prompt: ";

	#initialize shell and load a command and an option 
	my $sh = Fry::Shell->new(prompt=>$prompt,
		load_obj=>{ cmds=>{listStations=>{a=>'lS'}},
		opts=>{strict=>{type=>'flag',a=>'n',default=>0}} }
	);

	#begin shell loop
	$sh->shell(@ARGV);

	####end of example, start of other possible methods 

	#run shell once
	$sh->once(@ARGV);

	#loads libraries and runs each library's &_initLib 
	$sh->initLibs(@modules);

	$sh->loadFile($file);

	$sh->loadPlugins($myplugin);

	$sh->runCmd($cmd);

=head1 VERSION	

This document describes version 0.15.

=head1 DESCRIPTION 

Fry::Shell is a simple and flexible way to create a shell.  Unlike most other
light-weight shells, this module facilitates (un)loading libraries of
functions and thus encourages creating shells tailored to several modules.
Although the shell is currently only viewable at the commandline, the
framework is flexible enough to support other views (especially a web one :).
This module is mainly serving(will serve) as the model in an MVC framework.

From a user perspective it helps to know that a shell session consists of mainly four shell
components (whose classes are known as core classes) :
libraries (lib), commands (cmd), options (opt) and variables(var). Commands and options are the same
as in any shell environment: a command mapping to a function and an option changing the behavior of
a command ie changing variables within it or calling functions before the command. Variables
store all the configurable data, including data relating to these commands and options. Libraries
are containers for a related group of these components.

=head2 FEATURES

Here's a quick rundown of Fry::Shell's features:

	- Loading/unloading shell components at runtime.
	- Flexible framework for using shell features via plugins.	 
		You can even set up a bare minimum shell needing no external modules! Currently
		plugins exist for dumping data,readline support,reading shell configurations and
		viewing shell output. 
	- Commands and options can be aliased for minimal typing at the commandline.
	- Commands can have help and usage defined. 
	- Commands can have user-defined argument types. 
		One defines argument types by subroutines or tests that they should pass.
		These tests are then applied to a command's defined argument(s).
		With defined argument types, one can also define autocompletion
		routines for a command's arguments.
	- Options can modify variables.
		Since variables exist for almost every aspect of the shell, options
		can change many core shell functions. A handy example is 'parsecmd'
		which names the current parse subroutine for the current line.
		Changing this var would change how the input after the options is
		parsed.
	- Options can have different behaviors defined including the ability to invoke
		subroutines when called or to maintain a value for a specified amount of iterations. 
	- Default options include 'menu' which numbers output and allows the next command to
	reference them by number.
	- Page output with preferred pager.
	- Multiline mode.
	- Comes with a decent default library,Fry::Lib::Default, to dump,list or
		unload any shell component, run system commands,evaluate perl statements
		and execute methods of autoloaded libraries.

=head2 NOTE

Although this code is decently tested and is apparently unbuggy, I
consider it alpha until a few design issues have been solved. 

Oh yeah, some abbreviations I use often in these modules, especially in naming
subroutines:
cmd- command, lib- library,opt- option,var-variable, gen- general, attr- attribute .


=head1 Introduction

=head2 Setup

The two main ways to start a shell are via &shell and &once.
&once only runs once and useful for a noninteractive environment ie a shell script.
To set up &once :

	my $sh = Fry::Shell->new(prompt=>$prompt);
	$sh->once(@ARGV);

To set up &shell:

	my $sh = Fry::Shell->new(prompt=>$prompt);
	$sh->shell(@ARGV);

=head2 SYNOPSIS Explained

What can you do in your shell? Run any subroutines which you define as commands (or even better
commands defined by libraries). Even if your subroutines are not defined
they can still be executed by typing the subroutine's name. In SYNOPSIS above, &evalIt is such a
subroutine.

Looking at &evalIt's innards, you see that the first argument is $cls which is the class that calls
commands. You also see ' $cls->Flag("strict") ' which is a boolean flag to prepend a 'use strict' to
the evaluated code. Since we defined an option as type flag when initializing the shell, we change
the flag's value when we flip the option from the commandline (ie '-n evalIt $ref = "woah"; $foo =
"ref"; print $$foo').

&listStations is a cool example of the menu option. You'll need to have a music player that can
be executed via a system call, most likely a *nix environment, and that can play shoutcast radio stations (ie xmms).
Without any options, this command simply prints a list of stations. If you use the menu option (ie
'-m lS'), the next input line is parsed differently with numbers being substituted with
corresponding positions from the variable lines. For example,'! xmms 2', would call xmms with the 2nd radio
station in the variable lines. The &saveArray call is what passed the list of ip's to the variable lines.

=head2 Using Options

By default, options come before commands. You can change this behavior by redefining &parseLine.
An option begins with a '-'. You can specify an option's alias or full name. To set
an option's value put a '=' and the option value after it ie '-menu=1'.
If no '=' comes after an option name then the option is treated as a flag and set to 1 (ie the
previous example can be written '-menu').

=head1 LIBRARIES

=head2 Using Libraries

The SYNOPSIS section contains a good example of a shell with a couple of functions. But what happens
if you expand on this and develop several more radio-playing commands and other eval-based commands?
You would probably break them up into separate shells as the shell gets crowded with too many
commands you don't need for a given session. It's at this point that a library comes in handy.

A library is simply a group of related subroutines. At its simplest you can place your functions in
a library, load the library and execute any of its functions. You can load library(ies)
when initializing a shell via the libs attribute :

	Fry::Shell->new(libs=>[qw/:Lib1 Fry::Lib::Lib2/]);

or after initialization via &initLibs:

	$sh->initLibs([qw/:Lib1 Fry::Lib::Lib2/]);

Notice the shorthand ':Lib1' in both examples. This abbrevations is equal to
'Fry::Lib::Lib1' as 'Fry::Lib::' is implied by ':' . This shorthand should work
for any public method that takes libraries.

Even if no libraries are specified, a shell loads the lib Fry::Lib::Default. Its functions enable
you to view and change the core shell components.

=head2 Writing Libraries

Libraries are usually placed under Fry::Lib. Other namespaces will work for now but are only
recommended if you can't get under the Fry::Lib namespace .  To use most shell features, you need to
define shell components in your library. Currently this is only done via &_default_data. However,
since it only returns a hashref, there are many possible ways of storing configuration data ie
databases,xml,dbm, FreezeThaw ...  

A good library example is Fry::Lib::Default.

=head3 SETUP

=head4 &_default_data

&_default_data returns a hashref that can set library attributes
and create any shell component. It consists of any of the following keys: 

	depend(\@): lists other libraries that this library depends on.

	Dependent modules and their configurations are required and read before the current library.
	This parameter accepts the library abbreviation.

	cmds(\%): Defines commands with each id pointing to a defined object. A command object's attributes are explained in Fry::Cmd.

		cmds=>{cmd1=>\%obj1,cmd2=>\%obj2}

	opts(\%): Defines options with each id pointing to a defined object. An option object's attributes are explained in Fry::Opt.
	subs(\%): Defines subroutines with each id pointing to a defined object. A subroutine object's attributes are explained in Fry::Sub.
	objs(\%): Defines objects (of library classes) with each id pointing to a defined object. An object object's attributes are explained in Fry::Obj.
	vars(\%): Defines variables with each id pointing to its value. A variable object's attributes are explained in Fry::Var.

	Note: Since object and variable definitions only set one attribute of the object, it isn't
		possible to define any of their other attributes using &default_data. You could call
		&set in &_initLib.
		
=head4 &_initLib

	This is an optional subroutine that initializes anything within the library after loading
its configuration data. Its explicitly run via &Fry::Lib::runLibInits.

=head3 Writing Library Functions

See L<Fry::ShellI> for the complete list of public shell methods you can use when writing a library's
commands.

A dilemma you mave come across when developing more complex libraries is
portability. Perhaps you want to reuse a library's functions in other applications. Your library
will fail in other applications that don't use shell methods. The obvious solution is
minimizing the use of shell methods throughout your code. To work around the variable and
flag-related methods, define global hashes for Fry::Shell flags and variables. Then write a wrapper
around the command setting the needed variables and flags:

	my (%flag,%var);

	sub commandMammoth {
		my $o = shift; 

		#set variables
		for my $v (qw/Pi fodder goatcheese/) {
			$var{$v} = $o->Var($v)
		}
		#set flags
		for my $f (qw/complex simple fakeit/) {
			$flag{$f} = $o->Flag($f)
		}

		#original command
		#use %flag and %var in mammothAlgorithm
		$o->mammothAlgorithm(@_);
	}

=head1 PLUGINS

Fry::Shell plugins provide flexibility for often used shell features both in functionality and in
module dependency. In making Fry::Shell as portable as possible,  the default plugins do not require
any external modules. If Data::Dumper and Term::ReadLine::Gnu are detected,their plugins are
used. When a plugin is loaded, it is required and then initialized via &setup. Plugins do not
currently have their own shell components like libraries.  There are currently five plugins: View,
ReadLine,Dump,Error and Config.

=head2 View

View handles the view of the shell. Currently only a commandline view (Fry::View::CLI) exists.  A view outputs to the
filehandle specified by the var 'fh'.  A view's methods can be accessed via the accessor View ie
$o->View->list(@output).

Expected methods:

	view(@): General view method called by all other view methods. Outputs to filehandle
		specified by variable fh.
	list(@): Displays an array one value per line. 
	hash(\%arg\%options): Displays a hashref, a key-value pair per line. Also takes
		an options hash which can be passed a quote flag to quote values.
	arrayOfArrays(@): Displays an array of arrays with an array per line separated by the
		variable field_delimiter.

=head2 ReadLine

ReadLine plugins are usually interfaces to Term::ReadLine::* modules. 
These plugins are still in a state of flux and will delve into run-time configurable
autocompletions, assigning keys and configurable commandline history.
Fry::Shell comes with two of these plugins, Fry::ReadLine::Default and Fry::ReadLine::Gnu.

Expected methods:

	stdin($prompt): Reads input and returns it.
	prompt($prompt): Same as &stdin but also adds input to history.


=head2 Dump 		

Dump renders complicated data structures viewable.  A dump's methods can be accessed via the
accessor Dump ie $o->Dump->dump(@stuff).
Fry::Shell comes with three of these plugins, Fry::Dump::Default, Fry::Dump::DataDumper, and
Fry::Dump::TreeDumper.

Expected methods:

	dump($data_structure): Dumps given data structure
		Note that dumping doesn't output the data structure but returns a string
		dump. To print out a dump you could do this:
		$o->view($o->dumper($gargantuanDataStructure)).

=head2 Config(uration)

	Config plugins read configuration data (as if you didn't know). Currently only file
configurations exist. Fry::Shell comes with two of these plugins, Fry::Config::Default and
Fry::Config::YAML.

Expected methods:
	
	read($file): Reads given configuration file and returns a hashref.

=head3 Details 

Configurations are a quick way to define/redefine shell components such as variables and options.
There are two configurations read when initializing the shell ,a core one and a global one. The core
one is read after loading default data. Since the core config is read before you can specify your
preferred config plugin, it will always be read by Fry::Config::Default. See the section Configuring
Core Variables for more detail. The global config is the place to redefine any shell components from loaded libraries.

Configurations can also be loaded at the script level via &loadFile.

	$sh->loadFile('/home/dope/.mylovelyconfig');

If you're unable to set an object's attribute through the config then you can always use a script
method defined by the Fry::ShellI interface. For an example with a shell object $sh:

	$sh->call(lib=>'set',':MyLib',class=>'MyLib');

See the t/testlib/ directory for sample configurations.
	
=head3 Config Data Structure Format

	A configuration defines a hashref similar to a library's &_default_data, no suprise since
they're both defining shell components. It can have any of the same keys as &_default_data except
for depend.

=head3 Configuring Core Variables

When configuring core shell components (defined in this module's &_default data),
you'll usually modify variable values.  Here's a quick overview of core
variables and what they do (note,variables take a scalar value unless
indicated otherwise):

	defaultlib: default library loaded instead of Fry::Lib::Default
	cmd_class: name of class which inherits loaded libraries
	plugin_config: config plugin 
	plugin_readline: readline plugin
	plugin_dump: dump plugin
	plugin_view: view plugin
	plugin_error: error plugin
	defaultlibs(\@): default libraries to load
	parsecmd: current subroutine for parsing commands
	cmdlist: current subroutine for autocompleting commands
	viewsub: current subroutine for viewing subs, is used when it has a nonzero value 
	fh: current filehandle for output
	view_options(\%): contains options to be passed at
	eval_splitter: used by &parseEval to delimit where normal parsing ends and where eval parsing begins
	field_delimiter: delimits fields used in view subroutines
	fh_file: used with fh_file option to specify filename
	pager: name of preferred pager
	mline_char: regular expression indicating end of a multiline command
	pipe_char: regular expression used to delimit piping between command names on commandline
	prompt: shell prompt
	core_config: name of core config file
	global_config:name of global config file
	lines: used by the menu option
	closefh: used by options to keep track of open filehandles
	quit: flag which indicates to &shell to quit when true
	skipcmd: flag which skips executing a command when true
	autoview: option variable, see section Useful Options
	skiparg: " "
	menu: " "
	method_caller: " "
	multiline: " "
	cmdlist: " "
	page: " "
	loaded_libs(\@): currently loaded libraries

=head2 Error

See L<Fry::Error> for details.

=head1 Miscellaneous

=head2 Creating Shell Components

When considering where and how to create/recreate shell component values, you should know how and in
what order they are loaded. For now, the creation of shell component objects at any of these stages
is ultimately done by &Fry::List::setOrMake.  This method creates an object if it doesn't exist. If
it does exist, it sets the object with its value.  The shell components are loaded in the following
order: config of Fry::Shell library, core config, config of all other libraries, global
config,load_obj option of &new and options setting variable values.

=head2 Useful Options

Fry::Shell comes with a few handy options (defined in &_default_data): 

	parsecmd: sets the current parsing subroutine, handy when needing to pass a command a
		complex data structure and want to use your own parsing syntax
	cmdlist: sets the current subroutine for autocompleting commands
	menu: sets parsecmd to parseMenu thus putting the user in a menu mode
		where each output line is aliased to a number for the following
		command, explained in SYNOPSIS Explained section
	fh_file: sends command's output to specified file name
	page: sends command's output to preferred pager
	autoview: flag which turns on/off autoview and a command's subroutine outputs for itself
	skiparg: flag which turns on/off skipping command argument checking
	multiline: begins multiline mode
	method_caller: Controls class or object that calls a method when calling a command. Value of
		1, calls method with CmdClass. See &Fry::Cmd::runCmd for details.

=head2 Subroutine Hooks

Subroutine hooks allows runtime choosing of which subroutine to call at its location. Every choice
is a Fry::Sub object defined in a library's config. You can choose your subroutine by setting the
variable containg the hook's subroutine id, which is only done for now by its option.

=head3 Parsers

A parser sub hook parses the input after options. It receives the input as a string and returns the
command and its arguments in an array.

	sub parseMyWay {
		my ($o,$input) = @_;
		return (split(/ |/,$input))
	}

Available parse subroutines are parse* methods in Fry::Sub. This hook's variable and option is
parsecmd.

=head3 Command Completion

This sub hook returns the list of commands when autocompleting commands. This hook's variable and
option is cmdlist.

=head3  View Subroutines

This sub hook displays output in &autoView when set to a nonzero value. This hook's variable and
option is viewsub.

=head2 Multiline Mode

To start a multiline session you flip the multiline option (ie '-M').
The multiline mode lasts as long as it doesn't encounter the variable
mline_char, default being ';'. Multiple lines of input are joined by a whitespace.

=head2 Using Autoloaded Libraries

This is a sweeet feature implented via &classAct and &objectAct that allow
you to load a normal module and act on its object and/or class methods.
See L<Fry::Lib::Default> for details.

=head2 Argument Checking

By default, any command with an arg attribute has its arguments checked. See <Fry::Cmd> for details.

=head1 PUBLIC METHODS

Shell scripting methods that are recommended for scripting Fry::Shell while methods that
are encouraged to be subclassed.

A method's arguments are described via data structure symbols @,$,% and a descriptive
name. Optional arguments are described in perl regular expression format.

 Shell scripting methods
	new(%options): Creates a shell object and creates its shell components ie load
		libraries and initialize core data. It can take any variable
		name and value pairs as well as the following keys:
		
			libs(\@): Loads libraries after having loaded all libraries specified in
				configs.
			core_config($): core config file
			load_obj(\%): Creates shell components via &setAllObj,see it for data
				structure format 
			global_config($): global config file

		Note: For further description of core variables look at the above section
		Configure Core Variables. You can pass a core variable as an option just like any
		other variable.

	shell(@input?): Starts the shell's main loop. Optional argument is input to first loop iteration.
	once(@input?): One iteration of loop. If optional argument isn't given, prompts for input.
	runCmd(@args): Executes given command and arguments.
	initLibs(@libs): Loads libraries and calls library initialization subroutines.
	loadFile($file): Reads config file via config plugin.
	loadPlugins(@vars): Loads plugins by their variable name ie plugin_config.

 Subclassable methods
	preLoop(): This subroutine executes at the beginning of every shell loop.
	postLoop(): This subroutine executes at the end of every shell loop.
	loopDefault($cmd,@arg): This subroutine executes if no valid command is given. By default this sub
		returns an error message of an invalid entry. It is passed an array containg the command and
		its arguments.
	setPrompt(): Returns shell prompt to be displayed
	parseLine($input): Parses input into option and command sections and carries out actions
		associated with these shell components. Returns an array containg the command first and the
		arguments afterwards.
	autoView($cmd,@cmd_output): Handles displaying a command's output when the autoview flag is set.
		This subroutine handles cases first by the variable viewsub, then by number of arguments and then by type of data.
		This subroutine may move over soon to Fry::View::CLI.
	getInput(): Returns input from one shell iteration. The default way to get input is via a
		ReadLine plugin's &prompt. Should be subclassed if a Readline plugin for &prompt can't be made.
	postQuit(): Called after user has quit the shell via &shell. Useful for saving state of
		shell ie command history.

=head1 MODULE OUTLINE

	An outline of all modules that come with Fry::Shell

	Core classes
		Fry::Var
		Fry::Cmd
		Fry::Opt
		Fry::Obj
		Fry::Lib
		Fry::Type
		Fry::Sub

	Libraries
		Fry::Lib::Default
		Fry::Lib::DBI
		Fry::Lib::Inspector

	Plugins
		Fry::Config::YAML
		Fry::Config::Default
		Fry::Error
		Fry::Error::Carp
		Fry::Dump::DataDumper
		Fry::Dump::TreeDumper
		Fry::Dump::Default
		Fry::ReadLine::Default
		Fry::ReadLine::Gnu
		Fry::View::CLI

	Other modules
		Fry::List
		Fry::Base
		Fry::Shell
		Fry::ShellI

=head1 SEE ALSO
	
See Fry::Lib::* for available libraries.

For similar light shells, see L<Term::Shell>,L<Shell::Base> and
L<Term::GDBUI>.

For big-mama shells look at L<Zoidberg> and L<psh>.

=head1 CODE COVERAGE

I use Devel::Cover to test code coverage. All modules have a total code coverage of at least 70%. I
aim to cover more as the API stabilizes.

=head1 TO DO

There are a jazillion things I would like to do with this module.
Here are the high priority items:

	priority 1
		autoload modules
			develop framework around &objectAct
			be able to load:
				OO methods ie List::Compare
				class methods ie Class::DBI 
				functions ie Date::Manip
		view plugin: cgi view 
		develop configuration format for autoloaded modules and plugins
			menu or option-based choosing of a class's global settings
			menu or option-based choosing of a module's functions
		error framework
			logging
			error tracking with Fry::List
		readline and Fry::Type
			autocomplete arguments of commands
			chain commands: autocomplete cmds based on output type of last command
			map commands to keys
	priority 2
		move &autoView and convert it to a for loop of Fry::Sub objects
		clean tests

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.

=head1 BUGS

Although I've written up decent tests there are some combinations of
configurations I have not tried. If you see any bugs tell me so I can make
this module rock solid.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.
