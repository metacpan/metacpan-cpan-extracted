#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Lang::Perl::Perl qw();
use Meta::Utils::Output qw();
use Meta::Development::TestInfo qw();
use Meta::Baseline::Test qw();
use Meta::Baseline::Aegis qw();
use Meta::Development::Module qw();
use Error qw(:try);
use Meta::Types::Bool qw();

my($verb,$block,$file,$all);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","verbose or quiet ?",1,\$verb);
$opts->def_bool("block","block output ?",0,\$block);
$opts->def_devf("file","what file to check ?",undef,\$file);
$opts->def_bool("all","check all modules ?",0,\$all);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

# first prepare the testing configuration object

my($module)=Meta::Development::Module->new_name("xmlx/configs/test.xml");
my($info)=Meta::Development::TestInfo->new();
$info->read_modu($module);

my($files);
if($all) {
	$files=Meta::Baseline::Aegis::source_files_list(1,1,0,1,0,0);
} else {
	$files=[ $file ];
}

my($res)=1;
for(my($i)=0;$i<=$#$files;$i++) {
	my($curr)=$files->[$i];
	if(Meta::Lang::Perl::Perl::is_lib($curr)) {
		#lets translate file name to module
		my($module)=Meta::Lang::Perl::Perl::file_to_module($curr);
		#now use the module
		Meta::Lang::Perl::Perl::load_module($module);
		if($verb) {
			# no new line at the end of the next print so that each line will
			# be a different test
			Meta::Utils::Output::print("testing [".$module."]...");
		}
		#now call the method
		if($block) {
			Meta::Baseline::Test::redirect_on();
		}
		my($cres);
		try {
			$cres=Meta::Lang::Perl::Perl::call_method($module,"TEST",[$info]);
		}
		catch Error with {
			my($error)=shift;
			$cres=0;
			Meta::Utils::Output::print("cought exception from tested module:\n");
			Meta::Utils::Output::print($error->stringify());
		};
		if($block) {
			Meta::Baseline::Test::redirect_off();
		}
		#now unload the module
		#the unload doesn't work well since if I load a module afterwards
		#that needs something that I'm now unloading it created problems.
		#Meta::Lang::Perl::Perl::unload_module($module);
		my($bool)=Meta::Types::Bool->new_value($cres);
		Meta::Utils::Output::print("[".$bool->get_version("of")."]\n");
		if(!$cres) {
			$res=0;
		}
	}
}

Meta::Utils::System::exit($res);

__END__

=head1 NAME

perl_test.pl - run perl in module tests.

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

	MANIFEST: perl_test.pl
	PROJECT: meta
	VERSION: 0.05

=head1 SYNOPSIS

	perl_test.pl [options]

=head1 DESCRIPTION

Give this module a file name and it will run the embedded TEST method for it.

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

=item B<verbose> (type: bool, default: 1)

verbose or quiet ?

=item B<block> (type: bool, default: 0)

block output ?

=item B<file> (type: devf, default: )

what file to check ?

=item B<all> (type: bool, default: 0)

check all modules ?

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

	0.00 MV put all tests in modules
	0.01 MV move tests to modules
	0.02 MV download scripts
	0.03 MV finish papers
	0.04 MV teachers project
	0.05 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Baseline::Aegis(3), Meta::Baseline::Test(3), Meta::Development::Module(3), Meta::Development::TestInfo(3), Meta::Lang::Perl::Perl(3), Meta::Types::Bool(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-sort the module alphabetically before running the tests (make it look nice).

-allow to sort the modules according to modification times (shortens time).
