package Fry::Lib;
use strict;
use base 'Fry::List';
use base 'Fry::Base';
my $list = {};

sub list { return $list }
#shell interface
	sub runLibInits ($@) {
		my ($cls,@lib) = @_;
		no strict 'refs';

		for my $l (@lib) {
			$cls->sub->_require($l);
			my $sub = "$l\::_initLib";
			&$sub($cls->Caller) if (defined &$sub);
			#shell + sub were crawling up ISA
			#$cls->Caller->$sub() if ($l->can('_initLib'));
		}
	}
	sub fullName {
		my($cls,@libs) = @_;
		@libs =  map { s/^/Fry::Lib:/ if (/^:/); $_ } @libs;
		return wantarray ? @libs : $libs[0];
	}
	#loadLibs
	sub _getLibData ($$) {
		my ($cls,$module) = @_;
		#done for &_default_data
		#?: return undef if module require fails
		eval "require $module";
		warn($@) if $@;
		#$o->_require($module,{'warn'=>1});
		
		#if ($cls->Flag('detect_subs')) {
			#return {lib=>{ cmds=>[$cls->sub->chooseItems($cls->sub->classMethods($module))]},
			#type=>'function',class=>$module} 
		#}
		if ($module->can('_default_data')) {
			return $module->_default_data 
		}
	}
	sub _readLibObj ($$) {
		my ($cls,$dt) = @_;
		my ($varlist,$optlist,$cmdlist,$sublist,$objlist) = ([],[],[],[],[]);
			
			$varlist = 	[keys %{$dt->{vars}}] if (exists $dt->{vars});
			$optlist = 	[keys %{$dt->{opts}}] if (exists $dt->{opts});
			$cmdlist = 	[keys %{$dt->{cmds}}] if (exists $dt->{cmds});
			$sublist = 	[keys %{$dt->{subs}}] if (exists $dt->{subs});
			$objlist = 	[keys %{$dt->{objs}}] if (exists $dt->{objs});

		#add to Lib Obj directly via {lib}
		if (exists $dt->{lib}) {
			#push(@$varlist,@{$dt->{lib}{vars}}) if (exists $dt->{lib}{vars});
			#push(@$optlist,@{$dt->{lib}{opts}}) if (exists $dt->{lib}{opts});
			push(@$cmdlist,@{$dt->{lib}{cmds}}) if (exists $dt->{lib}{cmds});
		}
		return ($varlist,$optlist,$cmdlist,$sublist,$objlist);
	}
	sub setAllObj ($%) {
		my ($cls,%data) = @_;
		#for my $core ($cls->listCore) {
		#	$cls->$core->setOrMake
		$cls->var->setOrMake(%{$data{vars}}) if (exists $data{vars});
		$cls->opt->setOrMake(%{$data{opts}}) if (exists $data{opts});
		$cls->cmd->setOrMake(%{$data{cmds}}) if (exists $data{cmds});
		$cls->sub->setOrMake(%{$data{subs}}) if (exists $data{subs});
		$cls->obj->setOrMake(%{$data{objs}}) if (exists $data{objs});
	}
	sub loadLib ($$) {
		my ($cls,$module) = @_;
		($module) = $cls->fullName($module);

		my $dt = $cls->_getLibData($module);

		#e: empty dt returned
		return 0 if (ref($dt) ne "HASH");

		$dt->{module} = $module;

		$cls->_loadDependencies($dt);
		$cls->setAllObj(%$dt);
		$cls->sub->_require($module);
		$cls->_setLibISA($module);
		
		my ($varlist,$optlist,$cmdlist,$sublist,$objlist) = $cls->_readLibObj($dt); 

		#extract other attributes
		delete @{$dt}{qw/vars cmds opts lib subs objs module/};

		#setLibObj
			$cls->manyNew($module=>{cmds=>$cmdlist,opts=>$optlist,vars=>$varlist,subs=>$sublist,objs=>$objlist,%$dt});

			#post objectCreationTweaking for function libs
			#if (exists $cls->Obj($module)->{type} && $cls->Obj($module)->{type} eq "function") {
				#no strict 'refs';
				#for my $cmd (@{$cls->Obj($module)->{cmds}}) {
					#my $class =  $cls->Obj($module)->{class} || next;
					#*{"${module}::${cmd}"} = sub { shift; return &{"${class}::${cmd}"}(@_) }
				#}
			#}

		$cls->var->pushArray('loaded_libs','value',$module);
	}
	sub _setLibISA {
		my ($cls,$module) = @_;
		no strict 'refs';
		my $cmd_class = $cls->Var('cmd_class');	
		#td: cmd_class isn't in @{$module::ISA}
		push(@{"$cmd_class\::ISA"},$module) unless ($module =~ /^(Fry::Shell|Fry::Sub)$/);

		push(@{"$Fry::Sub::LibClass\::ISA"},$module) unless ($module =~ /^(Fry::Shell|Fry::Sub)$/);
	}
	sub unloadLib ($@) {
		my ($cls,@libs) = @_;
		@libs = $cls->fullName(@libs);

		for my $l (@libs) {
			$cls->cmd->unloadObj(@{$cls->Obj($l)->{cmds}});
			$cls->opt->unloadObj(@{$cls->Obj($l)->{opts}});
			$cls->var->unloadObj(@{$cls->Obj($l)->{vars}});
			$cls->sub->unloadObj(@{$cls->Obj($l)->{subs}});
			$cls->obj->unloadObj(@{$cls->Obj($l)->{objs}});
			$cls->lib->unloadObj($l);
			$cls->_removeLibISA($l);
		}
	}
	sub _removeLibISA {
		my ($cls,$lib) = @_;
		no strict 'refs';

		#regular-CmdClass
		my $cmdClass = $cls->Caller;
		$cls->sub->spliceArray(\@{"$cmdClass\::ISA"},$lib);

		#sub
		$cls->sub->spliceArray(\@{"$Fry::Sub::LibClass\::ISA"},$lib);
	}
	sub _loadDependencies ($$) {
		my ($cls,$dt) = @_;	
		if (exists ($dt->{depend})) {
			my @libs = @{$dt->{depend}};
			$cls->checkAndLoadLibs(@libs);
		}
	}
	sub checkAndLoadLibs {
		my ($cls,@a_libs) = @_;
		for my $lib (@a_libs) {
			if (! $cls->libsLoaded($lib)) {
				$cls->loadLib($lib)
			}
		}
		return 1;
	}
	sub requireLibraries {
		my ($cls,@libs) = @_;

		$cls->checkAndLoadLibs(@libs) && 
		$cls->view("Loaded libraries: ",join(',',@libs),"\n");
	}
	sub libsLoaded {
		my ($cls,@libs) = @_;
		@libs = $cls->fullName(@libs);
		for my $lib (@libs) {
			return 0 if (! grep(/^$lib$/,$cls->listIds) > 0);
		}
		return 1;
	}
	sub reloadLibs ($@) {
		my ($cls,@libs) = @_;
		$cls->unloadLib(@libs);
		for ($cls->fullName(@libs)) {
			eval "use again '$_'"; die $@ if $@;
		}
		$cls->initLibs(@libs);
	}	
	sub loadLibs ($@) {
		my ($cls,@modules) = @_;
		for (@modules) { $cls->loadLib($_) }
	}
	sub initLibs ($@) {
		my ($cls,@modules) = @_;
		@modules = $cls->fullName(@modules);
		$cls->loadLibs(@modules);
		$cls->runLibInits(@modules);
	}
1;
__END__	
	sub allCmds {
		my $cls = shift;
		my @cmds;
		for my $lib ($cls->listIds) {
			push(@cmds,@{$cls->obj($lib)->{cmds}});
		}
		return @cmds;
	}


=head1 NAME

Fry::Lib - Class for shell libraries. 

=head1 DESCRIPTION 

A Fry::Lib object has the following attributes:

	Attributes with a '*' next to them are always defined.

	*id($): Unique id which is full name of module.
	*vars(\@): Contains ids of variables in its library.
	*opts(\@): Contains ids of options in its library.
	*cmds(\@): Contains ids of commmands in its library.
	class($): Class autoloaded by library.
	depend(\@): Modules which library depends on.

=head1 PUBLIC METHODS

	runLibInits(@libs): Calls &_initLib of libraries if they exist.
	fullName(@libs): Converts aliased libraries that begin with ':' to their full path in Fry::Lib.
	setAllObj(%data): Creates core class objects defined by a data hash whose
		structure is the same as used to define &_default_data in a library
	loadLib($lib): Creates library object and loads library into shell's
		executable path.
	loadLibs(@libs):  loads libraries
	unloadLib(@libs): unloads libraries
	reloadLibs(@libs): reloads libraries, uses again.pm
	checkAndLoadLibs(@libs): loads libraries if not loaded
	libsLoaded(@libs): returns boolean indicating if libraries are loaded
	requireLibraries(@libs): commandline version of &checkAndLoadLib
	initLibs(@libs): loads libraries and runs &runLibInits on them

=head1 SEE ALSO

	LIBRARIES section of Fry::Shell.

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
