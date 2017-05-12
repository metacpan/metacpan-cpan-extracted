#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Aegis qw();
use Meta::Lang::Perl::Perl qw();
use Meta::Baseline::Lang::Perl qw();
use Meta::Utils::Output qw();
use Meta::Ds::Noset qw();
use Meta::Info::Enum qw();

my($fset)=Meta::Ds::Noset->new();
my($enum)=Meta::Info::Enum->new();
$enum->insert("copyright","fix the COPYRIGHT tag");
$enum->insert("license","fix the LICENSE tag");
$enum->insert("details","fix the DETAILS tag");
$enum->insert("author","fix the AUTHOR tag");
$enum->insert("history","fix the HISTORY tag");
$enum->insert("see","fix the SEE ALSO tag");
$enum->insert("options","fix the OPTIONS tag");
$enum->insert("version","fix the VERSION tag");
$enum->insert("super","fix the SUPER CLASSES tag");
$enum->set_default("options");
my($verb,$all,$file);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","noisy or quiet ?",1,\$verb);
$opts->def_bool("all","do it for all files in the change ?",0,\$all);
$opts->def_setx("fix","what fix to apply ?","options",\$fset,$enum);
$opts->def_devf("file","what file to fix ?",undef,\$file);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($file_list);
if($all) {
	$file_list=Meta::Baseline::Aegis::change_files_list(1,1,0,1,1,0);
} else {
	$file_list=[ $file ];
}
for(my($i)=0;$i<=$#$file_list;$i++) {
	my($modu)=$file_list->[$i];
	my($curr)=Meta::Baseline::Aegis::which($modu);
	if($verb) {
		Meta::Utils::Output::print("working on [".$modu."]\n");
	}
	if(Meta::Lang::Perl::Perl::is_perl($modu)) {
		if($fset->has("copyright")) {
			Meta::Baseline::Lang::Perl->fix_copyright($modu,$curr);
		}
		if($fset->has("license")) {
			Meta::Baseline::Lang::Perl->fix_license($modu,$curr);
		}
		if($fset->has("details")) {
			Meta::Baseline::Lang::Perl->fix_details($modu,$curr);
		}
		if($fset->has("author")) {
			Meta::Baseline::Lang::Perl->fix_author($modu,$curr);
		}
		if($fset->has("history")) {
			Meta::Baseline::Lang::Perl->fix_history($modu,$curr);
		}
		if($fset->has("see")) {
			Meta::Baseline::Lang::Perl->fix_see($modu,$curr);
		}
		#fixes just for binaries
		if(Meta::Lang::Perl::Perl::is_bin($modu)) {
			if($fset->has("options")) {
				Meta::Baseline::Lang::Perl->fix_options($modu,$curr);
			}
		}
		#fixes just for libraries
		if(Meta::Lang::Perl::Perl::is_lib($modu)) {
			if($fset->has("version")) {
				Meta::Baseline::Lang::Perl->fix_version($modu,$curr);
			}
			if($fset->has("super")) {
				Meta::Baseline::Lang::Perl->fix_super($modu,$curr);
			}
		}
	}
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

perl_pod_fix.pl - fix pods in perl files.

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

	MANIFEST: perl_pod_fix.pl
	PROJECT: meta
	VERSION: 0.04

=head1 SYNOPSIS

	perl_pod_fix.pl [options]

=head1 DESCRIPTION

This program will fix POD documentation in perl modules or scripts.
You need to tell it what type of fix do you want applied.

Some of the fixes are only relevant to modules, some are only relevant
to scripts and some for both.

The types of fixes currenly supported:

1. copyright: fix the COPYRIGHT pod.
2. license: fix the LICENSE pod.
3. details: fix the DETAILS pod.
4. author: fix the AUTHOR pod.
5. history: fix the HISTORY pod.
6. see: fix the SEE ALSO pod.
7. options: fix the OPTIONS pod (scripts only).
8. version: fix the VERSION pod (modules only).
9. super: fix the SUPER CLASSES pod (modules only).

You can either fix all files in the change or a single file.

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

noisy or quiet ?

=item B<all> (type: bool, default: 0)

do it for all files in the change ?

=item B<fix> (type: setx, default: options)

what fix to apply ?

options:
	copyright - fix the COPYRIGHT tag
	license - fix the LICENSE tag
	details - fix the DETAILS tag
	author - fix the AUTHOR tag
	history - fix the HISTORY tag
	see - fix the SEE ALSO tag
	options - fix the OPTIONS tag
	version - fix the VERSION tag
	super - fix the SUPER CLASSES tag

=item B<file> (type: devf, default: )

what file to fix ?

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
	0.04 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Lang::Perl(3), Meta::Ds::Noset(3), Meta::Info::Enum(3), Meta::Lang::Perl::Perl(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-have this script do checkouts too like documented.

-add options to checkout files if need be.

-add options to just show which changes are going to be made.

-add option to supply a list of files to be fixed.

-add the ability to make several changes simulteneously (using the set type for opts).
