#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use File::stat qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(1);
$opts->set_free_stri("[files]");
$opts->set_free_mini(1);
$opts->set_free_noli(1);
$opts->analyze(\@ARGV);
for(my($i)=0;$i<=$#ARGV;$i++) {
	my($curr)=$ARGV[$i];
	my($sb)=File::stat::stat($curr);
	Meta::Utils::Output::print("stat for [".$curr."]\n");
	Meta::Utils::Output::print("dev is [".$sb->dev()."]\n");
	Meta::Utils::Output::print("ino is [".$sb->ino()."]\n");
	Meta::Utils::Output::print("mode is [".$sb->mode()."]\n");
	Meta::Utils::Output::print("nlink is [".$sb->nlink()."]\n");
	Meta::Utils::Output::print("uid is [".$sb->uid()."]\n");
	Meta::Utils::Output::print("gid is [".$sb->gid()."]\n");
	Meta::Utils::Output::print("rdev is [".$sb->rdev()."]\n");
	Meta::Utils::Output::print("size is [".$sb->size()."]\n");
	Meta::Utils::Output::print("atime is [".$sb->atime()."]\n");
	Meta::Utils::Output::print("mtime is [".$sb->mtime()."]\n");
	Meta::Utils::Output::print("ctime is [".$sb->ctime()."]\n");
	Meta::Utils::Output::print("blksize is [".$sb->blksize()."]\n");
	Meta::Utils::Output::print("blocks is [".$sb->blocks()."]\n");
}
Meta::Utils::System::exit_ok();

__END__

=head1 NAME

utils_stat.pl - stat files and give you info.

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

	MANIFEST: utils_stat.pl
	PROJECT: meta
	VERSION: 0.08

=head1 SYNOPSIS

	utils_stat.pl [options]

=head1 DESCRIPTION

This program will stat files for you and print the results on the
stadard output. This way you can find out things which are harder
to find using "ls" type programs. You it for whatever.

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

	0.00 MV movie stuff
	0.01 MV thumbnail user interface
	0.02 MV more thumbnail issues
	0.03 MV website construction
	0.04 MV improve the movie db xml
	0.05 MV web site automation
	0.06 MV SEE ALSO section fix
	0.07 MV move tests to modules
	0.08 MV md5 issues

=head1 SEE ALSO

File::stat(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
