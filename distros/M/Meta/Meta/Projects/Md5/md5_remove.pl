#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::File::Iterator qw();
use XML::Parser qw();
use MIME::Base64 qw();
use Meta::Digest::Collection qw();
use Meta::Utils::File::File qw();
use Meta::Ds::Array qw();

my($curr_filename,$curr_moddate,$curr_md5sum,$collection);
my($premature,$predat)=0;

sub handle_char($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context());
	if($context eq "md5.stamp.filename") {
		$curr_filename=$elem;
	}
	if($context eq "md5.stamp.moddate") {
		$curr_moddate=$elem;
	}
	if($context eq "md5.stamp.md5sum") {
		if($premature) {
			$predat.=$elem;
			$curr_md5sum=MIME::Base64::decode($predat);
			$premature=0;
		} else {
			my($str)=$elem;
			$str=~ tr|A-Za-z0-9+=/||cd;# remove non-base64 chars
			if(length($str) % 4) {
				$premature=1;
#				Meta::Utils::Output::print("problem with [".$elem."]\n");
				$predat=$elem;
			} else {
				$curr_md5sum=MIME::Base64::decode($elem);
				$premature=0;
			}
		}
#		Meta::Utils::Output::print("got [".$curr_md5sum."] sum\n");
	}
}

sub handle_end($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context(),$elem);
	if($context eq "md5.stamp") {
		$collection->add($curr_filename,$curr_md5sum);
	}
}

my($input,$verb,$remove,$dire,$leave_tag,$leave_suffix,$list,$list_file,$stats);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_flst("input","what input files to use ?","/tmp/file.xml",\$input);
$opts->def_bool("verbose","noisy or quiet ?",0,\$verb);
$opts->def_bool("remove","actually remove files ?",1,\$remove);
$opts->def_dire("directory","directory to scan",".",\$dire);
$opts->def_bool("leave_tag","leave tag about removed files ?",1,\$leave_tag);
$opts->def_stri("leave_suffix","what suffix to leave ?",".rem",\$leave_suffix);
$opts->def_bool("list","make a list of removed files ?",0,\$list);
$opts->def_newf("list_file","what file to write the list to ?","/tmp/list_file.txt",\$list_file);
$opts->def_bool("stats","show statistics ?",1,\$stats);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

$collection=Meta::Digest::Collection->new();
my($parser)=XML::Parser->new();
$parser->setHandlers(
	Char=>\&handle_char,
	End=>\&handle_end,
);
my(@inputs)=split(':',$input);
for(my($i)=0;$i<=$#inputs;$i++) {
	my($curr)=$inputs[$i];
	if($verb) {
		Meta::Utils::Output::print("starting reading [".$curr."]\n");
	}
	$parser->parsefile($curr);
	if($verb) {
		Meta::Utils::Output::print("finished reading [".$curr."]\n");
	}
}

my($iterator)=Meta::Utils::File::Iterator->new();
$iterator->add_directory($dire);
$iterator->start();

my($array)=Meta::Ds::Array->new();

my($removed)=0;
my($scanned)=0;
while(!$iterator->get_over()) {
	my($curr)=$iterator->get_curr();
	if($verb) {
		Meta::Utils::Output::print("working on [".$curr."]\n");
	}
	$scanned++;
	my($sum)=Meta::Digest::MD5::get_filename_digest($curr);
	if($collection->has_sum($sum)) {
		if($verb) {
			Meta::Utils::Output::print("found dup [".$curr."]\n");
		}
		if($remove) {
			if($verb) {
				Meta::Utils::Output::print("removing [".$curr."]\n");
			}
			Meta::Utils::File::Remove::rm($curr);
			$removed++;
			if($leave_tag) {
				my($content)="file removed and exists in [".$collection->get_file($sum)."]\n";
				my($new_file)=$curr.$leave_suffix;
				Meta::Utils::File::File::save($new_file,$content);
			}
			if($list) {
				$array->push($curr);
			}
		}
	}
	$iterator->next();
}
$iterator->fini();
if($list) {
	#print the $array Meta::Ds::Array to the file $list_file
}
if($stats) {
	Meta::Utils::Output::print("removed is [".$removed."]\n");
	Meta::Utils::Output::print("scanned is [".$scanned."]\n");
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

md5_remove.pl - remove files that their md5 is in a current XML/MD5 file.

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

	MANIFEST: md5_remove.pl
	PROJECT: meta
	VERSION: 0.07

=head1 SYNOPSIS

	md5_remove.pl [options]

=head1 DESCRIPTION

Give this program an XML file with MD5 signatures and a directory to scan. The program will read the
MD5 signatures file and will store them in RAM. Then it will recurse the directory and for each file it
will calc the MD5 sum. If it finds files which have MD5 signatures that it already has then it
will remove them. The program can optionally leave a small file saying which file generated the md5
sum which caused the file to be deleted.

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

=item B<input> (type: flst, default: /tmp/file.xml)

what input files to use ?

=item B<verbose> (type: bool, default: 0)

noisy or quiet ?

=item B<remove> (type: bool, default: 1)

actually remove files ?

=item B<directory> (type: dire, default: .)

directory to scan

=item B<leave_tag> (type: bool, default: 1)

leave tag about removed files ?

=item B<leave_suffix> (type: stri, default: .rem)

what suffix to leave ?

=item B<list> (type: bool, default: 0)

make a list of removed files ?

=item B<list_file> (type: newf, default: /tmp/list_file.txt)

what file to write the list to ?

=item B<stats> (type: bool, default: 1)

show statistics ?

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

	0.00 MV web site development
	0.01 MV web site automation
	0.02 MV SEE ALSO section fix
	0.03 MV move tests to modules
	0.04 MV download scripts
	0.05 MV bring movie data
	0.06 MV finish papers
	0.07 MV md5 issues

=head1 SEE ALSO

MIME::Base64(3), Meta::Digest::Collection(3), Meta::Ds::Array(3), Meta::Utils::File::File(3), Meta::Utils::File::Iterator(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), XML::Parser(3), strict(3)

=head1 TODO

Nothing.
