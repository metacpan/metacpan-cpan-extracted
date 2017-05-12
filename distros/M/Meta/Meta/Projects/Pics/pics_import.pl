#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Db::Def qw();
use Meta::Db::Connections qw();
use Meta::Db::Dbi qw();
use Meta::Db::Info qw();
use Meta::Utils::File::File qw();
use Meta::Image::Magick qw();
use Digest::MD5 qw();
use Meta::Utils::File::Iter qw();
use Meta::Baseline::Aegis qw();
use Meta::Sql::Stats qw();

my($def_file,$connections_file,$name,$con_name,$clean,$verb,$dire,$thumb_y,$thumb_x);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("def_file","what def XML file to use ?","xmlx/def/pics.xml",\$def_file);
$opts->def_modu("connections_file","what connections XML file to use ?","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("name","name of the database to use ?",undef,\$name);
$opts->def_stri("con_name","name of the connection to use ?",undef,\$con_name);
$opts->def_bool("clean","clean the database before import ?",1,\$clean);
$opts->def_bool("verbose","should I be noisy ?",0,\$verb);
$opts->def_dire("directory","which directory to use ?",Meta::Baseline::Aegis::baseline()."/jpgx",\$dire);
$opts->def_inte("thumb_y","what y size for the thumbs ?",72,\$thumb_y);
$opts->def_inte("thumb_x","what x size for the thumbs ?",96,\$thumb_x);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($def)=Meta::Db::Def->new_modu($def_file);
if(!defined($name)) {
	$name=$def->get_name();
}
my($connections)=Meta::Db::Connections->new_modu($connections_file);
my($connection);
if(defined($con_name)) {
	$connection=$connections->get($con_name);
} else {
	$connection=$connections->get_def_con();
}

my($dbi)=Meta::Db::Dbi->new();
$dbi->connect_name($connection,$name);

my($info)=Meta::Db::Info->new();
$info->set_name($name);
$info->set_type($connection->get_type());

if($clean) {
	my($stats)=Meta::Sql::Stats->new();
	$def->getsql_clean($stats,$info);
	$dbi->execute($stats,$connection,$info);
}

$dbi->begin_work();
my($prep)=$dbi->prepare("INSERT INTO item (thumb,checksum,x,y,name,data) VALUES (?,?,?,?,?,?);");

my($iter)=Meta::Utils::File::Iter->new();
$iter->add_directory($dire);
$iter->start();
while(!($iter->get_over())) {
	my($curr)=$iter->get_curr();
	if($verb) {
		Meta::Utils::Output::print("importing [".$curr."]\n");
	}
	my($data);
	Meta::Utils::File::File::load($curr,\$data);
	my($image)=Meta::Image::Magick->new(magick=>'jpg');
	$image->BlobToImage($data);
	my($x,$y)=$image->Get('width','height');
	$image->Thumb($thumb_x,$thumb_y);
	my($thumb)=$image->ImageToBlob();
	my($checksum)=Digest::MD5::md5($data);
	my($rv1)=$prep->bind_param(1,$dbi->quote($thumb,DBI::SQL_BINARY),{ TYPE=>"SQL_BINARY" });
	#my($rv1)=$prep->bind_param(1,$thumb);
	if(!$rv1) {
		throw Meta::Error::Simple("unable to bind param 1");
	}
	my($rv2)=$prep->bind_param(2,$dbi->quote($checksum,DBI::SQL_BINARY),{ TYPE=>"SQL_BINARY" });
	#my($rv2=$prep->bind_param(2,$checksum);
	if(!$rv2) {
		throw Meta::Error::Simple("unable to bind param 2");
	}
	my($rv3)=$prep->bind_param(3,$x);
	if(!$rv3) {
		throw Meta::Error::Simple("unable to bind param 3");
	}
	my($rv4)=$prep->bind_param(4,$y);
	if(!$rv4) {
		throw Meta::Error::Simple("unable to bind param 4");
	}
	my($rv5)=$prep->bind_param(5,$curr);
	if(!$rv5) {
		throw Meta::Error::Simple("unable to bind param 5");
	}
	my($rv6)=$prep->bind_param(6,$dbi->quote($data,DBI::SQL_BINARY),{ TYPE=>"SQL_BINARY" });
	#my($rv6)=$prep->bind_param(6,$data);
	if(!$rv6) {
		throw Meta::Error::Simple("unable to bind param 6");
	}
	my($prv)=$prep->execute();
	if(!$prv) {
		throw Meta::Error::Simple("unable to execute statement here");
	}
	$iter->next();
}
$iter->fini();

$dbi->commit();
$dbi->disconnect();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

pics_import.pl - import images in directories to database.

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

	MANIFEST: pics_import.pl
	PROJECT: meta
	VERSION: 0.17

=head1 SYNOPSIS

	pics_import.pl [options]

=head1 DESCRIPTION

This program imports a directory with images in it into the pics database.
The program will recurse the directory given to it, will spot which files
are image files (currently according to .jpg suffix) and will upload
those files to the database. The script will also update the x and y
sizes and will create a thumbnail and checksum information in the database.
Md5 is used for the checksum and the Magick image library for the graphic
operations.

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

=item B<def_file> (type: modu, default: xmlx/def/pics.xml)

what def XML file to use ?

=item B<connections_file> (type: modu, default: xmlx/connections/connections.xml)

what connections XML file to use ?

=item B<name> (type: stri, default: )

name of the database to use ?

=item B<con_name> (type: stri, default: )

name of the connection to use ?

=item B<clean> (type: bool, default: 1)

clean the database before import ?

=item B<verbose> (type: bool, default: 0)

should I be noisy ?

=item B<directory> (type: dire, default: /local/development/projects/meta/baseline/jpgx)

which directory to use ?

=item B<thumb_y> (type: inte, default: 72)

what y size for the thumbs ?

=item B<thumb_x> (type: inte, default: 96)

what x size for the thumbs ?

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

	0.00 MV tree type organization in databases
	0.01 MV more movies
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV md5 progress
	0.06 MV thumbnail project basics
	0.07 MV more thumbnail code
	0.08 MV more thumbnail stuff
	0.09 MV thumbnail user interface
	0.10 MV more thumbnail issues
	0.11 MV website construction
	0.12 MV improve the movie db xml
	0.13 MV web site automation
	0.14 MV SEE ALSO section fix
	0.15 MV move tests to modules
	0.16 MV web site development
	0.17 MV md5 issues

=head1 SEE ALSO

Digest::MD5(3), Meta::Baseline::Aegis(3), Meta::Db::Connections(3), Meta::Db::Dbi(3), Meta::Db::Def(3), Meta::Db::Info(3), Meta::Image::Magick(3), Meta::Sql::Stats(3), Meta::Utils::File::File(3), Meta::Utils::File::Iter(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
