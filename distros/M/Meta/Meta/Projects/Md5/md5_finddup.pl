#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use XML::Parser qw();
use Meta::Utils::Output qw();
use MIME::Base64 qw();
use Term::ReadKey qw();
use Meta::Utils::File::Remove qw();
use Error qw(:try);

my($curr_filename,$curr_moddate,$curr_md5sum,$hash);
my($premature,$predat)=0;

sub handle_start($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context(),$elem);
#	Meta::Utils::Output::print("in here with context [".$context."]\n");
	if($context eq "md5.stamp.filename") {
		$curr_filename="";
	}
	if($context eq "md5.stamp.moddate") {
		$curr_moddate="";
	}
	if($context eq "md5.stamp.md5sum") {
		$predat="";
	}
}

sub handle_char($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context());
	if($context eq "md5.stamp.filename") {
		$curr_filename.=$elem;
	}
	if($context eq "md5.stamp.moddate") {
		$curr_moddate.=$elem;
	}
	if($context eq "md5.stamp.md5sum") {
		$predat.=$elem;
	}
}

sub handle_end($$) {
	my($self,$elem)=@_;
	my($context)=join(".",$self->context(),$elem);
	if($context eq "md5.stamp") {
		#$predat=~ tr|A-Za-z0-9+=/||cd;# remove non-base64 chars (for escapes)
		$curr_md5sum=MIME::Base64::decode($predat);
		if(exists($hash->{$curr_md5sum})) {
			my($file)=$hash->{$curr_md5sum};
#			Meta::Utils::Output::print("found dup [".$file."] [".$curr_filename."]\n");
			my($doit)=0;
			if((-f $file) && (-f $curr_filename)) {
				$doit=1;
			} else {
				Meta::Utils::Output::print("not displaying [".$file."] vs [".$curr_filename."] because one of the files is gone\n");
			}
			if($doit) {
				Meta::Utils::Output::print("a. remove [".$file."]\n");
				Meta::Utils::Output::print("b. remove [".$curr_filename."]\n");
				Meta::Utils::Output::print("c. interrupt.\n");
				Meta::Utils::Output::print("s. skip.\n");
				my($char);
				if(defined($char=Term::ReadKey::ReadKey(0))) {
					#Meta::Utils::Output::print("char is [".$char."]\n");
					my($to_remove);
					my($remove);
					if($char eq 'a') {
						$to_remove=$file;
						$remove=1;
					}
					if($char eq 'b') {
						$to_remove=$curr_filename;
						$remove=1;
					}
					if($char eq 'c') {
						$remove=0;
						Term::ReadKey::ReadMode(0);
						throw Meta::Error::Simple("caught interrupt");
					}
					if($char eq 's') {
						$remove=0;
					}
					if($remove) {
						Meta::Utils::File::Remove::rm($to_remove);
					}
				}
			}
		} else {
			#Meta::Utils::Output::print("inserting [".$curr_md5sum."] for [".$curr_filename."]\n");
			$hash->{$curr_md5sum}=$curr_filename;
		}
	}
}

my($input);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_file("input","what input file to use ?","/tmp/file.xml",\$input);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Term::ReadKey::ReadMode(4);
#select(STDIN);$|=1;

$hash={};
my($parser)=XML::Parser->new();
$parser->setHandlers(
	Start=>\&handle_start,
	Char=>\&handle_char,
	End=>\&handle_end,
);
$parser->parsefile($input);
Term::ReadKey::ReadMode(0);

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

md5_finddup.pl - find duplicate files in XML/md5 type files.

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

	MANIFEST: md5_finddup.pl
	PROJECT: meta
	VERSION: 0.14

=head1 SYNOPSIS

	md5_finddup.pl [options]

=head1 DESCRIPTION

This script processes an XML/md5 type file and looks for duplicate
MD5 sums (which, in high probability, indicate that the same
files are involved...), and prints out the files which have the
same MD5 sums. The user gets to select what to do with the file:
remove the file, keep the file etc...
This is an interactive program.

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

=item B<input> (type: file, default: /tmp/file.xml)

what input file to use ?

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

	0.00 MV books XML into database
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV graph visualization
	0.05 MV thumbnail user interface
	0.06 MV more thumbnail issues
	0.07 MV website construction
	0.08 MV improve the movie db xml
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV move tests to modules
	0.12 MV finish papers
	0.13 MV more pdmt stuff
	0.14 MV md5 issues

=head1 SEE ALSO

Error(3), MIME::Base64(3), Meta::Utils::File::Remove(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Term::ReadKey(3), XML::Parser(3), strict(3)

=head1 TODO

-fix problem with the parser that I have to do the hack for (the parser doenst seem to give me the whole character data in the handle_char callback...).
