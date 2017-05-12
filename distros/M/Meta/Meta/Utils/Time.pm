#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Time;

use strict qw(vars refs subs);
use Time::localtime qw();
use Time::Local qw();
use Date::Manip qw();

our($VERSION,@ISA);
$VERSION="0.28";
@ISA=qw();

#sub tm_to_string($);
#sub tm_to_epoch($);
#sub now_tm();
#sub now_string();
#sub now_epoch();
#sub now_mysql();
#sub unixdate2mysql($);
#sub stat2mysql($);
#sub TEST($);

#__DATA__

sub tm_to_string($) {
	my($tm)=@_;
	my($retu)=sprintf("%04d_%02d_%02d_%02d_%02d_%02d",
		$tm->year+1900,
		$tm->mon+1,
		$tm->mday,
		$tm->hour,
		$tm->min,
		$tm->sec);
	return($retu);
}

sub tm_to_epoch($) {
	my($tm)=@_;
	return(Time::Local::timelocal(
		$tm->sec,
		$tm->min,
		$tm->hour,
		$tm->mday,
		$tm->mon,
		$tm->year));
}

sub now_tm() {
	return(Time::localtime::localtime());
}

sub now_string() {
	return(tm_to_string(now_tm()));
}

sub now_epoch() {
	return(tm_to_epoch(now_tm()));
}

sub now_mysql() {
	return(&now_string());
}

sub unixdate2mysql($) {
	my($string)=@_;
	my($object)=Date::Manip::UnixDate($string,"%Y-%m-%d %T");
	return($object);
}

sub stat2mysql($) {
	my($secs)=@_;
	my($date)=Date::Manip::ParseDateString("epoch ".$secs);
	return(unixdate2mysql($date));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Time - module to let you access dates and times.

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

	MANIFEST: Time.pm
	PROJECT: meta
	VERSION: 0.28

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Time qw();
	my($string)=Meta::Utils::Time::now_string();

=head1 DESCRIPTION

This is a library to make it easier on you to access dates and time,
do calculations on them and other stuff without knowing all the gorry
details.
Note that we do not want to add routines like "epoch_to_tm" or "string_to_tm"
since the tm object is not to be used directly according to Tom Christiansen
who maintains these modules.
Therefore we use the string and epoch as merely printing and you should
hold internal representations of time in tm's which you cannot!!! generate
by yourself...(sad but true...).

=head1 FUNCTIONS

	tm_to_string($)
	tm_to_epoch($)
	now_tm()
	now_string()
	now_epoch()
	now_mysql()
	unixdate2mysql($)
	stat2mysql($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<tm_to_string($)>

Convert time structure to one coherent string that we use to denote time.

=item B<tm_to_epoch($)>

This routine receives a tm structure time and converts it to epoch.

=item B<now_tm()>

This routine returns the current time as a tm structure.

=item B<now_string()>

This routine gives you the current time in a standard form of two digits per
each element , larget to smaller of the current date and time up to the second.

=item B<now_epoch()>

Routine that returns the current time in epoch terms (seconds since
1/1/1970). Dont ask why we need this (something to do with cook).

=item B<now_mysql()>

Routine that returns the current time in a format that mysql can import as
part of SQL statements.

=item B<unixdate2mysql($)>

This routine converts a UNIX date (as comes out of the Date command) to
a string which is suitable for insertion as a DateTime field in a MySQL
database. This method uses the Date::Manip module (a very good module).

=item B<stat2mysql($)>

This method converts the dates returned from stat (epoch 1970 seconds) to
a format suitable for Mysql. Uses Date::Manip.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV initial code brought in
	0.01 MV make quality checks on perl code
	0.02 MV more perl checks
	0.03 MV check that all uses have qw
	0.04 MV fix todo items look in pod documentation
	0.05 MV more on tests/more checks to perl
	0.06 MV perl code quality
	0.07 MV more perl quality
	0.08 MV more perl quality
	0.09 MV perl documentation
	0.10 MV more perl quality
	0.11 MV perl qulity code
	0.12 MV more perl code quality
	0.13 MV revision change
	0.14 MV languages.pl test online
	0.15 MV perl packaging
	0.16 MV more movies
	0.17 MV md5 project
	0.18 MV database
	0.19 MV perl module versions in files
	0.20 MV movies and small fixes
	0.21 MV movie stuff
	0.22 MV thumbnail user interface
	0.23 MV more thumbnail issues
	0.24 MV website construction
	0.25 MV web site automation
	0.26 MV SEE ALSO section fix
	0.27 MV weblog issues
	0.28 MV md5 issues

=head1 SEE ALSO

Date::Manip(3), Time::Local(3), Time::localtime(3), strict(3)

=head1 TODO

-Rewrite this whole thing with my own time structure (Tom Christiansen sucks in that he wont allow people to use his...).

-add more functionality. (to postress, to oracle etc...).

-maybe use a different module than Date::Manip since it's supposed to be slow.

-add now_postgres, now_oracle etc...
