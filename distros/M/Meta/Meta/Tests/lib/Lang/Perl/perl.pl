#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Test qw();
use Meta::Lang::Perl::Perl qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::Output qw();
use Meta::Utils::File::File qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Baseline::Test::redirect_on();

my($file)=Meta::Baseline::Aegis::which("perl/lib/Meta/Db/Enum.pm");
my($version1)=Meta::Lang::Perl::Perl::get_version_mm($file);
my($version2)=Meta::Lang::Perl::Perl::get_version_mm_unix($file);
my($version3)=Meta::Lang::Perl::Perl::get_version($file);
my($isa)=Meta::Lang::Perl::Perl::get_file_isa("perl/lib/Meta/Db/Enum.pm");
my($pod)=Meta::Lang::Perl::Perl::get_file_pod_isa("perl/lib/Meta/Db/Enum.pm");
Meta::Utils::Output::print("version1 is [".$version1."]\n");
Meta::Utils::Output::print("version2 is [".$version2."]\n");
Meta::Utils::Output::print("version3 is [".$version3."]\n");
Meta::Utils::Output::print("isa is [".join(",",@$isa)."]\n");
Meta::Utils::Output::print("pod is [".$pod."]\n");
my($pod_file)=Meta::Baseline::Aegis::which("perl/bin/Meta/Projects/Website/website_copy.pl");
my($content);
Meta::Utils::File::File::load($pod_file,\$content);
my($hash)=Meta::Lang::Perl::Perl::get_pods_new($content);
while(my($key,$val)=each(%$hash)) {
	Meta::Utils::Output::print("pod is [".$key."]\n");
	Meta::Utils::Output::print("content is [".$val."]\n");
}

Meta::Baseline::Test::redirect_off();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

perl.pl - test suite for the Meta::Lang::Perl::Perl module.

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

	MANIFEST: perl.pl
	PROJECT: meta
	VERSION: 0.09

=head1 SYNOPSIS

	perl.pl [options]

=head1 DESCRIPTION

This is a test suite for the Meta::Lang::Perl::Perl module.
Currently it only reads a version number from a module
and prints it (from the Meta::Lang::Perl::Perl module).

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

	0.00 MV perl module versions in files
	0.01 MV graph visualization
	0.02 MV thumbnail user interface
	0.03 MV more thumbnail issues
	0.04 MV website construction
	0.05 MV improve the movie db xml
	0.06 MV web site automation
	0.07 MV SEE ALSO section fix
	0.08 MV move tests to modules
	0.09 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Test(3), Meta::Lang::Perl::Perl(3), Meta::Utils::File::File(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
