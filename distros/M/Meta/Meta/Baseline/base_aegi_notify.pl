#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Aegis qw();
use Meta::Baseline::Test qw();
use Meta::Utils::Output qw();
use Meta::Info::MailMessage qw();

my($verb,$demo);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","noisy or quiet ?",0,\$verb);
$opts->def_bool("demo","do it or just play pretend ?",0,\$demo);
$opts->set_free_allo(1);
$opts->set_free_stri("[type]");
$opts->set_free_mini(1);
$opts->set_free_maxi(1);
$opts->analyze(\@ARGV);

my(%types)=(
	"forced_develop_begin",undef,
	"develop_end",undef,
	"develop_end_undo",undef,
	"review_pass",undef,
	"review_pass_undo",undef,
	"review_fail",undef,
	"integrate_pass",undef,
	"integrate_fail",undef,
);
my($type)=($ARGV[0]);
my($scod);
if(exists($types{$type})) {
	if($type eq "integrate_pass") {
		my($project)=Meta::Baseline::Aegis::project();
		my($developer)=Meta::Baseline::Aegis::developer();
		my($change)=Meta::Baseline::Aegis::change();
		my($text)="Hello!\nYou may not know me but I am your Aegis baseline. It seems that the developer [".$developer."] has just completed a [".$type."] phase in his change [".$change."]. Please be advised.\n\n\t\t\t\t\t\t\tAegis";
		my($deve_hash)=Meta::Baseline::Aegis::developer_list_hash();
		my($revi_hash)=Meta::Baseline::Aegis::reviewer_list_hash();
		my($inte_hash)=Meta::Baseline::Aegis::integrator_list_hash();
		my($admi_hash)=Meta::Baseline::Aegis::administrator_list_hash();
		my(%send_hash);
		Meta::Utils::Hash::add_hash(\%send_hash,$deve_hash);
		Meta::Utils::Hash::add_hash(\%send_hash,$revi_hash);
		Meta::Utils::Hash::add_hash(\%send_hash,$inte_hash);
		Meta::Utils::Hash::add_hash(\%send_hash,$admi_hash);
		my($list)=Meta::Utils::Hash::to_list(\%send_hash);
		my($message)=Meta::Info::MailMessage->new();
		$message->set_from("aegis\@localhost.localdomain");
		$message->set_text($text);
		$message->set_subject("Aegis notification");
		for(my($i)=0;$i<=$#$list;$i++) {
			my($curr)=$list->[$i];
			$message->get_recipients()->push($curr);
		}
		$scod=$message->send();
		if($scod) {
#			Meta::Baseline::Test::remove_db();
#			Meta::Baseline::Test::create_db();
#			Meta::Baseline::Test::import_db();
		}
	} else {
		Meta::Utils::Output::print("notifications not sent for type [".$type."]\n");
		$scod=1;
	}
} else {
	Meta::Utils::Output::print("unknown notification type [".$type."]\n");
	$scod=0;
}
Meta::Utils::System::exit($scod);

__END__

=head1 NAME

base_aegi_notify.pl - handle Aegis notifications.

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

	MANIFEST: base_aegi_notify.pl
	PROJECT: meta
	VERSION: 0.28

=head1 SYNOPSIS

	base_aegi_notify.pl

=head1 DESCRIPTION

This script will be activated by Aegis each time an event worthy of
notification occurs (integration or other stuff...).

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

=item B<verbose> (type: bool, default: 0)

noisy or quiet ?

=item B<demo> (type: bool, default: 0)

do it or just play pretend ?

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

	0.00 MV initial code brought in
	0.01 MV make quality checks on perl code
	0.02 MV more perl checks
	0.03 MV make Meta::Utils::Opts object oriented
	0.04 MV more harsh checks on perl code
	0.05 MV fix todo items look in pod documentation
	0.06 MV more on tests/more checks to perl
	0.07 MV silense all tests
	0.08 MV more perl quality
	0.09 MV perl code quality
	0.10 MV more perl quality
	0.11 MV more perl quality
	0.12 MV more perl quality
	0.13 MV revision change
	0.14 MV languages.pl test online
	0.15 MV perl packaging
	0.16 MV more Perl packaging
	0.17 MV license issues
	0.18 MV md5 project
	0.19 MV database
	0.20 MV perl module versions in files
	0.21 MV thumbnail user interface
	0.22 MV more thumbnail issues
	0.23 MV website construction
	0.24 MV improve the movie db xml
	0.25 MV web site automation
	0.26 MV SEE ALSO section fix
	0.27 MV move tests to modules
	0.28 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Test(3), Meta::Info::MailMessage(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-do the actual notifications and use some perl email module to do that.

-move all the code here to some lower level (pm modules).

-once Utils::Opts supports enum types move the free argument to an enum type...:) (that way we wouldnt have to handle the error messages here...)

-today we follow the following algorithm for notifications: gather all developers, reviewers, integrators and administrators and send them the mail about the condition changing. Could we not have a much more sophisticated scheme in the baseline whereby people will only get the mail about stuff they are interested in and in any case there will be a file in the baseline (in /data) with general policies (like develop_end going to reviewers etc...?
