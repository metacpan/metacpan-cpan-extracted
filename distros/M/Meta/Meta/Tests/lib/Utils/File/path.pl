#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Test qw();
use Meta::Utils::File::Path qw();
use Meta::Utils::Env qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Baseline::Test::redirect_on();

my($path)=Meta::Utils::Env::get("PATH");
Meta::Utils::Output::print("original path is [".$path."]\n");
my($min_path)=Meta::Utils::File::Path::min_path($path,":");
Meta::Utils::Output::print("min_path is [".$min_path."]\n");
my($exist_path)=Meta::Utils::File::Path::remove_nonexist($path,":");
Meta::Utils::Output::print("exist_path is [".$exist_path."]\n");
my($apath)=Meta::Baseline::Aegis::search_path();
my($file)="data/baseline/cook/opts.txt";
my($resolve)=Meta::Utils::File::Path::resolve($apath,$file,":");
Meta::Utils::Output::print("resolve is [".$resolve."]\n");
my($relative)=Meta::Utils::File::Path::remove_path($apath,":",$resolve);
Meta::Utils::Output::print("relative is [".$relative."]\n");

Meta::Baseline::Test::redirect_off();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

path.pl - testing program for the Meta::Utils::File::Path.pm module.

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

	MANIFEST: path.pl
	PROJECT: meta
	VERSION: 0.21

=head1 SYNOPSIS

	path.pl

=head1 DESCRIPTION

This is a test suite for the Meta::Utils::File::Path.pm package.

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
	0.03 MV perl code quality
	0.04 MV more perl quality
	0.05 MV more perl quality
	0.06 MV revision change
	0.07 MV languages.pl test online
	0.08 MV perl packaging
	0.09 MV perl packaging again
	0.10 MV license issues
	0.11 MV md5 project
	0.12 MV database
	0.13 MV perl module versions in files
	0.14 MV thumbnail user interface
	0.15 MV more thumbnail issues
	0.16 MV website construction
	0.17 MV improve the movie db xml
	0.18 MV web site automation
	0.19 MV SEE ALSO section fix
	0.20 MV move tests to modules
	0.21 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Test(3), Meta::Utils::Env(3), Meta::Utils::File::Path(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
