#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Projects::Dbman::Section qw();
use Meta::Projects::Dbman::Page qw();
use Error qw(:try);

my($file,$section);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_file("file","the manual page file ?",undef,\$file);
$opts->def_stri("section","in what section to install it ?",undef,\$section);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

#check that the section is ok
my($section)=Meta::Projects::Dbman::Section->search("name",$section);
if(!(defined($section))) {
	throw Meta::Error::Simple("section [".$section."] does not exist");
}
#create the new page row and commit it
my($page)=Meta::Projects::Dbman::Page->create({});
$page->section($section);

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

dbman_install.pl - install manual pages to a dbman system.

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

	MANIFEST: dbman_install.pl
	PROJECT: meta
	VERSION: 0.07

=head1 SYNOPSIS

	dbman_install.pl [options]

=head1 DESCRIPTION

This executable is part of the dbman package. If you don't know
what dbman is please refer to the dbman documentation.

This program installs a single manual page into the dbman
database. You should prepare your troff/groff manual page with
whatevery tools you desire and then, at the installation part
of your software call this program to handle installation of
any of the manual pages. Since not every system has dbman installed
you should check (using autoconf or other methods) whether dbman
is installed in your installation script/Makefile or whatever.
If dbman is not install you can resort to using the regular
install(1) methods for installing the manual page on the local
hard drive.

This program is designed to be used by an automatic installer (based
on autoconf/automake or just plain makefiles) but can be used
by regular users too in order to add specific manual pages to
their dbman repository.

The manual page given should be an unzipped troff input file.
The section given should be a section already in the database.

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

=item B<file> (type: file, default: )

the manual page file ?

=item B<section> (type: stri, default: )

in what section to install it ?

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

	0.00 MV dbman package creation
	0.01 MV more thumbnail issues
	0.02 MV website construction
	0.03 MV improve the movie db xml
	0.04 MV web site automation
	0.05 MV SEE ALSO section fix
	0.06 MV move tests to modules
	0.07 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Projects::Dbman::Page(3), Meta::Projects::Dbman::Section(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
