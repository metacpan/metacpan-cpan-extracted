#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Test qw();
use Meta::Db::Def qw();
use Meta::Xml::Writer qw();
use Meta::Lang::Docb::Params qw();
use Meta::Utils::Utils qw();
use Meta::Utils::File::Remove qw();
use Meta::Utils::Output qw();
use Meta::Db::Info qw();
use Meta::IO::File qw();
use Meta::Development::Module qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

Meta::Baseline::Test::redirect_on();

my($module)=Meta::Development::Module->new_name("xmlx/def/pics.xml");
my($def)=Meta::Db::Def->new_modu($module);

my($info)=Meta::Db::Info->new();
$info->set_type("mysql");
$info->set_name($def->get_name());

Meta::Utils::Output::print("select is [".$def->getsql_select($info,"item")."]\n");
Meta::Utils::Output::print("insert is [".$def->getsql_insert($info,"item")."]\n");
Meta::Utils::Output::print("has is [".$def->has_field("item","id")."]\n");
Meta::Utils::Output::print("has is [".$def->has_field("foo","koo")."]\n");

my($field)=$def->get_field("item","id");
Meta::Utils::Output::print("field of item,id is [".$field."]\n");
my($field_num)=$def->get_field_number("item","name");
Meta::Utils::Output::print("field_num of item,name is [".$field_num."]\n");

my($temp)=Meta::Utils::Utils::get_temp_file();
my($outp)=Meta::IO::File->new("> ".$temp);
my($writ)=Meta::Xml::Writer->new(OUTPUT=>$outp,DATA_INDENT=>1,DATA_MODE=>1,UNSAFE=>1);
$writ->xmlDecl();
$writ->comment(Meta::Lang::Docb::Params::get_comment());
$writ->doctype(
	"section",
	Meta::Lang::Docb::Params::get_public()
);
$def->printd($writ);
$writ->end();
$outp->close();
Meta::Utils::File::Remove::rm($temp);

Meta::Baseline::Test::redirect_off();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

def.pl - testing program for the Meta::Db::Def.pm module.

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

	MANIFEST: def.pl
	PROJECT: meta
	VERSION: 0.32

=head1 SYNOPSIS

	def.pl

=head1 DESCRIPTION

This will test the Meta::Db::Def.pm module.
Currently this just reads a def file and prints out the result.

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
	0.06 MV get graph stuff going
	0.07 MV revision change
	0.08 MV pictures in docbooks
	0.09 MV languages.pl test online
	0.10 MV history change
	0.11 MV perl reorganization
	0.12 MV fix up xml parsers
	0.13 MV more c++ stuff
	0.14 MV move def to xml directory
	0.15 MV automatic data sets
	0.16 MV perl packaging
	0.17 MV XSLT, website etc
	0.18 MV more personal databases
	0.19 MV license issues
	0.20 MV md5 project
	0.21 MV database
	0.22 MV perl module versions in files
	0.23 MV graph visualization
	0.24 MV thumbnail user interface
	0.25 MV more thumbnail issues
	0.26 MV website construction
	0.27 MV improve the movie db xml
	0.28 MV web site automation
	0.29 MV SEE ALSO section fix
	0.30 MV move tests to modules
	0.31 MV teachers project
	0.32 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Test(3), Meta::Db::Def(3), Meta::Db::Info(3), Meta::Development::Module(3), Meta::IO::File(3), Meta::Lang::Docb::Params(3), Meta::Utils::File::Remove(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Utils(3), Meta::Xml::Writer(3), strict(3)

=head1 TODO

Nothing.
