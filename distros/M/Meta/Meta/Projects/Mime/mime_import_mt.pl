#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use MIME::Types qw();
use Meta::Projects::Mime::MimeTypes qw();
use Meta::Projects::Mime::Extensions qw();
use Meta::Db::Connections qw();
use Meta::Db::Dbi qw();
use Meta::Db::Ops qw();
use Meta::Class::DBI qw();

my($connections_file,$con_name,$name,$verb,$clean);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("connections_file","what connections XML file to use ?","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("con_name","what connection name ?",undef,\$con_name);
$opts->def_stri("name","what database name ?","mime",\$name);
$opts->def_bool("verbose","noisy or quiet ?",1,\$verb);
$opts->def_bool("clean","should I clean the database before ?",1,\$clean);
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

my($line);
my($mimetypes_id,$extensions_id)=(1,1);
while($line=<MIME::Types::DATA>) {
#	Meta::Utils::Output::print("line is [".$line."]\n");
	chop($line);
	if($line eq "" or $line=~/^#/) {
		next;
	}
	my(@fields)=split(' ',$line);
	my($name,$os,$extensions,$encoding);
	$extensions=undef;
	$encoding="standard";
	$os="linux,vms,mvs,mac,dos,windows";
	$name=$fields[0];
	if($name=~/:/) {
		($os,$name)=split(':',$name);
	}
	if($#fields==1) {
		$extensions=$fields[1];
	}
	if($#fields==2) {
		$extensions=$fields[1];
		$encoding=$fields[2];
	}
	if($verb) {
		Meta::Utils::Output::print("name is [".$name."]\n");
		Meta::Utils::Output::print("os is [".$os."]\n");
		Meta::Utils::Output::print("extensions is [".$extensions."]\n");
		Meta::Utils::Output::print("encoding is [".$encoding."]\n");
	}
	my($mime)=Meta::Projects::Mime::MimeTypes->new({});
#	$mime->id($mimetypes_id);#no need for this (MYSQL does automatically)
	$mime->type($name);
	$mime->encoding($encoding);
	$mime->osmask($os);
	$mime->commit();
	if(defined($extensions)) {
		my(@exts)=split(',',$extensions);
		for(my($i)=0;$i<=$#exts;$i++) {
			my($curr)=$exts[$i];
			my($extension)=Meta::Projects::Mime::Extensions->new({});
			#$extension->id($extensions_id);#no need for this (MYSQL does this automatically)
			$extensions_id++;
			$extension->extension($curr);
			$extension->mimetype($mime->id());
			$extension->commit();
		}
	}
	$mimetypes_id++;
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

mime_import_mt.pl - import mime types from the Mime::Types CPAN module into RDBMS.

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

	MANIFEST: mime_import_mt.pl
	PROJECT: meta
	VERSION: 0.03

=head1 SYNOPSIS

	mime_import_mt.pl [options]

=head1 DESCRIPTION

This program requires the installation of the Mime::Types modules for perl and it
imports all the mime types that that module knows into an RDBMS.

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

=item B<name> (type: stri, default: mime)

what database name ?

=item B<verbose> (type: bool, default: 1)

noisy or quiet ?

=item B<clean> (type: bool, default: 1)

should I clean the database before ?

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

	0.00 MV bring movie data
	0.01 MV move tests into modules
	0.02 MV teachers project
	0.03 MV md5 issues

=head1 SEE ALSO

MIME::Types(3), Meta::Class::DBI(3), Meta::Db::Connections(3), Meta::Db::Dbi(3), Meta::Db::Ops(3), Meta::Projects::Mime::Extensions(3), Meta::Projects::Mime::MimeTypes(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-do I really need to give out ids ? cant mysql take care of that ?
