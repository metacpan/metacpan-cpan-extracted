#!/bin/echo This is a perl module and should not be run

package Meta::Utils::System;

use strict qw(vars refs subs);
use Carp qw();
use Meta::Utils::File::File qw();
use Meta::Utils::Utils qw();
use Meta::Utils::Debug qw();
use Meta::Utils::Output qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.40";
@ISA=qw();

#sub system_nodie($$);
#sub system($$);
#sub system_shell_nodie($);
#sub system_shell($);
#sub smart_shell($);
#sub system_out_nodie($$$);
#sub system_err($$$);
#sub system_err_nodie($$$);
#sub system_err_silent_nodie($$);
#sub system_out($$);
#sub system_out_val($$);
#sub system_out_list($$);
#sub system_out_hash($$);
#sub perl_nodie($$);
#sub smart_nodie($$);
#sub eval_nodie($$);
#sub os_exit($);
#sub exit($);
#sub exit_ok();
#sub die($);
#sub TEST($);

my($eval);

#__DATA__

sub system_nodie($$) {
	my($prog,$args)=@_;
#	Meta::Utils::Arg::check_arg($prog,"SCALAR");
#	Meta::Utils::Arg::check_arg($args,"ARRAYref");
#	Meta::Utils::Output::print("prog is [".$prog."]\n");
#	Meta::Utils::Output::print("args is [".CORE::join(",",@$args)."]\n");
	if(Meta::Utils::Debug::debug()) {
		Meta::Utils::Debug::msg(CORE::join(",",$prog,@$args));
	}
	my($code)=CORE::system($prog,@$args);
	$code>>=8;
	my($resu)=Meta::Utils::Utils::bnot($code);
	return($resu);
}

sub system($$) {
	my($comm,$list)=@_;
	my($resu)=&system_nodie($comm,$list);
	if(!$resu) {
		throw Meta::Error::Simple("execution of [".$comm."] failed");
	}
	return($resu);
}

sub system_shell_nodie($) {
	my($prog)=@_;
	my($code)=CORE::system($prog);
	my($resu)=Meta::Utils::Utils::bnot($code);
	return($resu);
}

sub system_shell($) {
	my($prog)=@_;
	my($code)=CORE::system($prog);
	my($resu)=Meta::Utils::Utils::bnot($code);
#	Meta::Utils::Output::print("resu is [".$resu."]\n");
	if(!$resu) {
		throw Meta::Error::Simple("error running shell command [".$prog."]");
	}
}

sub smart_shell($) {
	my($comm)=@_;
	return(&system_shell_nodie($comm));
}

sub system_out_nodie($$$) {
	my($text,$prog,$args)=@_;
	my($full)=$prog." ".CORE::join(" ",@$args)." |";
	open(FILE,$full) || return(0);
	my($line);
	$$text="";
	while($line=<FILE> || 0) {
		$$text.=$line;
	}
	close(FILE) || return(0);
	return(1);
}

sub system_err($$$) {
	my($text,$prog,$args)=@_;
	my($full)=$prog." ".CORE::join(' ',@$args)." 2>&1 |";
	open(FILE,$full) || throw Meta::Error::Simple("unable to open prog [".$full."]");
	my($line);
	$$text="";
	while($line=<FILE> || 0) {
		$$text.=$line;
	}
	close(FILE) || throw Meta::Error::Simple("unable to close prog [".$full."]");
}

sub system_err_nodie($$$) {
	my($text,$prog,$args)=@_;
#	Meta::Utils::Arg::check_arg($prog,"SCALAR");
#	Meta::Utils::Arg::check_arg($args,"ARRAYref");
#	Meta::Utils::Output::print("prog is [".$prog."]\n");
#	Meta::Utils::Output::print("args is [".CORE::join(",",@$args)."]\n");
	my($full)=$prog." ".CORE::join(" ",@$args)." 2>&1 |";
	open(FILE,$full) || return(0);
	my($line);
	$$text="";
	while($line=<FILE> || 0) {
		$$text.=$line;
	}
	close(FILE) || return(0);
	return(1);
}

sub system_err_silent_nodie($$) {
	my($prog,$args)=@_;
	my($text);
	my($resu)=system_err_nodie(\$text,$prog,$args);
	if(!$resu) {
		Meta::Utils::Output::print($text);
	}
	return($resu);
}

sub system_out($$) {
	my($prog,$args)=@_;
#	Meta::Utils::Output::print("prog is [".$prog."]\n");
#	Meta::Utils::Output::print("args is [".$args."]\n");
#	Meta::Utils::Arg::check_arg($prog,"SCALAR");
#	Meta::Utils::Arg::check_arg($args,"ARRAYref");
	my($full)=$prog." ".CORE::join(" ",@$args)." |";
	open(FILE,$full) || &die("unable to run/open file to [".$prog."]");
	my($line);
	my($retu);
	while($line=<FILE> || 0) {
		$retu.=$line;
	}
	close(FILE) || &die("unable to close [".$prog."]");
	return(\$retu);
}

sub system_out_val($$) {
	my($prog,$args)=@_;
	my($resu)=&system_out($prog,$args);
	return($$resu);
}

sub system_out_list($$) {
	my($prog,$args)=@_;
	my($full)=$prog." ".CORE::join(" ",@$args)." |";
	open(FILE,$full) || &die("unable to run/open file to [".$prog."]");
	my(@retu);
	my($line);
	while($line=<FILE> || 0) {
		chop($line);
		push(@retu,$line);
	}
	close(FILE) || &die("unable to close [".$prog."]");
	return(\@retu);
}

sub system_out_hash($$) {
	my($prog,$args)=@_;
	my($full)=$prog." ".CORE::join(" ",@$args)." |";
	open(FILE,$full) || &die("unable to run/open file to [".$prog."]");
	my(%retu);
	my($line);
	while($line=<FILE> || 0) {
		chop($line);
		$retu{$line}=defined;
	}
	close(FILE) || &die("unable to close [".$prog."]");
	return(\%retu);
}

sub perl_nodie($$) {
	my($prog,$args)=@_;

#	my($cmpt)=new Safe();
#	$cmpt->deny_only();
#	my($resu)=$cmpt->rdo($prog);
#	or
#	use Meta::Utils::File::File qw();
#	my($file);
#	Meta::Utils::File::File::load($prog,\$file);
#	my($resu)=$cmpt->reval($file);

#	my(@save)=@ARGV;
#	@ARGV=@args;
#	require $prog;
#	@ARGV=@save;

	$eval=1;
	my($file);
	Meta::Utils::File::File::load($prog,\$file);

	my(@save)=@ARGV;
	@ARGV=@$args;
	open(OLDOUT,">&STDOUT") || &die("unable to dup stdout");
	open(OLDERR,">&STDERR") || &die("unable to dup stderr");
	my($resu)=eval($file);# we dont need the return from eval
	my($code)=int($@);
	my($result)=Meta::Utils::Utils::bnot($code);
	open(STDOUT,">&OLDOUT") || &die("unable to dup stdout");
	open(STDERR,">&OLDERR") || &die("unable to dup stderr");
	close(OLDOUT) || &die("unable to close oldout");
	close(OLDERR) || &die("unable to close olderr");
	@ARGV=@save;
	$eval=0;

	return($result);
}

sub smart_nodie($$) {
	my($prog,$args)=@_;
	if(File::Basename::basename($prog) eq "perl") {
		&die("oh oh");
		return(undef);
#		return(perl_nodie($args[0],$args[1..$#@$args]));
	} else {
		if(Meta::Utils::Utils::is_suffix($prog,".pl")) {
			return(perl_nodie($prog,$args));
		} else {
			return(system_nodie($prog,$args));
		}
	}
}

sub eval_nodie($$) {
	my($string,$ref)=@_;
#	my($io)=IO::String->new_from_fd(STDOUT,"r");
	$$ref="hello";
	return(1);
}

sub os_exit($) {
	my($code)=@_;
	if($eval==1) {
		CORE::open(STDERR,"/dev/null") || &die("cannot redirect stderr to /dev/null");
		&die($code."\n");
	} else {
		CORE::exit($code);
	}
}

sub exit($) {
	my($scod)=@_;
	my($code)=Meta::Utils::Utils::bnot($scod);
	CORE::exit($code);
}

sub exit_ok() {
	&exit(1);
}

sub die($) {
	my($stri)=@_;
	Carp::confess($stri);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::System - A module to help with running other programs.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: System.pm
	PROJECT: meta
	VERSION: 0.40

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::System qw();
	Meta::Utils::System::system_shell("echo Hello, World!");

=head1 DESCRIPTION

SPECIAL STDERR FILE

This library basically provides the routines to do the following:
0. execute binaries.
1. execute shell commands (with shell interpretation).
2. execute other perl scripts (in the same interpreter as you are...).
3. smart routines to find the most efficient way to execute something.
All routines have a die/nodie version which (respectivly) die or don't
die on errors from the execution process...

=head1 FUNCTIONS

	system_nodie($$)
	system($$)
	system_shell_nodie($)
	system_shell($)
	smart_shell($)
	system_out_nodie($$$)
	system_err($$$)
	system_err_nodie($$$)
	system_err_silent_nodie($$)
	system_out($$)
	system_out_val($$)
	system_out_list($$)
	system_out_hash($$)
	perl_nodie($$)
	smart_nodie($$)
	os_exit($)
	exit($)
	exit_ok()
	die($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<system_nodie($$)>

This routine is the same as the system routine and it does not die.
It returns the actual code that that process returned (look at the
"CORE::system" routines manual for details...).

=item B<system($$)>

This routine does the regular system() perl call.
The idea is to expand it to include the fact that if a perl script
is run then it will not be run via a regular call but rather inside
the perl interpreter...
In any case the system which is called does not pass through a shell
since we use it with two arguments (read the documentation of CORE::system).
We also dies if the system is not successfull.

=item B<system_shell_nodie($)>

This executes a system shell but doesnt die.
It returns the exit status of the process.

=item B<system_shell($)>

This routine executes a system command given in one string.
This will use the regular system of perl and therefore will use
a shell and will be slower than the sys command (better use that...).
It will also (like sys) die if there is an error.

=item B<smart_shell($)>

This routine get a full shell script, splits it according to ";", and gives
each piece to smart_part_shell.

=item B<system_out_nodie($$$)>

This routine does exactly the same as B<system_out> but does not die.
This routine return the error status according to whether the command was
successful or not.
This routine gets a string by reference to store the results in.

=item B<system_err($$$)>

This method will run a system command and will put it's standard error into
a string reference you will give it. Exceptions will be thrown in case of
error.

=item B<system_err_nodie($$$)>

This method is the same as system_out_nodie except it catched the standard
error and not the standard output.

=item B<system_err_silent_nodie($$)>

This method is the same as system_err_nodie except it will print out the
output if it fails.

=item B<system_out($$)>

This routine runs a script with arguments and returns a reference to all
the output that the program generated (stdout).
The program should accept one argument which is the program to be run and
an array of arguments for that program.

=item B<system_out_val($$)>

This routine returns the output of running a system command with the outputs
actual value and not just a reference (for use in small outputed executables).

=item B<system_out_list($$)>

This gives you the output of a command as a list of the lines of the output.

=item B<system_out_hash($$)>

This gives you the output of a command as a hash of the lines of the output.

=item B<perl_nodie($$)>

This routine receives a name of a perl script to execute, and a list
of arguments for it and executes it with the current perl interpreter
and returning the return value of the script and not dying if something
went wrong.
This script could be done in two basic ways:
0. way number 1 - the correct way - using the Safe module which allows
	you to control the compartment in which you're evaluating
	the code and make sure that it doesnt contaminate your name space...
	(contamination could even mean chaning your variables...).
	I didn't get that code to work and it is currently marked out...
	Read the perl manual for "Safe" if you want to know more...
1. way number 2 - the wrong way - this is currently implemented.
	Just eval the code. This is unsafe as name space contamination
	is concerned but hey - "Im just a singer in a Rock & Roll band...".
In both methods care in the routine is taken for the following:
0. setting ARGV to list the arguments so the code will think it is
	actually being executed.
1. saving stderr and stdout for any case the code does any redirection
	(and it does since it uses our own "exit" method which redirects
	stderr so "die" wont print it's funny messages on the screen...).
2. getting the correct return code. this is very ugly indeed since we take
	it for granted that the process were using uses our own "exit" routine
	to exit and that routine puts the code in the $@ variable.

=item B<smart_nodie($$)>

This routine is a smart execution routine. You should use this routine
to execute anything you want when you dont know what it is you want
to execute. The idea is for the routine to detect that you want to execute
perl code and not to execute perl again but rather use the "perl_" routines
in this module to run it. If what you want to run is another type
of executable then the regular "system_" routines are called.
The routine detects perl code to be run in two ways:
0. the suffix of the file to run is ".pl".
1. the program that you want to run is a perl interpreter.

=item B<os_exit($)>

This routine is you way to exit the program with an error code!
The ideas here are:
0. use die and not exit so your entire code could be evaluated within
	yet another perl program and not cause the entire thing
	to exit (using "exit" is nasty - check the perl manual...).
1. block stderr from writing before the die cause we dont want eny
	message on the screen. (the parent will take care of it's own
	stderr handle and even "dup" it if need be before calling
	us to do our thing).
2. I know it's funny that there is no "die" routine that doesnt print
	anything to the screen and I've sent a mail about that to
	the perl guys (Gurushy Sarathni - the guy in charge of perl
	release 5.6...). No real answer as of yet...

=item B<exit($)>

This function performs an exist but with a normal value passed to
it. This means that you pass 1 for success and 0 otherwise.

=item B<exit_ok()>

This function is explicitly designed to be called when a program
exists successfully. Currently it merely calls exit(1) from this
very package.

=item B<die($)>

This routine gets a string and dies while printing the string.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV initial code brought in
	0.01 MV make quality checks on perl code
	0.02 MV more perl checks
	0.03 MV make Meta::Utils::Opts object oriented
	0.04 MV more harsh checks on perl code
	0.05 MV fix up perl checks
	0.06 MV check that all uses have qw
	0.07 MV fix todo items look in pod documentation
	0.08 MV more on tests/more checks to perl
	0.09 MV more perl code quality
	0.10 MV more quality testing
	0.11 MV lilypond stuff
	0.12 MV fix up the rule system
	0.13 MV finish Simul documentation
	0.14 MV perl quality change
	0.15 MV perl code quality
	0.16 MV more perl quality
	0.17 MV more perl quality
	0.18 MV perl documentation
	0.19 MV more perl quality
	0.20 MV perl qulity code
	0.21 MV more perl code quality
	0.22 MV revision change
	0.23 MV languages.pl test online
	0.24 MV history change
	0.25 MV PDMT/SWIG support
	0.26 MV perl packaging
	0.27 MV PDMT
	0.28 MV md5 project
	0.29 MV database
	0.30 MV perl module versions in files
	0.31 MV movies and small fixes
	0.32 MV more thumbnail stuff
	0.33 MV thumbnail user interface
	0.34 MV more thumbnail issues
	0.35 MV md5 project
	0.36 MV website construction
	0.37 MV web site automation
	0.38 MV SEE ALSO section fix
	0.39 MV download scripts
	0.40 MV md5 issues

=head1 SEE ALSO

Carp(3), Error(3), Meta::Utils::Debug(3), Meta::Utils::File::File(3), Meta::Utils::Output(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-do not actually do a system call in both system and system_shell (one should call the other...).

-make the routine that die use the routines that dont die.

-drop the "system_" add to everything. do the following names: system [to] dire_diex system_nodie [to] dire_ndie system_shell [to] shel_diex system_shell_nodie [to] shel_ndie system_out [to] dire_outx and add the "shel_outx" routine. maybe think about passing the die argument ?

-why doesnt the use of Safe work ? It keeps giving me these strange errors!!! make the Safe work - this is a must because otherwise the code could do bad things to us...

-the perl_nodie routine doesnt know how to scan the path for the executable that it's expected to perform. therefore it has to get absolute file names. (as a result the smart routine also has to get absolute filenames cause its using perl_nodie...). make it scan...

-add a third way of detecting that perl code is wanted to run in the "smart_" routines using the first line of the target script...

-improve the exit routine... It should be nicer...

-rearrange the routines in proper order...

-work with the "Safe" module in the perl runnign section.

-get ridd of the ugly patch where "exit" sends the code in the "$@" variable so "perl_nodie" could catch it there...

-smart_shell should be optimized greatly.

-straighten out the mess with system_out,system_out_val,system_out_nodie (have them do some code sharing for god sake...).

-do a function which runs a system command that gets its stdin from a text you send it... (this could be useful in a lot of cases...).

-do a shell function that runs a command internally (not via shell) and has a predefined output file for stdout or stderr.
