#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::File::File qw();
use Meta::Baseline::Aegis qw();
use Meta::Ds::Graph qw();
use Meta::Utils::Output qw();
use Meta::Lang::Perl::Perl qw();

my($verb,$stat);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","noisy or quiet ?",0,\$verb);
$opts->def_bool("stats","print status reports ?",1,\$stat);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($grap)=Meta::Ds::Graph->new();
if($stat) {
	Meta::Utils::Output::print("Getting sources...\n");
}
# this actually needs to be only cpp files
my($sour)=Meta::Baseline::Aegis::source_files_hash(1,1,0,1,1,0);
if($stat) {
	Meta::Utils::Output::print("Constructing nodes...\n");
}
while(my($key,$val)=each(%$sour)) {
	if(Meta::Lang::Perl::Perl::is_perl($key)) {
		$grap->node_insert($key);
	}
}
if($stat) {
	Meta::Utils::Output::print("Got ".$grap->node_size()." nodes\n");
	Meta::Utils::Output::print("Constructing edges...\n");
}
while(my($key,$val)=each(%$sour)) {
	if(Meta::Lang::Perl::Perl::is_perl($key)) {
		my($basename)=File::Basename::basename($key,"\.pm","\.pl");
		my($dirname)=File::Basename::dirname($key);
		my($real)="deps/".$dirname."/".$basename.".deps";
		my($load);
		Meta::Utils::File::File::load_deve($real,$load);
		if(defined($load)) {
			my($addx)=$load=~/^.*\ncascade $key=\n(.*);$/s;
			my(@allx)=split('\n',$addx);
			for(my($i)=0;$i<=$#allx;$i++) {
				my($curr)=$allx[$i];
				#make sure we have the nodes
				$grap->node_insert($key);
				$grap->node_insert($curr);
				$grap->edge_insert($key,$curr);
			}
		}
	}
}
if($stat) {
	Meta::Utils::Output::print("Got ".$grap->edge_size()." edges\n");
	Meta::Utils::Output::print("Checking cycles...\n");
}
#my($numb)=$grap->numb_cycl($verb,Meta::Utils::Output::get_file());
#if($stat) {
#	Meta::Utils::Output::print("found [".$numb."] cycles\n");
#}
my($scod)=1;
#if($numb>0) {
#	$scod=0;
#} else {
#	$scod=1;
#}
Meta::Utils::System::exit($scod);

__END__

=head1 NAME

cpp_check_cycles.pl - check for cycle includes in the baseline.

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

	MANIFEST: cpp_check_cycles.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	cpp_check_cycles.pl

=head1 DESCRIPTION

This will check for cyclic includes in the baseline.
Cyclic includes are redundant since each h file is a set of promises by
the programmer to the compiler and it is protected against double inclusion.
If a cycle exists, then this protection is the only thing keep the C pre
processor from going into an infinite regress, but still it does mean that
the loop is redundant and we can save time by cutting it at the bud.
This check should be run in the post compile stage of the integration or at
a users discretion.

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

=item B<stats> (type: bool, default: 1)

print status reports ?

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

	0.00 MV move tests to modules
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Ds::Graph(3), Meta::Lang::Perl::Perl(3), Meta::Utils::File::File(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-add option to do this from a change and thus do less work (only chec if the new files close any cycles...).
