#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Fhist;

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use File::Basename qw();
use Meta::Baseline::Aegis qw();
use Meta::Revision::Entry qw();
use Meta::Revision::Revision qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::File::Patho qw();

our($VERSION,@ISA);
$VERSION="0.18";
@ISA=qw();

#sub BEGIN();
#sub history($);
#sub create($$);
#sub get($$$);
#sub put($$);
#sub query($);
#sub easy_put($);
#sub TEST($);

#__DATA__

our($tool_path);

sub BEGIN() {
	my($patho)=Meta::Utils::File::Patho->new_path();
	$tool_path=$patho->resolve("tar");
}

sub history($) {
	my($file)=@_;
	my(@args);
	my($module)=File::Basename::basename($file);
	my($module_dir)=File::Basename::dirname($file);
	my($history)=Meta::Baseline::Aegis::history_directory();
	my($module_path)=$history."/".$module_dir;
	my($prog)="fhist";
	push(@args,$module);
	push(@args,"-List");
	push(@args,"-Path");
	push(@args,$module_path);
	my($text)=Meta::Utils::System::system_out($prog,\@args);
#	Meta::Utils::Output::print("text is [".$$text."]\n");
	my(@lines)=split("\n",$$text);
	my($revision)=Meta::Revision::Revision->new();
	for(my($i)=1;$i<=$#lines;$i+=2) {
		my($info_line)=$lines[$i];
#		Meta::Utils::Output::print("info_line is [".$info_line."]\n");
		my($number,$initials,$date)=($info_line=~/^Edit (\d+):\ \ \ (.*)\ \ \ (.*)$/);
#		Meta::Utils::Output::print("number is [".$number."]\n");
		my($remark)=$lines[$i+1];
		if($remark eq "") {
			$remark="NONE";
		}
		my($curr)=Meta::Revision::Entry->new();
		$curr->set_number($number);
		$curr->set_date($date);
		$curr->set_initials($initials);
		$curr->set_remark($remark);
		$revision->push($curr);
	}
	return($revision);
}

sub create($$) {
	my($input,$history)=@_;
	my($prog)="fhist";
	my(@args);
	push(@args,File::Basename::basename($input));
	push(@args,"-CReate");
	push(@args,"-Conditional_Update");
	push(@args,"-Input");
	push(@args,$input);
	push(@args,"-Path");
	push(@args,File::Basename::dirname($history));
	push(@args,"-Remark");
	#if($input=~/\.jar$/ || $input=~/\.jpg$/ || $input=~/\.png$/) {
	#	push(@args,"-BINary");
	#}
	my($scod)=Meta::Utils::System::system_nodie($prog,\@args);
	return($scod);
}

sub get($$$) {
	my($history,$edit,$output)=@_;
	my($prog)="fhist";
	my(@args);
	push(@args,File::Basename::basename($history));
	push(@args,"-Extract");
	push(@args,$edit);
	push(@args,"-Output");
	push(@args,$output);
	push(@args,"-Path");
	push(@args,File::Basename::dirname($history));
	#if($history=~/\.jar$/ || $history=~/\.jpg$/ || $history=~/\.png$/) {
	#	push(@args,"-BINary");
	#}
	my($scod)=Meta::Utils::System::system_nodie($prog,\@args);
	return($scod);
}

sub put($$) {
	my($input,$history)=@_;
	my($prog)="fhist";
	my(@args);
	push(@args,File::Basename::basename($input));
	push(@args,"-Create");
	push(@args,"-Conditional_Update");
	push(@args,"-Input");
	push(@args,$input);
	push(@args,"-Path");
	push(@args,File::Basename::dirname($history));
	push(@args,"-Remark");
	#if($input=~/\.jar$/ || $input=~/\.jpg$/ || $input=~/\.png$/) {
	#	push(@args,"-BINary");
	#}
	my($scod)=Meta::Utils::System::system_nodie($prog,\@args);
	return($scod);
}

sub query($) {
	my($history)=@_;
	my($prog)="fhist";
	my(@args);
	push(@args,File::Basename::basename($history));
	push(@args,"-List");
	push(@args,0);
	push(@args,"-Path");
	push(@args,File::Basename::dirname($history));
	push(@args,"-Quick");
	#if($history=~/\.jar$/ || $history=~/\.jpg$/ || $history=~/\.png$/) {
	#	push(@args,"-BINary");
	#}
	my($scod)=Meta::Utils::System::system_nodie($prog,\@args);
	return($scod);
}

sub easy_put($) {
	my($file)=@_;
	my($dire)=File::Basename::dirname($file);
	my($history)=Meta::Baseline::Aegis::history_directory();
	return(put($file,$history."/".$dire));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Fhist - module to help you deal with Fhist.

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

	MANIFEST: Fhist.pm
	PROJECT: meta
	VERSION: 0.18

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Fhist qw();
	my($object)=Meta::Tool::Fhist->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module helps you interact with fhist -
ask something of it and it shall oblige.
Pay attention that we do NOT use the -BINary flag anymore since
aegis supports binary files from version 3.26.

=head1 FUNCTIONS

	BEGIN()
	history($)
	create($$)
	get($$$)
	put($$)
	query($)
	easy_put($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method to find your version of fhist.

=item B<history($)>

This method receives a file name and returns the history object of that
module. Mind you that normally you would not use this because SCS systems
use fhist only for storage. If you want to get a full listing of a sources
history - go to your SCS system (Aegis).

=item B<create($$)>

This method will create a new fhist module for a new file to save history
for.

=item B<get($$$)>

This method will get a certain edit of a certain module from history.

=item B<put($$)>

This method will put (commit) a module to history.

=item B<query($)>

This method receives a module name and queries the history tool about its
history.

=item B<easy_put($)>

This method just put a file given to it in history.

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

	0.00 MV revision change
	0.01 MV better general cook schemes
	0.02 MV all fhist stuff into Fhist.pm
	0.03 MV pictures in docbooks
	0.04 MV languages.pl test online
	0.05 MV history change
	0.06 MV perl packaging
	0.07 MV db inheritance
	0.08 MV md5 project
	0.09 MV database
	0.10 MV perl module versions in files
	0.11 MV movies and small fixes
	0.12 MV graph visualization
	0.13 MV thumbnail user interface
	0.14 MV more thumbnail issues
	0.15 MV website construction
	0.16 MV web site automation
	0.17 MV SEE ALSO section fix
	0.18 MV md5 issues

=head1 SEE ALSO

File::Basename(3), Meta::Baseline::Aegis(3), Meta::Revision::Entry(3), Meta::Revision::Revision(3), Meta::Utils::File::Patho(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-this module should check if the files are binary via some interface and
	not hardcoded as it is now.
