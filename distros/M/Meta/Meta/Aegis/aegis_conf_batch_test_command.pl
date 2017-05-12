#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use File::Basename qw();
use Meta::Utils::Color qw();
use Meta::Baseline::Test qw();
use Meta::Utils::Output qw();
use Meta::Math::Pad qw();
use Meta::IO::File qw();
use Meta::Types::Bool qw();

my($demo,$verb,$stop,$summ);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("demo","realy do it or just demo ?",0,\$demo);
$opts->def_bool("verbose","noisy or quiet ?",1,\$verb);
$opts->def_bool("stop","stop after test failures ?",1,\$stop);
$opts->def_bool("summ","print summary at end ?",1,\$summ);
$opts->set_free_allo(1);
$opts->set_free_stri("[outp] [sear] [exse] [test]");
$opts->set_free_mini(3);
$opts->set_free_maxi(4);
$opts->analyze(\@ARGV);

if($#ARGV==2) {
	Meta::Utils::Output::verbose($verb,"no tests to run\n");
	$ARGV[3]="";
}
my($outp,$sear,$exse,$test)=($ARGV[0],$ARGV[1],$ARGV[2],$ARGV[3]);
my(@tsts)=split(" ",$test);
my($scod)=1;
my($file)=Meta::IO::File->new_writer($outp);
print $file "test_result=\n";
print $file "[\n";
my($summ_okxx,$summ_fail)=(0,0);
my($numb)=$#tsts+1;
for(my($i)=0;$i<$numb && !($stop && !$scod);$i++) {
	my($curr)=$tsts[$i];
	my($base)=File::Basename::basename($curr);
	my($numb)=Meta::Math::Pad::pad($i,3);
	Meta::Utils::Output::verbose($verb,"running test [".$numb."] [".$base."]...");
#		Meta::Utils::Color::set_color(*stderr,"blue");
#		print stderr "running test ".$i." [";
#		Meta::Utils::Color::set_color(*stderr,"red");
#		print stderr $base;
#		Meta::Utils::Color::set_color(*stderr,"blue");
#		print stderr "]...";
#		Meta::Utils::Color::reset(*stderr);
	my($ccod)=Meta::Utils::System::system_nodie($curr,[]);
	if($ccod==0) {
		$scod=0;
		$summ_fail++;
	} else {
		$summ_okxx++;
	}
	if($verb) {
		my($bool)=Meta::Types::Bool->new_value($ccod);
#		Meta::Utils::Color::set_color(*stderr,"red");
#		print stderr $stri."\n";
#		Meta::Utils::Color::set_color(*stderr,"blue");
#		Meta::Utils::Color::reset(*stderr);
		Meta::Utils::Output::print($bool->get_version("of")."\n");
	}
	my($code)=Meta::Utils::Utils::bnot($ccod);
	print $file "\t{\n";
	print $file "\t\tfile_name=\"".$curr."\";\n";
	print $file "\t\texit_status=".$code.";\n";
	print $file "\t},\n";
}
print $file "];\n";
$file->close();
Meta::Utils::Output::verbose($summ,"total/ok/fail [".$numb."]/[".$summ_okxx."]/[".$summ_fail."] tests\n");
Meta::Utils::System::exit($scod);

__END__

=head1 NAME

aegis_conf_batch_test_command.pl - run batch tests for aegis.

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

	MANIFEST: aegis_conf_batch_test_command.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	aegis_conf_batch_test_command.pl

=head1 DESCRIPTION

This script is called by Aegis to run batch tests.

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

=item B<demo> (type: bool, default: 0)

realy do it or just demo ?

=item B<verbose> (type: bool, default: 1)

noisy or quiet ?

=item B<stop> (type: bool, default: 1)

stop after test failures ?

=item B<summ> (type: bool, default: 1)

print summary at end ?

=back

minimum of [3] free arguments required
no maximum limit on number of free arguments placed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV web site development
	0.01 MV md5 issues

=head1 SEE ALSO

File::Basename(3), Meta::Baseline::Test(3), Meta::IO::File(3), Meta::Math::Pad(3), Meta::Types::Bool(3), Meta::Utils::Color(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-try to parallel the tests on several machines.
