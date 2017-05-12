#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::File::MMagic qw();
use Meta::Utils::Output qw();
use Meta::Utils::File::File qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(1);
$opts->set_free_stri("[files]");
$opts->analyze(\@ARGV);

my($mm)=Meta::File::MMagic->new();
for(my($i)=0;$i<=$#ARGV;$i++) {
	my($file)=$ARGV[$i];
	my($io)=Meta::IO::File->new_reader($file);
	my($data);
	Meta::Utils::File::File::load($file,\$data);
	# the next two are not the same
	my($type1)=$mm->checktype_filename($file);
	my($type2)=$mm->checktype_byfilename($file);
	my($type3)=$mm->checktype_magic($data);
	my($type4)=$mm->checktype_filemagic($file);
	my($type5)=$mm->checktype_filehandle($io);
	my($type6)=$mm->checktype_contents($data);
	my($type7)=$mm->checktype_filecontents($file);
	Meta::Utils::Output::print("checktype_filename [".$file."] is [".$type1."]\n");
	Meta::Utils::Output::print("checktype_byfilename [".$file."] is [".$type2."]\n");
	Meta::Utils::Output::print("checktype_magic [".$file."] is [".$type3."]\n");
	Meta::Utils::Output::print("checktype_filemagic [".$file."] is [".$type4."]\n");
	Meta::Utils::Output::print("checktype_filehandle [".$file."] is [".$type5."]\n");
	Meta::Utils::Output::print("checktype_contents [".$file."] is [".$type6."]\n");
	Meta::Utils::Output::print("checktype_filecontents [".$file."] is [".$type7."]\n");
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

develop_file.pl - show types of files using File::MMagic.

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

	MANIFEST: develop_file.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	develop_file.pl [options]

=head1 DESCRIPTION

This program will get a list of files and will tell you their types using
the File::MMagic perl module. The idea is to be able to see what the
deduction engine of File::MMagic thinks about the corrent mime types.
Mime types are quite important when it comes to, for instance, serving
content over a web server.

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

=back

minimum of [1] free arguments required
no maximum limit on number of free arguments placed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV download scripts
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::File::MMagic(3), Meta::Utils::File::File(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-do magic,content and other methods here.
