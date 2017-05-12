#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::File::Iterator qw();
use Meta::Utils::File::Prop qw();
use Meta::Digest::MD5 qw();
use Meta::Projects::Md5::Node qw();
use Meta::Projects::Md5::Edge qw();
use Meta::Db::Connections qw();
use Meta::Db::Dbi qw();
use Meta::Db::Ops qw();
use Meta::Class::DBI qw();
use Meta::Ds::Hash qw();
use Fcntl qw();

my($connections_file,$con_name,$name,$clean,$dire,$verb);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("connections_file","what connections XML file to use ?","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("con_name","what connection name ?",undef,\$con_name);
$opts->def_stri("name","what database name ?","md5",\$name);
$opts->def_bool("clean","should I clean the database before ?",0,\$clean);
$opts->def_dire("directory","what directory to scan ?",undef,\$dire);
$opts->def_bool("verbose","should I be noisy ?",1,\$verb);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($connections)=Meta::Db::Connections->new_modu($connections_file);
my($connection)=$connections->get_con_null($con_name);

if($clean) {
	#clean the database
	my($dbi)=Meta::Db::Dbi->new();
	$dbi->connect_name($connection,$name);
	Meta::Db::Ops::clean_sa($dbi);
	$dbi->disconnect();
}

Meta::Class::DBI::set_connection($connection,$name);

sub insert($$$$) {
	my($sb,$curr,$base,$dire)=@_;
	#Meta::Utils::Output::verbose($verb,"in insert with curr [".$curr."]\n");
	#Meta::Utils::Output::verbose($verb,"in insert with base [".$base."]\n");
	#Meta::Utils::Output::verbose($verb,"in insert with dire [".$dire."]\n");
	if($curr eq "") {
		return;
	}
	my($node)=Meta::Projects::Md5::Node->create({});
	$node->mod_time($sb->mtime());
	$node->inode($sb->ino());
	$node->name($base);
	$node->size($sb->size());
	$node->mode($sb->mode());
	if(Fcntl::S_ISREG($sb->mode())) {
		$node->checksum(Meta::Digest::MD5::get_filename_digest($curr));
	}
	$node->commit();
	#now connect the file to its directory
	my($sd)=Meta::Utils::File::Prop::stat($dire);
	my($dir_inode)=$sd->ino();
	my(@found)=Meta::Projects::Md5::Node->search("inode"=>$sd->ino());
	if($#found==0) {#found exactly one parent dir
		my($directory_node)=$found[0];
		my($edge)=Meta::Projects::Md5::Edge->create({});
		$edge->from_node_id($directory_node->id());
		$edge->to_node_id($node->id());
		$edge->commit();
	}
	if($#found>0) {#found more than one parent dir ?
		throw Meta::Error::Simple("inode [".$sd->ino."] for directory [".$dire."] more than once in the database");
	}
	if($#found==-1) {#havent found the parent
		insert(
			$sd,
			$dire,
			File::Basename::basename($dire),
			File::Basename::dirname($dire)
		);
	}
}

my($iterator)=Meta::Utils::File::Iterator->new();
$iterator->set_want_dirs(1);
$iterator->set_want_files(1);
$iterator->add_directory($dire);

$iterator->start();
while(!$iterator->get_over()) {
	my($curr)=$iterator->get_curr();
	my($base)=$iterator->get_base();
	my($dire)=$iterator->get_dire();
	Meta::Utils::Output::verbose($verb,"curr is [".$curr."]\n");
	#Meta::Utils::Output::verbose($verb,"base is [".$base."]\n");
	#Meta::Utils::Output::verbose($verb,"dire is [".$dire."]\n");
	my($sb)=Meta::Utils::File::Prop::stat($curr);
	my(@found)=Meta::Projects::Md5::Node->search("inode"=>$sb->ino());
	if($#found==-1) {#is not in the database
		insert($sb,$curr,$base,$dire);
	}
	if($#found==0) {#is in the database
		#update the md5 sum if the data is bigger
		my($db_node)=$found[0];
		if($sb->mtime()>$db_node->mod_time()) {#hard disk is newer than db
			insert($sb,$curr,$base,$dire);
		}
	}
	if($#found>0) {#more than once in the database ?!?
		throw Meta::Error::Simple("inode [".$sb->ino."] for file [".$curr."] more than once in the database");
	}
	$iterator->next();
}
$iterator->fini();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

md5_import.pl - import directory md5 data into a database.

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

	MANIFEST: md5_import.pl
	PROJECT: meta
	VERSION: 0.15

=head1 SYNOPSIS

	md5_import.pl [options]

=head1 DESCRIPTION

This script receives a directory, traverses it, and adds it's data
to a given Md5 database. The resulting data base will the 
information about the hirarchy of the directory and checksum
information on each file.

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

=item B<name> (type: stri, default: md5)

what database name ?

=item B<clean> (type: bool, default: 0)

should I clean the database before ?

=item B<directory> (type: dire, default: )

what directory to scan ?

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

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

	0.00 MV movie stuff
	0.01 MV more thumbnail code
	0.02 MV more thumbnail stuff
	0.03 MV thumbnail user interface
	0.04 MV import tests
	0.05 MV more thumbnail issues
	0.06 MV md5 project
	0.07 MV website construction
	0.08 MV improve the movie db xml
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV move tests to modules
	0.12 MV download scripts
	0.13 MV teachers project
	0.14 MV more pdmt stuff
	0.15 MV md5 issues

=head1 SEE ALSO

Fcntl(3), Meta::Class::DBI(3), Meta::Db::Connections(3), Meta::Db::Dbi(3), Meta::Db::Ops(3), Meta::Digest::MD5(3), Meta::Ds::Hash(3), Meta::Projects::Md5::Edge(3), Meta::Projects::Md5::Node(3), Meta::Utils::File::Iterator(3), Meta::Utils::File::Prop(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-make this script also do update smoothly.
