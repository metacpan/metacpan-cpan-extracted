#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Cook;

use strict qw(vars refs subs);
use Meta::Utils::Time qw();
use Meta::Utils::Options qw();
use Meta::Utils::File::Touch qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::File::Purge qw();
use File::Basename qw();
use DB_File qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Utils qw();
use Meta::Development::Deps qw();
use Meta::IO::File qw();

our($VERSION,@ISA);
$VERSION="0.50";
@ISA=qw();

#sub new($);

#sub search_list($);
#sub inte($);
#sub deve($);

#sub temp_dir($);

#sub touch($$$$$);
#sub touch_now($$$$);

#sub exec_development_build($$$$);
#sub exec_build($$$);

#sub print_deps_handle($$);
#sub print_deps($$);

#sub read_deps($$$);
#sub read_deps_full($);
#sub read_deps_set($);

#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	bless($self,$class);
	my($opts)=Meta::Utils::Options->new();
	my($cook_opts)=Meta::Baseline::Aegis::which("data/baseline/cook/opts.txt");
	$opts->read($cook_opts);
	$self->{OPTS}=$opts;
	return($self);
}

sub search_list($) {
	my($self)=@_;
	my($list)=Meta::Baseline::Aegis::search_path_list();
	return(join(" ",@$list));
}

sub inte($) {
	my($self)=@_;
	return(Meta::Baseline::Aegis::inte());
}

sub deve($) {
	my($self)=@_;
	return(Meta::Baseline::Aegis::deve());
}

sub temp_dir($) {
	my($self)=@_;
	return($self->{OPTS}->get("base_cook_temp"));
}

sub touch($$$$$) {
	my($self,$file,$time,$demo,$verb)=@_;
	if($verb) {
		Meta::Utils::Output::print("doing file [".$file."]\n");
	}
	my($name,$path,$suff)=File::Basename::fileparse($file);
	$name=~s/(\W)/\\$1/g;
	my($fp)=$path.".cook.fp";
	my($stat)="bad stat";
	if(-e $fp) {
		my(@arra);
		tie(@arra,"DB_File",$fp,DB_File::O_RDWR,0666,$DB_File::DB_RECNO) || throw Meta::Error::Simple("cannot tie [".$file."]");
		my($foun)=0;
		for(my($i)=0;($i<=$#arra) && (!$foun);$i++) {
			my($line)=$arra[$i];
			if($line=~"\"$name\"") {
				$arra[$i]="\"$name\"={ $time";
				$foun=1;
			}
		}
		if($foun) {
			$stat=".cook.fp changed";
		} else {
			$stat=".cook.fp didnt contain file";
		}
		untie(@arra) || throw Meta::Error::Simple("cannot untie [".$file."]");
	} else {
		$stat=".cook.fp not found";
	}
	if($verb) {
		Meta::Utils::Output::print("result: [".$stat."]\n");
	}
	return(Meta::Utils::File::Touch::date($file,$time,$demo,$verb));
}

sub touch_now($$$$) {
	my($self,$file,$demo,$verb)=@_;
	my($time)=Meta::Utils::Time::now_epoch();
	return($self->touch($file,$time,$demo,$verb));
}

sub exec_development_build($$$$) {
	my($self,$demo,$verb,$arra)=@_;

	if($demo) {
		return(1);
	}

	my($ctim)=Meta::Utils::Time::now_string();

	my($base_list)=$self->temp_dir()."/".$ctim.".list";
	my($base_book)=Meta::Baseline::Aegis::which("cook/main.cook");

	my($base_cook_search_path)=Meta::Baseline::Aegis::search_path();
	my($base_cook_baseline)=Meta::Baseline::Aegis::baseline();
	my($base_cook_project)=Meta::Baseline::Aegis::project();
	my($base_cook_change)=Meta::Baseline::Aegis::change();
	my($base_cook_version)=Meta::Baseline::Aegis::version();
	my($base_cook_architecture)=Meta::Baseline::Aegis::architecture();
	my($base_cook_state)=Meta::Baseline::Aegis::state();
	my($base_cook_developer)=Meta::Baseline::Aegis::developer();
	my($base_cook_developer_list)=Meta::Baseline::Aegis::developer_list();
	my($base_cook_reviewer_list)=Meta::Baseline::Aegis::reviewer_list();
	my($base_cook_integrator_list)=Meta::Baseline::Aegis::integrator_list();
	my($base_cook_administrator_list)=Meta::Baseline::Aegis::administrator_list();

	my($base_cook_search_list)=$self->search_list();
	my($base_cook_inte)=$self->inte();
	my($base_cook_deve)=$self->deve();

	my(@args)=
	(
		"-Book",$base_book,

		"base_cook_search_path=$base_cook_search_path",
		"base_cook_baseline=$base_cook_baseline",
		"base_cook_project=$base_cook_project",
		"base_cook_change=$base_cook_change",
		"base_cook_version=$base_cook_state",
		"base_cook_architecture=$base_cook_architecture",
		"base_cook_state=$base_cook_state",
		"base_cook_developer=$base_cook_developer",
		"base_cook_developer_list=$base_cook_developer_list",
		"base_cook_reviewer_list=$base_cook_reviewer_list",
		"base_cook_integrator_list=$base_cook_integrator_list",
		"base_cook_administrator_list=$base_cook_administrator_list",

		"base_cook_search_list=$base_cook_search_list",
		"base_cook_inte=$base_cook_inte",
		"base_cook_deve=$base_cook_deve",
	);

	my($opts)=$self->{OPTS};
	my($size)=$opts->size();
	for(my($i)=0;$i<$size;$i++) {
		my($key)=$opts->key($i);
		my($val)=$opts->val($i);
		push(@args,$key."=".$val);
	}

	my($base_cook_list)=$opts->get("base_cook_list");
	if($base_cook_list) {
		push(@args,"-List",$base_list);
	} else {
		push(@args,"-No_List");
	}

	my($base_cook_webx)=$opts->get("base_cook_webx");
	if($base_cook_webx) {
		push(@args,"-Web");
	} else {
		#there is no such flag (-No_Web)
		#it's enough that we don't put "-Web"
		#push(@args,"-No_Web");
	}

	push(@args,@$arra);
	if($verb) {
		Meta::Utils::Output::print("activating cook with [".join(',',@args)."]\n");
	}
	my($scod);
	if(!$demo) {
		$scod=Meta::Utils::System::system_nodie("cook",\@args);
	} else {
		$scod=1;
	}
	return($scod);
}

sub exec_build($$$) {
	my($self,$demo,$verb)=@_;
	my(@arra);
	my($scod)=$self->exec_development_build($demo,$verb,\@arra);
	if($scod) {
		if(!$demo) {
			my($dire)=Meta::Baseline::Aegis::integration_directory();
			$scod=Meta::Utils::File::Purge::purge($dire,0,0,undef);
		}
	}
	return($scod);
}

sub print_deps_handle($$) {
	my($deps,$file)=@_;
	#put a nice emblem to begin the file
	Meta::Baseline::Utils::cook_emblem_print($file);
	# iterate over the nodes
	for(my($i)=0;$i<$deps->node_size();$i++) {
		my($node)=$deps->nodes()->elem($i);
		my($out_edges)=$deps->edge_ou($node);
		# only if there are dependencies
		if($out_edges->size()>0) {
			print $file "cascade ".$node."=\n";
			for(my($j)=0;$j<$out_edges->size();$j++) {
				my($edge)=$out_edges->elem($j);
				print $file $edge."\n";
			}
			print $file ";\n";
		}
	}
	return(1);
}

sub print_deps($$) {
	my($deps,$targ)=@_;
	open(FILE,"> ".$targ) || throw Meta::Error::Simple("unable to open file [".$targ."]");
	&print_deps_handle($deps,*FILE);
	close(FILE) || throw Meta::Error::Simple("unable to close file [".$targ."]");
	return(1);
}

sub read_deps($$$) {
	my($deps,$file,$recu)=@_;
	#Meta::Utils::Output::print("file is [".$file."]\n");
	my($f_name,$f_path,$f_suff)=File::Basename::fileparse($file,'\..*');
	my($exte)="deps/".$f_path.$f_name.".deps";
	#Meta::Utils::Output::print("trying [".$exte."]\n");
	my($full)=Meta::Baseline::Aegis::which_nodie($exte);
	if(defined($full)) {
		my(@list);
		my($io)=Meta::IO::File->new_reader($full);
		# read the first comment line.
		my($line)=$io->cgetline();
		# if we have dep information
		if(!$io->eof()) {
			# read the cascade line
			$line=$io->cgetline();
			my($new)=($line=~/^cascade (.*)=$/);
			#Meta::Utils::Output::print("inserting node [".$new."]\n");
			$deps->node_insert($new);
			while(!$io->eof()) {
				if($line ne ";") {
					if(!$deps->node_has($line)) {
						push(@list,$line);
					}
					$deps->node_insert($line);
					#Meta::Utils::Output::print("inserting node [".$line."]\n");
					$deps->edge_insert($new,$line);
					#Meta::Utils::Output::print("inserting edge [".$new.",".$line."]\n");
				}
			}
		}
		$io->close();
		if($recu) {
			for(my($i)=0;$i<=$#list;$i++) {
				read_deps($deps,$list[$i],$recu);
			}
		}
	} else {
		$deps->node_insert($file);
	}
}

sub read_deps_full($) {
	my($file)=@_;
	my($graph)=Meta::Development::Deps->new();
	read_deps($graph,$file,1);
	return($graph);
}

sub read_deps_set($) {
	my($set)=@_;
	my($graph)=Meta::Development::Deps->new();
	for(my($i)=0;$i<$set->size();$i++) {
		my($curr)=$set->elem($i);
		read_deps($graph,$curr,1);
	}
	return($graph);
}

sub TEST($) {
	my($context)=@_;
	my($cook)=Meta::Baseline::Cook->new();
	my($search_list)=$cook->search_list();
	Meta::Utils::Output::print("search_list is [".$search_list."]\n");
	my($inte)=$cook->inte();
	Meta::Utils::Output::print("inte is [".$inte."]\n");
	my($deve)=$cook->deve();
	Meta::Utils::Output::print("deve is [".$deve."]\n");
	my($temp_dir)=$cook->temp_dir();
	Meta::Utils::Output::print("temp_dir is [".$temp_dir."]\n");

	my($graph)=Meta::Baseline::Cook::read_deps_full("deps/html/projects/Website/computing.deps");
	Meta::Utils::Output::print("number of nodes is [".$graph->node_size()."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Cook - library to give out cook related information to perl scripts.

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

	MANIFEST: Cook.pm
	PROJECT: meta
	VERSION: 0.50

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Cook qw();
	my($cook)=Meta::Baseline::Cook->new();
	$cook->exec_build([params]);

=head1 DESCRIPTION

This library is intended to supply all demanders (i.e. Peter Miller's cook,
other scripts or any other inquirer) any information regarding cook related
parameters in the project. In addition this library knows how to do cook
related stuff (write and read dependencies in cook format...).

=head1 FUNCTIONS

	new($)
	search_list($)
	inte($)
	deve($)
	temp_dir($)
	touch($$$$$)
	touch_now($$$$)
	exec_development_build($$$$)
	exec_build($$$)
	print_deps_handle($$)
	print_deps($$)
	read_deps($$$)
	read_deps_full($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This gives you a new cook object.

=item B<search_list($)>

This returns the search_list variable in cook format (space separated...).

=item B<inte($)>

This returns 0 or 1 accroding to whether this is an integration state.

=item B<deve($)>

This returns 0 or 1 accroding to whether this is a development state.

=item B<temp_dir($)>

This will return a temp directory to hold cook junk files.
(lists, temporary files, etc...).

=item B<touch($$$$$)>

This routine receives file to touch,epoch date and a verbose variable.
It check if the the directory in which the file resides has a ".cook.fp"
file in it. If so, it checks if the file name is in the ".cook.fp" file.
If so, it chages the file's date (in epoch seconds) to the epoch date received
from whatever was in there.
In either case it uses the regular mechanism and touches the file using the
epoch received.
The overall effect is that cook will be aware that the file has indeed changed.

=item B<touch_now($$$$)>

This routine receives a file, a demo flag and a verbose flag.
The routine finds the current time using Meta::Utils::Time::now_epoch
and then calls touch from this module to change the cook time to the
current time.

=item B<exec_development_build($$$$)>

This routine executes a development build.
It receives a list of arguments as the partial build targets and executes
cook. The routine returns the status from cook on exit.

=item B<exec_build($$$)>

This command executes an integration build.
This is the reason why the command does not receive any arguments since
partial builds in integration time are not allowed.
This just calls exec_development_build with no partial targets.
This returns the correct state output.
This routine receives a demo flag of whether to run as demo or not.

=item B<print_deps_handle($$)>

This method gets a dependency object and prints it out in cook style.
A dependency object is just a graph so what it needed here is the following:
pass over every node (in whatever order) and for each node find edges to other
nodes and emit the "cascase" type statements for cook. If the node does not
have any adjacents - no need to emit anything!!! right ?

=item B<print_deps($$)>

This method is exactly as print_deps_handle except it also opens and closes
a file.

=item B<read_deps($$$)>

This method receives a baseline related file name and assumes that its a cook
dependency file written by the above print_deps methods. It adds the dependency
information it finds in the file to the graph it gets also as input. It also
receives a parameters telling it whether to be recursive or not.

=item B<read_deps_full($)>

This method is just convenience wrapper around the read_deps method. It generates
the graph that will be used to hold the dependency information. It also returns
that graph at the end.

=item B<TEST($)>

Test suite for this module.
This just prints out some statistics out of that module.

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
	0.01 MV bring databases on line
	0.02 MV adding an XML viewer/editor to work with the baseline
	0.03 MV code sanity
	0.04 MV Another change
	0.05 MV make quality checks on perl code
	0.06 MV more perl checks
	0.07 MV make Meta::Utils::Opts object oriented
	0.08 MV more harsh checks on perl code
	0.09 MV check that all uses have qw
	0.10 MV differentiate between deps and udep in perl
	0.11 MV fix todo items look in pod documentation
	0.12 MV handle C++ dependencies better
	0.13 MV more on tests/more checks to perl
	0.14 MV more perl code quality
	0.15 MV put ALL tests back and light the tree
	0.16 MV fix up the cook module
	0.17 MV change new methods to have prototypes
	0.18 MV cook.pm to automatically pass options down to the cook level
	0.19 MV correct die usage
	0.20 MV perl quality change
	0.21 MV perl code quality
	0.22 MV more perl quality
	0.23 MV chess and code quality
	0.24 MV more perl quality
	0.25 MV perl documentation
	0.26 MV more perl quality
	0.27 MV perl qulity code
	0.28 MV more perl code quality
	0.29 MV more perl quality
	0.30 MV revision change
	0.31 MV languages.pl test online
	0.32 MV good xml support
	0.33 MV real deps for docbook files
	0.34 MV html site update
	0.35 MV spelling and papers
	0.36 MV fix up cook files
	0.37 MV perl packaging
	0.38 MV xml encoding
	0.39 MV md5 project
	0.40 MV database
	0.41 MV perl module versions in files
	0.42 MV movies and small fixes
	0.43 MV thumbnail user interface
	0.44 MV more thumbnail issues
	0.45 MV website construction
	0.46 MV web site automation
	0.47 MV SEE ALSO section fix
	0.48 MV web site development
	0.49 MV teachers project
	0.50 MV md5 issues

=head1 SEE ALSO

DB_File(3), File::Basename(3), Meta::Baseline::Aegis(3), Meta::Baseline::Utils(3), Meta::Development::Deps(3), Meta::IO::File(3), Meta::Utils::File::Purge(3), Meta::Utils::File::Touch(3), Meta::Utils::Options(3), Meta::Utils::Output(3), Meta::Utils::Time(3), strict(3)

=head1 TODO

-unite all the init routines into init and make that code run on usage (in the BEGIN block of the module...).

-In the init routine: Get names of architectures. Get names of machines. Get names of languages supported.

-split the unix_path routine to fixpath and fixline where the difference is that the first matches a single match at the begining and the later matches many matches anywhere.

-remove the unix_path routine from this module once we fix the amd maps.

-add more functionality here like auto script making for auto mounting on the NT machines, distinguishing between Watcom and Visual C++ etc... (machines that give out services that is...).

-maybe when we give a list of machines to cook we should double the name of the current host or something to refelect the fact that he's faster ? check with peter... Maybe we should double the name of the host on which the change resides locally ?

-make is_plat not do that ugly "|| $plat eq "scr"" stuff.
