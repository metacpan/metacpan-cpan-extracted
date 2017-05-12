#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Lang::Perl::Perlpkgs qw();
use Meta::Baseline::Aegis qw();
use Meta::Lang::Perl::Perl qw();
use Meta::Utils::Output qw();

my($re,$file,$num);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_stri("re","what regular experssion ?",".*\.pm",\$re);
$opts->def_modu("package","what packages file ?","xmlx/perlpkgs/meta.xml",\$file);
$opts->def_stri("num","what package number ?",0,\$num);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($pkgs)=Meta::Lang::Perl::Perlpkgs->new_modu($file);
my($pkg)=$pkgs->getx($num);
my($modules)=$pkg->get_modules();
my(%hash);
for(my($i)=0;$i<$modules->size();$i++) {
	my($curr)=$modules->getx($i);
	my($file)=$curr->get_source();
	#Meta::Utils::Output::print("curr is [".$file."]\n");
	$hash{$file}=0;
}
#Meta::Utils::Output::print("size is [".$modules->size()."]\n");

my($scod)=1;
my($source)=Meta::Baseline::Aegis::source_files_list(1,1,0,1,1,0);
for(my($i)=0;$i<=$#$source;$i++) {
	my($modu)=$source->[$i];
	if(Meta::Lang::Perl::Perl::is_lib($modu)) {
		if($modu=~/$re/) {
			if(!exists($hash{$modu})) {
				Meta::Utils::Output::print("module [".$modu."] is missing\n");
				$scod=0;
			}
		}
	}
}

Meta::Utils::System::exit($scod);

__END__

=head1 NAME

perl_pkgcheck.pl - check that perl package memebers match a certain re.

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

	MANIFEST: perl_pkgcheck.pl
	PROJECT: meta
	VERSION: 0.04

=head1 SYNOPSIS

	perl_pkgcheck.pl [options]

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

=item B<re> (type: stri, default: .*.pm)

what regular experssion ?

=item B<package> (type: modu, default: xmlx/perlpkgs/meta.xml)

what packages file ?

=item B<num> (type: stri, default: 0)

what package number ?

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
	0.02 MV bring movie data
	0.03 MV teachers project
	0.04 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Lang::Perl::Perl(3), Meta::Lang::Perl::Perlpkgs(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
