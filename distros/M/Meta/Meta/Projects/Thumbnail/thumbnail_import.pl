#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Db::Def qw();
use Meta::Db::Connections qw();
use Meta::Db::Dbi qw();
use Meta::Utils::File::File qw();
use Image::Magick qw();
use Digest::MD5 qw();
use Meta::Utils::File::Iterator qw();
use GD qw();
use Image::GD::Thumbnail qw();
use Meta::Image::Magick qw();
use Meta::Db::Info qw();
use Meta::Sql::Stats qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::File::Prop qw();
use File::MMagic qw();
use Error qw(:try);

my($def_file,$connections_file,$name,$con_name,$clean,$verb,$demo,$dire,$thumb_y,$thumb_x);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("def_file","what def XML file to use ?","xmlx/def/thumbnail.xml",\$def_file);
$opts->def_modu("connections_file","what connections XML file to use ?","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("name","which database name ?",undef,\$name);
$opts->def_stri("con_name","which connection name ?",undef,\$con_name);
$opts->def_bool("clean","clean the database before import ?",1,\$clean);
$opts->def_bool("verbose","should I be noisy ?",1,\$verb);
$opts->def_bool("demo","should I really do it ?",0,\$demo);
$opts->def_devd("directory","which directory to use ?","jpgx",\$dire);
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
my($prep)=$dbi->prepare("INSERT INTO node (width,height,name,thumb,checksum,inode) VALUES (?,?,?,?,?,?);");

my($mm)=File::MMagic->new();

$dire=Meta::Baseline::Aegis::which_dir($dire);
my($iter)=Meta::Utils::File::Iterator->new();
$iter->add_directory($dire);
$iter->start();
while(!($iter->get_over())) {
	my($curr)=$iter->get_curr();
	#find out if file is jpg
	my($type)=$mm->checktype_filename($curr);
	Meta::Utils::Output::verbose($verb,"considering [".$curr."] with type [".$type."]\n");
	if($type eq "image/jpeg") {
		Meta::Utils::Output::verbose($verb,"importing [".$curr."]\n");
		my($data);
		Meta::Utils::File::File::load($curr,\$data);
		my($image)=Meta::Image::Magick->new(magick=>'jpg');
		$image->BlobToImage($data);
		my($width,$height)=$image->Get('width','height');

		#GD implementation
		#my($gdimage)=GD::Image->newFromJpegData($data);
		#my($gdthumb)=Image::GD::Thumbnail::create($gdimage,$thumb_y);
		#my($thumb)=$gdthumb->jpeg();

		#ImageMagick implementation
		#$image->Resize(height=>$thumb_y,width=>$thumb_x);
		#$image->Scale(height=>$thumb_y,width=>$thumb_x);
		$image->Thumb($thumb_x,$thumb_y);
		my($thumb)=$image->ImageToBlob();

		my($checksum)=Digest::MD5::md5($data);
		my($rv1)=$prep->bind_param(1,$width);
		if(!$rv1) {
			throw Meta::Error::Simple("unable to bind param 1");
		}
		my($rv2)=$prep->bind_param(2,$height);
		if(!$rv2) {
			throw Meta::Error::Simple("unable to bind param 2");
		}
		my($rv3)=$prep->bind_param(3,$curr);
		if(!$rv3) {
			throw Meta::Error::Simple("unable to bind param 3");
		}
		my($rv4)=$prep->bind_param(4,$dbi->quote($thumb,DBI::SQL_BINARY),{ TYPE=>"SQL_BINARY" });
		if(!$rv4) {
			throw Meta::Error::Simple("unable to bind param 4");
		}
		my($rv5)=$prep->bind_param(5,$dbi->quote($checksum,DBI::SQL_BINARY),{ TYPE=>"SQL_BINARY" });
		if(!$rv5) {
			throw Meta::Error::Simple("unable to bind param 5");
		}
		my($sb)=Meta::Utils::File::Prop::stat($curr);
		my($inode)=$sb->ino();
		my($rv6)=$prep->bind_param(6,$inode);
		if(!$rv6) {
			throw Meta::Error::Simple("unable to bind param 6");
		}
		#Meta::Utils::Output::print("going to execute\n");
		if(!$demo) {
			my($prv)=$prep->execute();
			if(!$prv) {
				throw Meta::Error::Simple("unable to execute statement");
			}
		}
	}
	$iter->next();
}
$iter->fini();

$dbi->commit();
$dbi->disconnect();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

thumbnail_import.pl - import images in a directory to a thumbnail database.

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

	MANIFEST: thumbnail_import.pl
	PROJECT: meta
	VERSION: 0.15

=head1 SYNOPSIS

	thumbnail_import.pl [options]

=head1 DESCRIPTION

This program imports a directory with images in it into the thumbnail database.
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

=item B<def_file> (type: modu, default: xmlx/def/thumbnail.xml)

what def XML file to use ?

=item B<connections_file> (type: modu, default: xmlx/connections/connections.xml)

what connections XML file to use ?

=item B<name> (type: stri, default: )

which database name ?

=item B<con_name> (type: stri, default: )

which connection name ?

=item B<clean> (type: bool, default: 1)

clean the database before import ?

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

=item B<demo> (type: bool, default: 0)

should I really do it ?

=item B<directory> (type: devd, default: jpgx)

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

	0.00 MV md5 progress
	0.01 MV thumbnail project basics
	0.02 MV more thumbnail code
	0.03 MV more thumbnail stuff
	0.04 MV thumbnail user interface
	0.05 MV import tests
	0.06 MV more thumbnail issues
	0.07 MV md5 project
	0.08 MV paper writing
	0.09 MV website construction
	0.10 MV improve the movie db xml
	0.11 MV web site automation
	0.12 MV SEE ALSO section fix
	0.13 MV move tests to modules
	0.14 MV teachers project
	0.15 MV md5 issues

=head1 SEE ALSO

Digest::MD5(3), Error(3), File::MMagic(3), GD(3), Image::GD::Thumbnail(3), Image::Magick(3), Meta::Baseline::Aegis(3), Meta::Db::Connections(3), Meta::Db::Dbi(3), Meta::Db::Def(3), Meta::Db::Info(3), Meta::Image::Magick(3), Meta::Sql::Stats(3), Meta::Utils::File::File(3), Meta::Utils::File::Iterator(3), Meta::Utils::File::Prop(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-add importing of directory structure.

-add importing of file system stuff (inode etc...).

-maybe use Net::Pbm or whatever the gallery project uses to produce good thumbnails.
