package Fry::Cmd;
use strict;
use base 'Fry::List';
use base 'Fry::Base';
my $list = {};

sub list { return $list }

	sub defaultNew {
		my ($cls,%arg) = @_;
		$cls->manyNew(%arg);
		for my $cmd (keys %arg) {
			#sub default
			#make sure call is done by obj and not shell class
			$cls->_obj($cmd)->{_sub} = sub {$cls->Caller->$cmd(@_) }
				if (! exists $cls->_obj($cmd)->{_sub});

			#usage default		
			if (exists $cls->_obj($cmd)->{arg} && ! exists $cls->_obj($cmd)->{u}) {
				#$o->{cmd}->_obj($cmd)->{u} ||= $o->{cmd}->_obj($cmd)->{arg}
				my $arg = $cls->get($cmd,'arg') || return 0;
				$arg =~ s/cmd/command/;
				$arg =~ s/lib/library/;
				$arg =~ s/opt/option/;
				$arg =~ s/var/variable/;
				$cls->_obj($cmd)->{u} = $arg;
			}
		}
	}
	sub argAlias ($$$) {
		my ($cls,$cmd,$args) = @_;

		my $alias_sub = $cls->get($cmd,'aa') || return 0;
		if (ref $alias_sub eq "CODE") { @$args = $alias_sub->($cls->sub,@$args); }
		else { @$args = $cls->Caller->$alias_sub(@$args) }

		#td?: @$args = $cls->Sub($alias_sub,@$args);
	}
	sub _extractArgs {
		my ($cls,$arg) = @_;
		(ref $arg eq "ARRAY") ?  @$arg : split(/,/,$arg);
	}
	sub checkArgs ($$@) {
		my ($cls,$cmd,@args) = @_;

		my $arg = $cls->get($cmd,'arg') || return 1;
		my @argtypes = $cls->_extractArgs($arg);
		for my $arg (@argtypes) {
			my ($datatype,$usertype) = split(//,$arg,2);
			#print "$datatype,$usertype\n";
			my @testarg;
			if ($datatype eq "\$") {@testarg = shift @args}
			elsif ($datatype eq "@") { @testarg = @args; }
			elsif ($datatype eq "%"){ @testarg = keys %{{@args}} }

			my $testsub;
			if ($cls->type->attrExists($usertype,'t')) {
				$testsub = $cls->type->get($usertype,'t');
			}
			else {
				$testsub = $cls->defaultTestName($usertype);
			}

			if (! $cls->sub->can($testsub)) {
				warn("No test sub '$testsub' found, running defaultTest",2);
				return 0 if (! $cls->runTest('defaultTest',@testarg));
			}
			#test case defined
			else { return 0 if (! $cls->runTest($testsub,@testarg))  }
			return 1
		}
	}
	sub defaultTestName { return "t_$_[1]" }
	sub runTest ($$) {
		my ($cls,$test,@args) = @_;

		if (! $cls->Sub($test,@args)) {
		#if (! $cls->callSubAttr(id=>$test,args=>\@args)) 
			warn(join(' ',@args).": invalid type(s)\n");
			$cls->setFlag(skipcmd=>1);
			return 0
		}
		return 1;
	}
	sub runCmd ($$@) {
		my ($cls,$a_cmd,@args) = @_;

		my $cmd = $cls->anyAlias($a_cmd);
		#print "c: $cmd,a: @args\n";

		if ($cls->attrExists($cmd,'_sub')) {
			return $cls->Obj($cmd)->{_sub}->(@args);
		}

		#autodetect
		if ($cls->Var('method_caller') == 1) {
			if ($cls->Caller->can($cmd)) { 
				return $cls->Caller->$cmd(@args) 
			}
			else { warn ("Command '$cmd' not in Caller's path",1) }
		}
		else {
			if ($cls->Var('method_caller')->can($cmd)) {
				return $cls->Var('method_caller')->$cmd(@args)
			}
			else { my $caller = $cls->Var('method_caller');
			       	warn ("Command '$cmd' not in $caller\'s path",1) 
			}
		}

		#elsif ($cls->lib->find(cmds=>$cmd,type=>'function')) { }
		return $cls->sh->loopDefault($cmd,@args);
	}
1;

__END__	

#OLD CODE
	sub cmdChecks ($$@) {
		my ($cls,$cmd,@args) = @_;
		$cmd = $cls->anyAlias($cmd);
		if ($cls->objExists($cmd) && exists $cls->obj($cmd)->{req}) {
			my $module ="";
			for $module (@{$cls->_obj($cmd)->{req}}) {
				eval "require $module";
				if ($@) {
					$cls->setFlag('skipcmd'=>1);
					#warning issue
					#$o->_warn("Required module $module not found. Skipping command\n").
					return ;
				}	
			}	
		}
	}

=head1 NAME

Fry::Cmd - Class for shell commands.

=head1 DESCRIPTION

A command object has the following attributes:

	Attributes with a '*' next to them are always defined.

	*id($): Unique id which is usually the name of subroutine associated with it.
	a($): Command alias.
	d($): Description help for command.
	u($): Usage help for command.
	*_sub(\&): Coderef which points to subroutine to execute when command is
		run. If not explicitly set,it's set to a default of 'sub {$o->$cmd(@_) }'
		where $cmd is the command's id.
	arg($): Use this attribute if you want to validate the command's
		arguments. Describe expected input type with a data structure symbol and
		name. See Argument Checking below.

=head1 Argument Checking

To validate your command's arguments you define an arg attribute. This attribute describes the
expected input with a symbol and a unique name for argument type. Currently valid symbols are $,%,@
to indicate scalar,hash and array data structures respectively.  An expected hash of a type means
that its keys must be of that type.  Each input type must have a test subroutine of the name t_$name
where $name is its name. Tests are called by the shell object. Tests that pass return a 1 and those
that fail return 0.

For example, lets look at the command printVarObj in Fry::Lib::Default. This command has an arg
value of '@var'. This means that the arguments are expected to be an array of type var. The var
type's test subroutine is &t_var and it is via this test that printVarObj's arguments will be
validated.

The arg attribute also offers the possibility to autocomplete a command's arguments
with the plugin Fry::ReadLine::Gnu. For autocompletion to work you must have a subroutine named
cmpl_$name where $name is the name of the user-defined type. The subroutine is called by the shell
object and should return a list of possible completion values. The autocompletion subroutine for
the previous subrouting would be cmpl_var.

You can turn off argument checking in the shell with the skiparg option.

=head1 PUBLIC METHODS

	argAlias($cmd,$args): Aliases a command's arguments by modifying the given arguments
		reference with the subroutine specified in the 'aa' attribute.
	checkArgs($cmd,@args): If args attribute is defined runs tests on user-defined arguments.
		If tests don't pass then warning is thrown and command is skipped.
	runCmd($cmd,@args): Runs command with given arguments. Checks for aliases.

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
