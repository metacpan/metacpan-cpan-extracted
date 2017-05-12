#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Test qw();
use Meta::Baseline::Aegis qw();
use Meta::Lang::Perl::Perl qw();
use Meta::Utils::Output qw();
use Meta::Utils::Utils qw();
use Meta::Ds::Set qw();

my($verb,$block,$run);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","verbose or quiet ?",0,\$verb);
$opts->def_bool("block","block output ?",0,\$block);
$opts->def_bool("run","really run ?",1,\$run);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

#Meta::Baseline::Test::redirect_on();

my($res)=1;
Meta::Utils::Output::verbose($verb,"started getting files\n");
my($files)=Meta::Baseline::Aegis::source_files_list(1,1,0,1,1,1);
Meta::Utils::Output::verbose($verb,"finished getting files\n");
my($num)=$#$files+1;
Meta::Utils::Output::verbose($verb,"number of files [".$num."]\n");
my($set)=Meta::Ds::Set->new();
for(my($i)=0;$i<=$#$files;$i++) {
	my($curr)=$files->[$i];
	if(Meta::Lang::Perl::Perl::is_bin($curr)) {
		my($base)=Meta::Utils::Utils::basename($curr);
		Meta::Utils::Output::verbose($verb,"testing [".$base."]...");
		if($run) {
			if($block) {
				Meta::Baseline::Test::redirect_on();
			}
			my($cres)=Meta::Utils::System::system_nodie($curr,["--quit"]);
			if($block) {
				Meta::Baseline::Test::redirect_off();
			}
			Meta::Utils::Output::verbose($verb,"[".Meta::Baseline::Test::code_to_string($cres)."]\n");
			if(!$cres) {
				$res=0;
			}
		}
		if($set->has($base)) {
			Meta::Utils::Output::print("problem with duplicate name [".$base."]\n");
			$res=0;
		} else {
			$set->insert($base);
		}
	}
}

#Meta::Baseline::Test::redirect_off();

Meta::Utils::System::exit($res);

__END__

=head1 NAME

dry_run.pl - Meta regression test to dry run all executables to catch compilation errors.

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

	MANIFEST: dry_run.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	dry_run.pl [options]

=head1 DESCRIPTION

Put your programs description here.

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

verbose or quiet ?

=item B<block> (type: bool, default: 0)

block output ?

=item B<run> (type: bool, default: 1)

really run ?

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

	0.00 MV teachers project
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Test(3), Meta::Ds::Set(3), Meta::Lang::Perl::Perl(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

Nothing.
