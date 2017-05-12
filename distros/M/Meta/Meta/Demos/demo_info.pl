#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Module::Info qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

#my($mod)=Module::Info->new_from_module('Meta::Utils::System');
#my($mod)=Module::Info->new_from_file(Meta::Baseline::Aegis::which("perl/lib/Meta/Ds/Hash.pm"));
my($mod)=Module::Info->new_from_module('Meta::Ds::Ohash');
if(!$mod) {
	die("unable to load module\n");
}

my($name)=$mod->name();
my($version)=$mod->version();
my($dir)=$mod->inc_dir();
my($file)=$mod->file();
my($is_core)=$mod->is_core();

Meta::Utils::Output::print("name is [".$name."]\n");
Meta::Utils::Output::print("version is [".$version."]\n");
Meta::Utils::Output::print("dir is [".$dir."]\n");
Meta::Utils::Output::print("file is [".$file."]\n");
Meta::Utils::Output::print("is_core is [".$is_core."]\n");

my(%subs)=$mod->subroutines();
#Meta::Utils::Output::print("after subroutines ".join(",",keys(%subs))."\n");
while(my($key,$val)=each(%subs)) {
	while(my($kk,$vv)=each(%$val)) {
#		Meta::Utils::Output::print("kk is [".$kk."]\n");
#		Meta::Utils::Output::print("vv is [".$vv."]\n");
	}
#	Meta::Utils::Output::print("key is [".$key."]\n");
#	Meta::Utils::Output::print("val is [".$val."]\n");
}
my(%subs_called)=$mod->subroutines_called();
Meta::Utils::Output::print("after subroutines_called ".join(",",keys(%subs_called))."\n");
while(my($key,$val)=each(%subs_called)) {
	while(my($kk,$vv)=each(%$val)) {
#		Meta::Utils::Output::print("kk is [".$kk."]\n");
#		Meta::Utils::Output::print("vv is [".$vv."]\n");
	}
#	Meta::Utils::Output::print("key [".$key."]\n");
#	Meta::Utils::Output::print("val [".$val."]\n");
}
my(@superclasses)=$mod->superclasses();
for(my($i)=0;$i<=$#superclasses;$i++) {
	my($curr)=$superclasses[$i];
	Meta::Utils::Output::print("super class is [".$curr."]\n");
}
my(@used)=$mod->modules_used();
for(my($i)=0;$i<=$#used;$i++) {
	my($curr)=$used[$i];
	Meta::Utils::Output::print("used is [".$curr."]\n");
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

demo_info.pl - Demo capabilities of Module::Info.

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

	MANIFEST: demo_info.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	info.pl [options]

=head1 DESCRIPTION

This program shows you what you can do with Module::Info.

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

	0.00 MV finish papers
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), Module::Info(3), strict(3)

=head1 TODO

Nothing.
