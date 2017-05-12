#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Test qw();
use Mail::Sendmail qw();
use Meta::Utils::Output qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Baseline::Test::redirect_on();

my($user)=Meta::Baseline::Test::get_user();
my($host)=Meta::Baseline::Test::get_host();

my(%mail)=(
	To=>$user."\@".$host,
	From=>'me@here.com',
	Subject=>'Hello there',
	Message=>'how are you doing'
);
my($scod)=Mail::Sendmail::sendmail(%mail);
if($scod) {
	Meta::Utils::Output::print("log is [".$Mail::Sendmail::log."]\n");
} else {
	Meta::Utils::Output::print("error is [".$Mail::Sendmail::error."]\n");
}

Meta::Baseline::Test::redirect_off();

Meta::Utils::System::exit($scod);

__END__

=head1 NAME

sendmail.pl - test the external Mail::Sendmail module.

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

	MANIFEST: sendmail.pl
	PROJECT: meta
	VERSION: 0.17

=head1 SYNOPSIS

	sendmail.pl

=head1 DESCRIPTION

This is a test suite for the Mail::Sendmail package.
Currently this just sends an email message to the abused user.

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

no free arguments are allowed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV chess and code quality
	0.01 MV more perl quality
	0.02 MV revision change
	0.03 MV languages.pl test online
	0.04 MV perl packaging
	0.05 MV db inheritance
	0.06 MV license issues
	0.07 MV md5 project
	0.08 MV database
	0.09 MV perl module versions in files
	0.10 MV thumbnail user interface
	0.11 MV more thumbnail issues
	0.12 MV website construction
	0.13 MV improve the movie db xml
	0.14 MV web site automation
	0.15 MV SEE ALSO section fix
	0.16 MV move tests to modules
	0.17 MV md5 issues

=head1 SEE ALSO

Mail::Sendmail(3), Meta::Baseline::Test(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
