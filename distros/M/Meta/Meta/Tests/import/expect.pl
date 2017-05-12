#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Test qw();
use Expect qw();
use Meta::Utils::Output qw();
use Error qw(:try);

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Baseline::Test::redirect_on();

my($user)=Meta::Baseline::Test::get_user();
my($pass)=Meta::Baseline::Test::get_password();
my($host)=Meta::Baseline::Test::get_host();

my($ssh_bin)="/usr/bin/ssh";
#my($ssh_bin)="/local/tools/bin/ssh";
my($cmd)=$ssh_bin." ".$host." -l ".$user;
Meta::Utils::Output::print("cmd is [".$cmd."]\n");
my($sess)=Expect->spawn($cmd);

$sess->log_stdout(1);
$sess->expect(30,$user."@".$host."'s password: ") || throw Meta::Error::Simple("never got password prompt on [".$host."],[".$sess->exp_error()."]");
print $sess $pass."\r";
my($matc)=$sess->expect(30,"Login incorrect","-re",'(.*)\$');
if($matc==0) {
	throw Meta::Error::Simple("connection closed");
}
print $sess "ls -l\r";
$matc=$sess->expect(30,"-re",'\r\n(.*)\$') || throw Meta::Error::Simple("wait here");
my($retu)=$sess->exp_before();
print $sess "exit\r";
$sess->soft_close();
#sleep(5);
Meta::Utils::Output::print("got retu [".$retu."]\n");

Meta::Utils::Output::print("in here\n");

Meta::Baseline::Test::redirect_off();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

expect.pl - test the Expect.pm external module.

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

	MANIFEST: expect.pl
	PROJECT: meta
	VERSION: 0.26

=head1 SYNOPSIS

	expect.pl

=head1 DESCRIPTION

This is a test suite for the Meta::Expect.pm package.

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

	0.00 MV put ALL tests back and light the tree
	0.01 MV silense all tests
	0.02 MV more perl code quality
	0.03 MV cleanup tests change
	0.04 MV correct die usage
	0.05 MV fix expect.pl test
	0.06 MV perl code quality
	0.07 MV more perl quality
	0.08 MV more perl quality
	0.09 MV perl qulity code
	0.10 MV revision change
	0.11 MV languages.pl test online
	0.12 MV pics with db support
	0.13 MV perl packaging
	0.14 MV license issues
	0.15 MV md5 project
	0.16 MV database
	0.17 MV perl module versions in files
	0.18 MV thumbnail user interface
	0.19 MV more thumbnail issues
	0.20 MV website construction
	0.21 MV improve the movie db xml
	0.22 MV web site automation
	0.23 MV SEE ALSO section fix
	0.24 MV move tests to modules
	0.25 MV web site development
	0.26 MV md5 issues

=head1 SEE ALSO

Error(3), Expect(3), Meta::Baseline::Test(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-somehow doing close on the session causes the exit value of THIS process to be error (255). How come ? I had to stop closing the session because of this. fix this (upgrade Expect ?).
