#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Projects::Dbman::Page qw();
use Meta::Projects::Dbman::Section qw();
use Meta::Utils::File::Iterator qw();
use Meta::Utils::Output qw();
use Meta::Utils::File::File qw();
use Compress::Zlib qw();
use Meta::Tool::Groff qw();
use Meta::Utils::Progress qw();
use Meta::Db::Ops qw();
use Meta::Db::Connections qw();
use Meta::Db::Dbi qw();
use Meta::Class::DBI qw();
use Meta::File::MMagic qw();
use Meta::Tool::Man qw();

my($connections_file,$con_name,$name,$verbose,$clean,$sections,$pages,$demo,$import_description,$import_troff,$import_ascii,$import_ps,$import_dvi,$import_html,$dlst,$man_path);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("connections_file","what connections XML file to use ?","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("con_name","what connection name ?",undef,\$con_name);
$opts->def_stri("name","what database name ?","dbman",\$name);
$opts->def_bool("verbose","should I be noisy ?",1,\$verbose);
$opts->def_bool("clean","should I clean the database before ?",1,\$clean);
$opts->def_bool("sections","import sections ?",1,\$sections);
$opts->def_bool("pages","import pages ?",1,\$pages);
$opts->def_bool("demo","fake it ?",0,\$demo);
$opts->def_bool("import_description","import description ?",1,\$import_description);
$opts->def_bool("import_troff","import troff format ?",1,\$import_troff);
$opts->def_bool("import_ascii","import ascii format ?",1,\$import_ascii);
$opts->def_bool("import_ps","import ps format ?",1,\$import_ps);
$opts->def_bool("import_dvi","import dvi format ?",1,\$import_dvi);
$opts->def_bool("import_html","import html format ?",1,\$import_html);
$opts->def_dlst("dirs","directory path to scan","/local/tools/man",\$dlst);
$opts->def_bool("man_path","take path to import from man ?",1,\$man_path);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

if($man_path) {
	$dlst=Meta::Tool::Man::path();
}

my($connections)=Meta::Db::Connections->new_modu($connections_file);
my($connection)=$connections->get_con_null($con_name);

my($mm)=Meta::File::MMagic->new();

if($clean) {
	#clean the database
	my($dbi)=Meta::Db::Dbi->new();
	$dbi->connect_name($connection,$name);
	Meta::Db::Ops::clean_sa($dbi);
	$dbi->disconnect();
}

Meta::Class::DBI::set_connection($connection,$name);

my(%map_hash)=(
	"1","1",
	"2","2",
	"3","3",
	"4","4",
	"5","5",
	"6","6",
	"7","7",
	"8","8",
	"9","9",
	"n","n",
	"h","n",
	"l","n",
	"1ssl","1",
	"1m","1",
	"1x","1",
	"3pm","3",
	"3x","3",
	"3thr","3",
	"3qt","3",
	"3t","3",
	"3ncp","3",
	"3ssl","3",
	"5ssl","5",
	"5x","5",
	"6x","6",
	"7ssl","7",
	"8c","8",
);
my($names)=[
	"Section 1",
	"Section 2",
	"Section 3",
	"Section 4",
	"Section 5",
	"Section 6",
	"Section 7",
	"Section 8",
	"Section 9",
	"Section n",
];
my($descriptions)=[
	"User Commands",
	"System Calls",
	"Subroutines",
	"Devices",
	"File Formats",
	"Games",
	"Miscellaneous",
	"System Administration",
	"Kernel",
	"New",
];
my($tags)=[
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"n",
];

if($sections) {
	#setup all the sections
	for(my($i)=0;$i<=$#$names;$i++) {
		my($name)=$names->[$i];
		my($description)=$descriptions->[$i];
		my($tag)=$tags->[$i];
		if(!$demo) {
			my($section)=Meta::Projects::Dbman::Section->create({});
			$section->name($name);
			$section->description($description);
			$section->tag($tag);
			$section->commit();
		}
	}
}

if($pages) {
	#create a tag -> section id mapping
	my(%mapping);
	my(@sections)=Meta::Projects::Dbman::Section->retrieve_all();
	for(my($i)=0;$i<=$#sections;$i++) {
		my($curr)=$sections[$i];
		$mapping{$curr->tag()}=$curr->id();
	}
	my($iter)=Meta::Utils::File::Iterator->new();
	$iter->set_want_dirs(0);
	$iter->set_want_files(1);
	$iter->add_directories($dlst,":");
	$iter->start();
	my($progress)=Meta::Utils::Progress->new();
	$progress->start();
	while(!($iter->get_over())) {
		my($curr)=$iter->get_curr();
		Meta::Utils::Output::verbose($verbose,"curr is [".$curr."]\n");
		my($name,$description,$tag,$contenttroff,$contenttroff_unzipped);
		#uncompressed file
		my($res)=$mm->checktype_filename($curr);
		Meta::Utils::Output::verbose($verbose,"type is [".$res."]\n");
		my($doit)=0;
		if($res eq "text/x-roff") {
		#if($curr=~m/\/man.*\/.*\..*$/) {
			#Meta::Utils::Output::print("curr is [".$curr."]\n");
			Meta::Utils::File::File::load($curr,\$contenttroff_unzipped);
			#compress is
			$contenttroff=Compress::Zlib::memGzip($contenttroff_unzipped);
			($name,$tag)=($curr=~/\/man.*\/(.*)\.(.*)$/);
			$doit=1;
		}
		#gzip compressed file
		if($curr=~m/\/man.*\/.*\..*\.gz$/) {
			Meta::Utils::File::File::load($curr,\$contenttroff);
			$contenttroff_unzipped=Compress::Zlib::memGunzip($contenttroff);
			($name,$tag)=($curr=~/\/man.*\/(.*)\.(.*)\.gz$/);
			$doit=1;
		}
		#bzip compressed file
		if($curr=~m/\/man.*\/.*\..*\.bz2$/) {
			Meta::Utils::File::File::load($curr,\$contenttroff);
			$contenttroff_unzipped=Compress::Bzip2::decompress($contenttroff);
			($name,$tag)=($curr=~/\/man.*\/(.*)\.(.*)\.bz2$/);
			$doit=1;
		}
		if($doit) {
			my($section);
			if(exists($map_hash{$tag})) {
				my($map_tag)=$map_hash{$tag};
				if(exists($mapping{$map_tag})) {
					$section=$mapping{$map_tag};
				} else {
					throw Meta::Error::Simple("internal mapping problem");
				}
			} else {
				throw Meta::Error::Simple("internal mapping problem");
			}
			#extract description from content
			if(!$demo) {
				my($page)=Meta::Projects::Dbman::Page->create({});
				$page->section($section);
				$page->name($name);
				if($import_description) {
					$description=Meta::Tool::Groff::get_oneliner($contenttroff_unzipped);
					$page->description($description);
				}
				if($import_troff) {
					$page->contenttroff($contenttroff);
				}
				if($import_ascii) {
					my($contentascii)=Compress::Zlib::memGzip(Meta::Tool::Groff::process($contenttroff_unzipped,"ascii"));
					$page->contentascii($contentascii);
				}
				if($import_ps) {
					my($content)=Compress::Zlib::memGzip(Meta::Tool::Groff::process($contenttroff_unzipped,"ps"));
					$page->contentps($content);
				}
				if($import_dvi) {
					my($content)=Compress::Zlib::memGzip(Meta::Tool::Groff::process($contenttroff_unzipped,"dvi"));
					$page->contentdvi($content);
				}
				if($import_html) {
					my($content)=Compress::Zlib::memGzip(Meta::Tool::Groff::process($contenttroff_unzipped,"html"));
					$page->contenthtml($content);
				}
				$page->filename($curr);
				$page->commit();
			}
		} else {
			Meta::Utils::Output::print("not matched [".$curr."]\n");
		}
		$iter->next();
		$progress->report();
	}
	$iter->fini();
	$progress->finish();
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

dbman_import.pl - import manual pages into the dbman database.

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

	MANIFEST: dbman_import.pl
	PROJECT: meta
	VERSION: 0.10

=head1 SYNOPSIS

	dbman_import.pl [options]

=head1 DESCRIPTION

This program imports the on-disk manual pages specified by a search path
and puts them into the dbman RDBMS.

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

=item B<connections_file> (type: modu, default: xmlx/connections/connections.xml)

what connections XML file to use ?

=item B<con_name> (type: stri, default: )

what connection name ?

=item B<name> (type: stri, default: dbman)

what database name ?

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

=item B<clean> (type: bool, default: 1)

should I clean the database before ?

=item B<sections> (type: bool, default: 1)

import sections ?

=item B<pages> (type: bool, default: 1)

import pages ?

=item B<demo> (type: bool, default: 0)

fake it ?

=item B<import_description> (type: bool, default: 1)

import description ?

=item B<import_troff> (type: bool, default: 1)

import troff format ?

=item B<import_ascii> (type: bool, default: 1)

import ascii format ?

=item B<import_ps> (type: bool, default: 1)

import ps format ?

=item B<import_dvi> (type: bool, default: 1)

import dvi format ?

=item B<import_html> (type: bool, default: 1)

import html format ?

=item B<dirs> (type: dlst, default: /local/tools/man)

directory path to scan

=item B<man_path> (type: bool, default: 1)

take path to import from man ?

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

	0.00 MV import tests
	0.01 MV dbman package creation
	0.02 MV more thumbnail issues
	0.03 MV website construction
	0.04 MV improve the movie db xml
	0.05 MV web site automation
	0.06 MV SEE ALSO section fix
	0.07 MV move tests to modules
	0.08 MV download scripts
	0.09 MV teachers project
	0.10 MV md5 issues

=head1 SEE ALSO

Compress::Zlib(3), Meta::Class::DBI(3), Meta::Db::Connections(3), Meta::Db::Dbi(3), Meta::Db::Ops(3), Meta::File::MMagic(3), Meta::Projects::Dbman::Page(3), Meta::Projects::Dbman::Section(3), Meta::Tool::Groff(3), Meta::Tool::Man(3), Meta::Utils::File::File(3), Meta::Utils::File::Iterator(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::Progress(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-use time stamps and inodes in the database to determine if things need to be updated.

-take care of all the warnings that come out when doing a full import.

-do file types with File::Mime or someting and not according to the file name.

-handle symbolic links by having multiple entries with the same manual content (two tables).
