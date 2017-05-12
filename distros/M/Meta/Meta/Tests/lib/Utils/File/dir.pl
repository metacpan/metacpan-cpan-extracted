#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Test qw();
use Meta::Utils::File::Dir qw();
use Meta::Utils::Output qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Baseline::Test::redirect_on();

my($sample0)="one/two/../file.stam";
my($sample1)="/one/two/../file.stam";
my($sample2)="/one/two/three/../../file.stam";
my($sample3)="/one/two/three/../../../file.stam";
my($res0)=Meta::Utils::File::Dir::fixdir($sample0);
my($res1)=Meta::Utils::File::Dir::fixdir($sample1);
my($res2)=Meta::Utils::File::Dir::fixdir($sample2);
my($res3)=Meta::Utils::File::Dir::fixdir($sample3);
Meta::Utils::Output::print("result0 is [".$res0."]\n");
Meta::Utils::Output::print("result1 is [".$res1."]\n");
Meta::Utils::Output::print("result2 is [".$res2."]\n");
Meta::Utils::Output::print("result3 is [".$res3."]\n");

my($file1)="html/this/that/other/file.html";
my($file2)="html/this/other/that/index.html";
my($relative)=Meta::Utils::File::Dir::get_relative_path($file1,$file2);
Meta::Utils::Output::print("file1 is [".$file1."]\n");
Meta::Utils::Output::print("file2 is [".$file2."]\n");
Meta::Utils::Output::print("relative is [".$relative."]\n");

Meta::Baseline::Test::redirect_off();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

dir.pl - testing program for the Meta::Utils::File::Dir.pm module.

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

	MANIFEST: dir.pl
	PROJECT: meta
	VERSION: 0.14

=head1 SYNOPSIS

	dir.pl

=head1 DESCRIPTION

This is a test suite for the Meta::Utils::File::Dir.pm package.
Currently it only tests the fixdir method by giving it some
samples and seeing the result.

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

	0.00 MV web site and docbook style sheets
	0.01 MV perl packaging
	0.02 MV license issues
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV improve the movie db xml
	0.10 MV more web page stuff
	0.11 MV web site automation
	0.12 MV SEE ALSO section fix
	0.13 MV move tests to modules
	0.14 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Test(3), Meta::Utils::File::Dir(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
