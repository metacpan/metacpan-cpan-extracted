#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use POSIX qw();
use File::Basename qw();
use Meta::Utils::File::File qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::Output qw();
use Meta::Ds::Ohash qw();
use Error qw(:try);

sub develop_path_addx($$$) {
	my($onex,$twox,$sepa)=@_;
	if($onex eq "") {
		if($twox eq "") {
			return("");
		} else {
			return($twox);
		}
	} else {
		if($twox eq "") {
			return($onex);
		} else {
			return(join($sepa,$onex,$twox));
		}
	}
}

sub develop_path_mini($$) {
	my($val,$sepa)=@_;
	my(@arra)=split($sepa,$val);
	my(%hash);
	my(@narr);
	for(my($i)=0;$i<=$#arra;$i++) {
		my($curr)=$arra[$i];
		if(!exists($hash{$curr})) {
			push(@narr,$curr);
			$hash{$curr}=defined;
		}
	}
	my($resu)=join($sepa,@narr);
	return($resu);
}

sub develop_envx_addx($$$$$) {
	my($varx,$sepa,$val,$star,$env)=@_;
	my($curr);
	if($env->has($varx)) {
		$curr=$env->get($varx);
	} else {
		try {
			$curr=Meta::Utils::Env::get($varx);
		}
		catch Error with {
			$curr="";
		};
	}
	my($nval);
	if(defined($curr)) {
		if($curr eq "") {
			$nval=$val;
		} else {
			if($star) {
				$nval=join($sepa,$val,$curr);
			} else {
				$nval=join($sepa,$curr,$val);
			}
		}
	} else {
		$nval=$val;
	}
	my($mini)=develop_path_mini($nval,$sepa);
	$env->insert($varx,$mini);
}

sub develop_envx_addx_mult($$$$$$) {
	my($varx,$sepa,$list,$suff,$star,$env)=@_;
	my(@vals)=split($sepa,$list);
	my(@resu);
	for(my($i)=0;$i<=$#vals;$i++) {
		push(@resu,$vals[$i].$suff);
	}
	my($resx)=join($sepa,@resu);
	develop_envx_addx($varx,$sepa,$resx,$star,$env);
}

sub develop_scri_addx($$) {
	my($list,$para)=@_;
	push(@$list,$para);
}

my($aegi,$tvbi,$tvld,$tvma,$tvin,$xmli,$sgmi,$sgpi,$bplt,$dplt,$shel,$tbin,$tldx,$tman,$tinf);
my($txml,$tsgm,$tsgp,$tsgs,$binx,$ldxx,$manx,$info,$java,$perl,$txmd,$sgml,$sgpl,$pyth,$base);
my($cdpa,$cdch,$colo,$lsco,$long,$pete,$nprj,$nchn,$blxx,$chxx,$ps1x,$page,$manp,$prof,$verb);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_dire("aegi","where is your aegis located","/local/tools/bin",\$aegi);
$opts->def_path("tvbi","extra path for the shell runner","/usr/games:/usr/sbin:/local/tools/bin",\$tvbi);
$opts->def_path("tvld","extra path for the dynamic linkder","/local/tools/lib",\$tvld);
$opts->def_path("tvma","extra path for the man pager","/local/tools/man",\$tvma);
$opts->def_path("tvin","extra path for the info pager","/local/tools/info",\$tvin);
$opts->def_flst("xmli","extra path for the XML catalogs","",\$xmli);
$opts->def_flst("sgmi","extra path for the SGML catalogs","",\$sgmi);
$opts->def_path("sgpi","extra path for the sgml path","",\$sgpi);
$opts->def_stri("bplt","what is the binary platform you are working on","reg.cpp.bin.dbg",\$bplt);
$opts->def_stri("dplt","what is the dll platform you are working on","reg.cpp.dll.dbg",\$dplt);
$opts->def_stri("shel","what is your shell","bash2",\$shel);
$opts->def_bool("tbin","do you want to set PATH for tools",0,\$tbin);
$opts->def_bool("tldx","do you want to set LD_LIBRARY_PATH for tools",0,\$tldx);
$opts->def_bool("tman","do you want to set MANPATH for tools",1,\$tman);
$opts->def_bool("tinf","do you want to set INFOPATH for tools",1,\$tinf);
$opts->def_bool("txml","do you want to set XML_CATALOG_FILES for tools",0,\$txml);
$opts->def_bool("tsgm","do you want to set SGML_CATALOG_FILES for tools",0,\$tsgm);
$opts->def_bool("tsgp","do you want to set SGML_SEARCH_PATH for tools",0,\$tsgp);
$opts->def_bool("tsgs","do you want to set SGML_PATH for tools",0,\$tsgs);
$opts->def_bool("binx","do you want to set PATH for tools",1,\$binx);
$opts->def_bool("ldxx","do you want to set LD_LIBRARY_PATH for tools",1,\$ldxx);
$opts->def_bool("manx","do you want to set MANPATH for tools",0,\$manx);
$opts->def_bool("info","do you want to set INFOPATH for tools",0,\$info);
$opts->def_bool("java","do you want to set CLASSPATH for tools",1,\$java);
$opts->def_bool("perl","do you want to set PERL5LIB for tools",0,\$perl);
$opts->def_bool("txmd","do you want to set XML_CATALOG_FILES for tools",0,\$txmd);
$opts->def_bool("sgml","do you want to set SGML_CATALOG_FILES for tools",0,\$sgml);
$opts->def_bool("sgpl","do you want to set SGML_SEARCH_PATH for tools",0,\$sgpl);
$opts->def_bool("pyth","do you want to set PYTHONPATH for tools",1,\$pyth);
$opts->def_bool("base","do you want perl baseline executables settings (this is for libs and bins)",1,\$base);
$opts->def_bool("cdpa","do you want to set the CDPATH for development",1,\$cdpa);
$opts->def_bool("cdch","do you want to cd to your change on login",1,\$cdch);
$opts->def_bool("colo","do you want ls baseline coloring",0,\$colo);
$opts->def_bool("lsco","do you want ls standard coloring",0,\$lsco);
$opts->def_bool("long","do you want --long opt for ls coloring",1,\$long);
$opts->def_bool("pete","do you want aegis type (Peter) shortcuts (only valid for bash)",0,\$pete);
$opts->def_bool("nprj","do you want to set your AEGIS_PROJECT from your aegis prefs",1,\$nprj);
$opts->def_bool("nchn","do you want to set your AEGIS_CHANGE from your aegis prefs",1,\$nchn);
$opts->def_bool("blxx","do you want to set the BL environment variable to point to the baseline",1,\$blxx);
$opts->def_bool("chxx","do you want to set the CH environment variable to point to the change",1,\$chxx);
$opts->def_bool("ps1x","do you want to set the PS1 environment variable for the shell",1,\$ps1x);
$opts->def_bool("page","do you want to set the PAGER environment varialbe",1,\$page);
$opts->def_bool("manp","do you want to set the MANPAGER variable",1,\$manp);
$opts->def_file("prof","where is your aegis profile located","/local/tools/share/aegis/profile",\$prof);
$opts->def_bool("verb","do you want verbosity",0,\$verb);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

# prepare the environment hash

my($env)=Meta::Ds::Ohash->new();

# read the project hash table

my($hash)=Meta::Baseline::Aegis::rc_set();

# Lets get the change directory,baseline directory and search path
# from the aesub program

my($aegi_proj)=Meta::Baseline::Aegis::project();
my($aegi_chan)=Meta::Baseline::Aegis::change();
my($aegi_base)=Meta::Baseline::Aegis::baseline();
my($aegi_stat)=Meta::Baseline::Aegis::state();
my($aegi_sear)=Meta::Baseline::Aegis::search_path();
my($aegi_inch)=Meta::Baseline::Aegis::inside_change();
my($aegi_change_dir)=Meta::Baseline::Aegis::work_dir();
my($aegi_baseline_dir)=Meta::Baseline::Aegis::baseline();

# Lets declare the script variable to hold the script

my(@scri);

# Lets give MANPATH its own value so we could (potentially) change it

my($mpth)=Meta::Utils::System::system_out("man",["--path"]);
$env->insert("MANPATH",$$mpth);
$env->insert("INFOPATH","/usr/share/info");

# Lets start handling of the options.

if($binx) {
	develop_envx_addx_mult("PATH",":",$aegi_sear,"/bins/".$bplt,1,$env);
}
if($ldxx) {
	develop_envx_addx_mult("LD_LIBRARY_PATH",":",$aegi_sear,"/dlls/".$dplt,1,$env);
}
if($manx) {
	develop_envx_addx_mult("MANPATH",":",$aegi_sear,"/manx",1,$env);
}
if($info) {
	develop_envx_addx_mult("INFOPATH",":",$aegi_sear,"/info",1,$env);
}
if($java) {
	develop_envx_addx_mult("CLASSPATH",":",$aegi_sear,"/objs/java/lib",1,$env);
}
if($perl) {
	develop_envx_addx_mult("PERL5LIB",":",$aegi_sear,"/perl/lib",1,$env);
}
if($txml) {
	develop_envx_addx_mult("XML_CATALOG_FILES",":",$aegi_sear,"/dtdx/CATALOG",1,$env);
}
if($sgml) {
	develop_envx_addx_mult("SGML_CATALOG_FILES",":",$aegi_sear,"/dtdx/CATALOG",1,$env);
}
if($sgpl) {
	develop_envx_addx_mult("SGML_SEARCH_PATH",":",$aegi_sear,"/dtdx",1,$env);
}
if($pyth) {
	develop_envx_addx_mult("PYTHONPATH",":",$aegi_sear,"/pyth/lib",1,$env);
}
if($base) {
	develop_envx_addx_mult("PERL5LIB",":",$aegi_sear,"/perl/lib",1,$env);
	develop_envx_addx_mult("PATH",":",$aegi_sear,"/perl/bin/Meta/Baseline",1,$env);
}
if($cdpa) {
	develop_envx_addx_mult("CDPATH",":",$aegi_sear,"",1,$env);
	develop_envx_addx("CDPATH",":",".",1,$env);
}
if($cdch) {
	if($aegi_inch) {
		develop_scri_addx(\@scri,"cd ".$aegi_change_dir);
	}
}
if($colo) {
	my($scri)=Meta::Baseline::Aegis::which("perl/bin/Meta/Baseline/develop_cook_colors.pl");
	my($opt);
	if($long) {
		$opt="--longopt";
	} else {
		$opt="--nolongopt";
	}
#	FIXME
#	my($colors)=$(develop_aegi_find "perl/bin/Meta/Baseline/develop_cook_colors.pl")
#	eval $($colors $opt)
}
if($lsco) {
	develop_scri_addx(\@scri,"alias ls=\'ls --color=auto'");
}
if($long) {
#	develop_scri_addx(\@scri,"long",1);
}
if($pete) {
	develop_scri_addx(\@scri,"if [ -r ".$prof." ]");
	develop_scri_addx(\@scri,"then");
	develop_scri_addx(\@scri,"\tsource ".$prof);
	develop_scri_addx(\@scri,"else");
	develop_scri_addx(\@scri,"\techo \"cannot source [".$prof."]\"");
	develop_scri_addx(\@scri,"fi");
}
if($nprj) {
	$env->insert("AEGIS_PROJECT",$aegi_proj);
}
if($nchn) {
	if($aegi_inch) {
		$env->insert("AEGIS_CHANGE",$aegi_chan);
	}
}
if($blxx) {
	$env->insert("BL",$aegi_baseline_dir);
}
if($chxx) {
	if($aegi_inch) {
		$env->insert("CH",$aegi_change_dir);
	}
}
if($ps1x) {
	$env->insert("PS1","\\u:\\h:\\w> ");
}
if($page) {
	$env->insert("PAGER","less -csi");
}
if($manp) {
	$env->insert("MANPAGER","less -csi");
}
if($tbin) {
	develop_envx_addx_mult("PATH",":",$tvbi,"",1,$env);
}
if($tldx) {
	develop_envx_addx_mult("LD_LIBRARY_PATH",":",$tvld,"",1,$env);
}
if($tman) {
	develop_envx_addx_mult("MANPATH",":",$tvma,"",1,$env);
}
if($tinf) {
	develop_envx_addx_mult("INFOPATH",":",$tvin,"",1,$env);
}
if($txmd) {
	develop_envx_addx_mult("XML_CATALOG_FILES",":",$xmli,"",0,$env);
}
if($tsgm) {
	develop_envx_addx_mult("SGML_CATALOG_FILES",":",$sgmi,"",0,$env);
}
if($tsgp) {
	develop_envx_addx_mult("SGML_SEARCH_PATH",":",$sgpi,"",0,$env);
}
if($tsgs) {
	develop_envx_addx_mult("SGML_PATH",":",$sgpi,"",0,$env);
}
if($verb) {
	Meta::Utils::Output::print("aegi_proj=[".$aegi_proj."]\n");
	Meta::Utils::Output::print("aegi_chan=[".$aegi_chan."]\n");
	Meta::Utils::Output::print("aegi_base=[".$aegi_base."]\n");
	Meta::Utils::Output::print("aegi_stat=[".$aegi_stat."]\n");
	Meta::Utils::Output::print("aegi_sear=[".$aegi_sear."]\n");
	Meta::Utils::Output::print("aegi_inch=[".$aegi_inch."]\n");
}

# Lets get a temp file for the script. Open it,put the script in,and close it

#my($temp)=Meta::Utils::Utils::get_temp_file();
#open(TEMP,"> ".$temp) || throw Meta::Error::Simple("unable to open temp file [".$temp."]");
for(my($i)=0;$i<=$#scri;$i++) {
	print $scri[$i]."\n";
}
for(my($i)=0;$i<$env->size();$i++) {
	print "export ".$env->key($i)."='".$env->val($i)."'\n";
}
#print TEMP "rm -f ".$temp."\n";# Watch closly now. Are you watching now ?
#close(TEMP) || throw Meta::Error::Simple("unable to close temp file [".$temp."]");
#if($verb) {
#	Meta::Utils::Output::print("wrote script to [".$temp."]\n");
#}

# Thats it. Lets run the shell,and tell it to read our initialization to make
# everything uniform...

#exec($shel,"--rcfile",$temp);

# exit with a success exit code

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

develop_rc.pl - a development startup script.

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

	MANIFEST: develop_rc.pl
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	develop_rc.pl

=head1 DESCRIPTION

"AEGIS - the best project manager this side of the sahara..."
As usual - take heed...
This is the standard text to be a Meta developer.
Place this text in a fixed location (~/.develop_rc /etc/develop_rc
etc...) and source it at startup.
some explanation on this file:
This file exists because when we want to work on the baseline we have to
set a few environment variables for the command line to work (we do work
on the command line...).
setting environment variables is not done from perl or other language
scripts but rather from a shell script (the same one your'e using -
currently bash2)
because:
0. its not a practice to change your parent process data (it seems to me
that you cant realy do that without the concent of your parent process).
1. its difficut.
2. its non standard.
3. I hate it.
4. Its impossible.
Therefore we wrote this script.
This script should be "sourced" as this is the only way to change the
env variables of the calling process.
Routines here are characterised by the fact that they change the
environment parameters of the calling shell.
A rule of thumb about putting routines here should be:
if the routine is supposed to deal with environment parameters it
should be here
if not - write a perl script instead.
The routines here change the runtime affecting values of variables - not
the compile time ones...

Important for developers:

It is important that all the interactive stuff be done AFTER the basic path
settings since they may run a few executables and those will need to path
settings in order to run...

=head1 OPTIONS

=over 4

=item B<help> (type: bool, default: 0)

display help message

=item B<pod> (type: bool, default: 0)

display pod options snipplet

=item B<man> (type: bool, default: 0)

display manual page

=item B<quit> (type: bool, default: 0)

quit without doing anything

=item B<gtk> (type: bool, default: 0)

run a gtk ui to get the parameters

=item B<license> (type: bool, default: 0)

show license and exit

=item B<copyright> (type: bool, default: 0)

show copyright and exit

=item B<description> (type: bool, default: 0)

show description and exit

=item B<history> (type: bool, default: 0)

show history and exit

=item B<aegi> (type: dire, default: /local/tools/bin)

where is your aegis located

=item B<tvbi> (type: path, default: /usr/games:/usr/sbin:/local/tools/bin)

extra path for the shell runner

=item B<tvld> (type: path, default: /local/tools/lib)

extra path for the dynamic linkder

=item B<tvma> (type: path, default: /local/tools/man)

extra path for the man pager

=item B<tvin> (type: path, default: /local/tools/info)

extra path for the info pager

=item B<xmli> (type: flst, default: )

extra path for the XML catalogs

=item B<sgmi> (type: flst, default: )

extra path for the SGML catalogs

=item B<sgpi> (type: path, default: )

extra path for the sgml path

=item B<bplt> (type: stri, default: reg.cpp.bin.dbg)

what is the binary platform you are working on

=item B<dplt> (type: stri, default: reg.cpp.dll.dbg)

what is the dll platform you are working on

=item B<shel> (type: stri, default: bash2)

what is your shell

=item B<tbin> (type: bool, default: 0)

do you want to set PATH for tools

=item B<tldx> (type: bool, default: 0)

do you want to set LD_LIBRARY_PATH for tools

=item B<tman> (type: bool, default: 1)

do you want to set MANPATH for tools

=item B<tinf> (type: bool, default: 1)

do you want to set INFOPATH for tools

=item B<txml> (type: bool, default: 0)

do you want to set XML_CATALOG_FILES for tools

=item B<tsgm> (type: bool, default: 0)

do you want to set SGML_CATALOG_FILES for tools

=item B<tsgp> (type: bool, default: 0)

do you want to set SGML_SEARCH_PATH for tools

=item B<tsgs> (type: bool, default: 0)

do you want to set SGML_PATH for tools

=item B<binx> (type: bool, default: 1)

do you want to set PATH for tools

=item B<ldxx> (type: bool, default: 1)

do you want to set LD_LIBRARY_PATH for tools

=item B<manx> (type: bool, default: 0)

do you want to set MANPATH for tools

=item B<info> (type: bool, default: 0)

do you want to set INFOPATH for tools

=item B<java> (type: bool, default: 1)

do you want to set CLASSPATH for tools

=item B<perl> (type: bool, default: 0)

do you want to set PERL5LIB for tools

=item B<txmd> (type: bool, default: 0)

do you want to set XML_CATALOG_FILES for tools

=item B<sgml> (type: bool, default: 0)

do you want to set SGML_CATALOG_FILES for tools

=item B<sgpl> (type: bool, default: 0)

do you want to set SGML_SEARCH_PATH for tools

=item B<pyth> (type: bool, default: 1)

do you want to set PYTHONPATH for tools

=item B<base> (type: bool, default: 1)

do you want perl baseline executables settings (this is for libs and bins)

=item B<cdpa> (type: bool, default: 1)

do you want to set the CDPATH for development

=item B<cdch> (type: bool, default: 1)

do you want to cd to your change on login

=item B<colo> (type: bool, default: 0)

do you want ls baseline coloring

=item B<lsco> (type: bool, default: 0)

do you want ls standard coloring

=item B<long> (type: bool, default: 1)

do you want --long opt for ls coloring

=item B<pete> (type: bool, default: 0)

do you want aegis type (Peter) shortcuts (only valid for bash)

=item B<nprj> (type: bool, default: 1)

do you want to set your AEGIS_PROJECT from your aegis prefs

=item B<nchn> (type: bool, default: 1)

do you want to set your AEGIS_CHANGE from your aegis prefs

=item B<blxx> (type: bool, default: 1)

do you want to set the BL environment variable to point to the baseline

=item B<chxx> (type: bool, default: 1)

do you want to set the CH environment variable to point to the change

=item B<ps1x> (type: bool, default: 1)

do you want to set the PS1 environment variable for the shell

=item B<page> (type: bool, default: 1)

do you want to set the PAGER environment varialbe

=item B<manp> (type: bool, default: 1)

do you want to set the MANPAGER variable

=item B<prof> (type: file, default: /local/tools/share/aegis/profile)

where is your aegis profile located

=item B<verb> (type: bool, default: 0)

do you want verbosity

=back

no free arguments are allowed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV move tests to modules
	0.01 MV finish papers
	0.02 MV md5 issues

=head1 SEE ALSO

Error(3), File::Basename(3), Meta::Baseline::Aegis(3), Meta::Ds::Ohash(3), Meta::Utils::File::File(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), POSIX(3), strict(3)

=head1 TODO

-get the $- variable from the shell as input (the shell has it) and use it to make checks whether this script runs interactivly or not...

-make routine in here more accessible in that users could change their platform / architecture in the middle of a shell session.

-make options to put the development stuff ahead of everything and the reverse.

-make stuff here more generic (all the variables are handled pretty much the same...).

-make the coloring work again (the code is commented).

-remove the functions here which have to do with paths, evnrionment and the like and use my modules instead.

-add an option to set default posgresql and mysql env variables here (like default database name and other stuff).
