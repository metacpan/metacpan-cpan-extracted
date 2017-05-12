#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Cook qw();
use Meta::Baseline::Aegis qw();
use Meta::Ds::Oset qw();
use Meta::Utils::File::Copy qw();
use Meta::Utils::Output qw();
use Meta::Utils::Utils qw();
use Meta::Utils::File::Prop qw();
use Meta::Lang::Perl::Perl qw();
use Meta::Development::Scripts qw();
use XML::XPath qw();
use Meta::Tool::Perl qw();

my($modules,$targ,$verbose);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("modules","XML modules file to copy","xmlx/modules/website.xml",\$modules);
$opts->def_dire("directory","directory to copy to","/var/www/html",\$targ);
$opts->def_bool("verbose","should I be noisy ?",1,\$verbose);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($par)=XML::Parser->new();
if(!defined($par)) {
	throw Meta::Error::Simple("unable to create XML::Parser");
}
my($parser)=XML::XPath::XMLParser->new(filename=>$modules->get_abs_path(),parser=>$par);
if(!defined($parser)) {
	throw Meta::Error::Simple("unable to create XML::XPath::XMLParser");
}
my($root_node)=$parser->parse();
my($set)=Meta::Ds::Oset->new();
my($nodes)=$root_node->find('/modules/module/name');
foreach my $node ($nodes->get_nodelist()) {
	my($name)=$node->getChildNode(1)->getValue();
	Meta::Utils::Output::verbose($verbose,"inserting [".$name."]\n");
	$set->insert($name);
}

Meta::Utils::Output::verbose($verbose,"reading dependendencies...\n");
my($graph)=Meta::Baseline::Cook::read_deps_set($set);
my($output_set)=Meta::Ds::Oset->new();
Meta::Utils::Output::verbose($verbose,"getting span...\n");
$graph->all_ou_new($set,$output_set);

for(my($i)=0;$i<$output_set->size();$i++) {
	my($curr)=$output_set->elem($i);
	if(Meta::Utils::Utils::is_relative($curr)) {
		Meta::Utils::Output::verbose($verbose,"working on [".$curr."]\n");
		my($real)=Meta::Baseline::Aegis::which($curr);
		my($outf)=$targ."/".$curr;
		Meta::Utils::File::Copy::syscopy_mkdir($real,$outf);
		#Meta::Utils::File::Prop::same_mode($real,$outf);
		if(Meta::Lang::Perl::Perl::is_bin($curr)) {
			Meta::Development::Scripts::set_runline($outf,"#!".$Meta::Tool::Perl::tool_path." -I".$targ."/perl/lib");
			Meta::Utils::File::Prop::chmod_x($outf);
		}
	}
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

website_copy.pl - copy part of the development tree with dependencies.

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

	MANIFEST: website_copy.pl
	PROJECT: meta
	VERSION: 0.05

=head1 SYNOPSIS

	website_copy.pl [options]

=head1 DESCRIPTION

Give this script a list of files that you're interested in and a writer object that can write
to a destination (local directory, ftp site whatever) and it will calculate the forest spanned by those
files and will copy only these files to the target directory/tar.gz/other

This script currently does NOT use the writer object to deduce which files are already on the target
machine and only copy the difference. This is left as an exercise to the reader.

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

=item B<modules> (type: modu, default: xmlx/modules/website.xml)

XML modules file to copy

=item B<directory> (type: dire, default: /var/www/html)

directory to copy to

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

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

	0.00 MV web site automation
	0.01 MV SEE ALSO section fix
	0.02 MV move tests to modules
	0.03 MV web site development
	0.04 MV weblog issues
	0.05 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Cook(3), Meta::Development::Scripts(3), Meta::Ds::Oset(3), Meta::Lang::Perl::Perl(3), Meta::Tool::Perl(3), Meta::Utils::File::Copy(3), Meta::Utils::File::Prop(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Utils(3), XML::XPath(3), strict(3)

=head1 TODO

-get this script out of here cause it's generic (it has nothing to do with web sites).

-make this script not copy files which are up to date.

-make this script remove files which are not needed on the target.

-make this script use a generic transfer agent (which could do copy but could also do ftp, sftp etc...)

-make this script get a list of files and not a single one out of some generic XML description.

-get ridd of the hardcoding of the perl interpreter here.
