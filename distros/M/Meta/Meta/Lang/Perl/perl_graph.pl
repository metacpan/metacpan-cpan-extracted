#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Visualization::Graph qw();
use GraphViz::ISA qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();

my($outfile,$type);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_newf("outfile","what output file ?","/tmp/out.file",\$outfile);
$opts->def_enum("type","what type of output file ?","ps",\$type,Meta::Visualization::Graph::get_enum());
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($graph)=Meta::Visualization::Graph->new(width=>8.5,height=>11);
my($sour)=Meta::Baseline::Aegis::source_files_hash(1,1,0,1,1,0);
while(my($key,$val)=each(%$sour)) {
	if(Meta::Lang::Perl::Perl::is_lib($key)) {
		my($module)=Meta::Lang::Perl::Perl::file_to_module($key);
		$graph->add_node($module);
		my($isa)=Meta::Lang::Perl::Perl::get_isa($key);
		for(my($i)=0;$i<=$#$isa;$i++) {
			my($curr)=$isa->[$i];
			#Meta::Utils::Output::print("curr is [".$curr."]\n");
			$graph->add_edge($module,$curr);
		}
	}
}
$graph->as_type($type,$outfile);

#my($g)=GraphViz::ISA->new('Meta::Ds::Ohash');
#Meta::Utils::Output::print("type is [".$type."]\n");
#Meta::Visualization::Graph::as_type($g,$type,$outfile);
#$g->as_png($outfile);

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

perl_graph.pl - make a graph to visualize Perl aspects.

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

	MANIFEST: perl_graph.pl
	PROJECT: meta
	VERSION: 0.03

=head1 SYNOPSIS

	perl_graph.pl [options]

=head1 DESCRIPTION

This script will generate usage graphs or ISA graphs from the
internal/external perl modules. Hope you like this.
It makes use of the GraphViz package to achieve this.

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

=item B<outfile> (type: newf, default: /tmp/out.file)

what output file ?

=item B<type> (type: enum, default: ps)

what type of output file ?

options:
	canon - canon
	text - text
	ps - ps
	hpgl - hpgl
	pcl - pcl
	mif - mif
	pic - pic
	gd - gd
	gd2 - gd2
	gif - gif
	jpeg - jpeg
	png - png
	wbmp - wbmp
	ismap - ismap
	imap - imap
	vrml - vrml
	vtx - vtx
	mp - mp
	fig - fig
	svg - svg
	plain - plain

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
	0.02 MV finish papers
	0.03 MV md5 issues

=head1 SEE ALSO

GraphViz::ISA(3), Meta::Baseline::Aegis(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Visualization::Graph(3), strict(3)

=head1 TODO

Nothing.
