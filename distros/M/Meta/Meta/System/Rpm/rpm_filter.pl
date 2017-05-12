#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use RPM::Database qw();
use Meta::Ds::Hash qw();
use Meta::Tool::Rpm qw();
use Error qw(:try);

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(1);
$opts->set_free_stri("[rpmfiles]");
$opts->set_free_mini(1);
$opts->set_free_noli(1);
$opts->analyze(\@ARGV);

my($hash)=Meta::Ds::Hash->new();
my(%RPM);
tie %RPM,"RPM::Database" or throw Meta::Error::Simple("cannot access RPM database with error [".$RPM::err."]");
while(my($key,$val)=each(%RPM)) {
	$hash->insert($key);
#	Meta::Utils::Output::print("key is [".$key."] and val is [".$val."]\n");
#	while(my($hkey,$hval)=each(%$val)) {
#		Meta::Utils::Output::print("hkey is [".$hkey."] and hval is [".$hval."]\n");
#	}
}

for(my($i)=0;$i<=$#ARGV;$i++) {
	my($curr)=$ARGV[$i];
	# get the basename of the rpm
	my($base)=Meta::Tool::Rpm::basename($curr);
	if($hash->hasnt($base)) {
		Meta::Utils::Output::print($curr."\n");
	}
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

rpm_filter.pl - filter out installed packages.

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

	MANIFEST: rpm_filter.pl
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	rpm_filter.pl [options]

=head1 DESCRIPTION

Give this program a list of RPMS and it will only return the RPM which are
not installed on your system. The idea is that you can use this tool to
find the set of RPMS that you didn't install from a CD and install them
at a single command. This script is not designed to be run as root. You
should run this script to create the list of RPMS that you want installed
and then issue "rpm --install --verbose `cat list.txt`" as root. This script
uses the RPM perl module to access the RPM database and find out which RPMS
are installed.

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

	0.00 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Ds::Hash(3), Meta::Tool::Rpm(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), RPM::Database(3), strict(3)

=head1 TODO

Nothing.
