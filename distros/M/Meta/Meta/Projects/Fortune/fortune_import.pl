#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Projects::Fortune::Item qw();
use Meta::Projects::Fortune::Node qw();
use Meta::Projects::Fortune::Link qw();
use Meta::Projects::Fortune::Edge qw();
use Meta::Utils::File::Iterator qw();
use Meta::Utils::Output qw();
use Meta::Db::Connections qw();
use Meta::Db::Dbi qw();
use Meta::Db::Ops qw();
use Meta::Class::DBI qw();
use Meta::IO::File qw();

my($connections_file,$con_name,$name,$clean,$dire,$filter,$verbose);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("connections_file","what connections XML file to use ?","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("con_name","what connection name ?",undef,\$con_name);
$opts->def_stri("name","what database name ?","fortune",\$name);
$opts->def_bool("clean","should I clean the database before ?",1,\$clean);
$opts->def_dire("directory","where are the fortune files ?","/usr/share/games/fortunes",\$dire);
$opts->def_stri("filter","what pattern to filter ?",'^.*\.dat$',\$filter);
$opts->def_bool("verbose","should I speak ?",0,\$verbose);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($connections)=Meta::Db::Connections->new_modu($connections_file);
my($connection)=$connections->get_con_null($con_name);

if($clean) {
	#clean the database
	my($dbi)=Meta::Db::Dbi->new();
	$dbi->connect_name($connection,$name);
	Meta::Db::Ops::clean_sa($dbi);
	$dbi->disconnect();
}

Meta::Class::DBI::set_connection($connection,$name);

# get all files in $dire which dont match $filter 

my($root_node)=Meta::Projects::Fortune::Node->new({});
$root_node->name("root");
$root_node->description("this is the root node");
$root_node->commit();

my($iter)=Meta::Utils::File::Iterator->new();
$iter->set_want_dirs(0);
$iter->set_want_files(1);
$iter->add_directory($dire);
$iter->start();
while(!($iter->get_over())) {
	my($curr)=$iter->get_curr();
	my($base)=$iter->get_base();
	if($curr!~$filter) {
		Meta::Utils::Output::verbose($verbose,"working on [".$curr."]\n");
		my($node)=Meta::Projects::Fortune::Node->new({});
		$node->name($base);
		#$node->filename($curr);
		$node->commit();
		my($edge)=Meta::Projects::Fortune::Edge->new({});
		$edge->from_node_id($root_node->id());
		$edge->to_node_id($node->id());
		$edge->commit();
		my($io)=Meta::IO::File->new_reader($curr);
		my($text)="";
		my($line)=$io->getline();
		$text.=$line;
		while(!$io->eof()) {
			if($line eq "%\n") {
				chop($text);
				#Meta::Utils::Output::verbose($verbose,"text is [".$text."]\n");
				my($item)=Meta::Projects::Fortune::Item->new({});
				$item->text($text);
				$item->commit();
				my($link)=Meta::Projects::Fortune::Link->new({});
				$link->item_id($item->id());
				$link->node_id($node->id());
				$link->commit();
				$text="";
			} else {
				$text.=$line;
			}
			$line=$io->getline();
		}
		$io->close();
	}
	$iter->next();
}
$iter->fini();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

fortune_import.pl - import fortune data into the fortune database.

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

	MANIFEST: fortune_import.pl
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	fortune_import.pl [options]

=head1 DESCRIPTION

This program will import fortune data into the fortune database.
The program has various options to control it's activity.
Please consult this manual for the specifics.

How does it do it ?
It will read all files in the specified directory which do not
match the user provided filter (don't worry about the values -
the defaults will do). It the proceeds to parse each file looking
for the \n%\n delimiter. If you don't know what I'm talking about
take a look at the fortune plain text data files. It them proceeds
to put them into the database under the category which is named
after the file name that is being parsed. All categories are connected
to a root category which is created.

The system has been tested on RedHat. Since file layout is different
in different systems you may need ot tweek the paramters to get this
script to work.

I'll try and get some numbers here regarding how long does it take
to import the full fortune database.

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

=item B<connections_file> (type: modu, default: xmlx/connections/connections.xml)

what connections XML file to use ?

=item B<con_name> (type: stri, default: )

what connection name ?

=item B<name> (type: stri, default: fortune)

what database name ?

=item B<clean> (type: bool, default: 1)

should I clean the database before ?

=item B<directory> (type: dire, default: /usr/share/games/fortunes)

where are the fortune files ?

=item B<filter> (type: stri, default: ^.*\.dat$)

what pattern to filter ?

=item B<verbose> (type: bool, default: 0)

should I speak ?

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
	0.01 MV teachers project
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::Class::DBI(3), Meta::Db::Connections(3), Meta::Db::Dbi(3), Meta::Db::Ops(3), Meta::IO::File(3), Meta::Projects::Fortune::Edge(3), Meta::Projects::Fortune::Item(3), Meta::Projects::Fortune::Link(3), Meta::Projects::Fortune::Node(3), Meta::Utils::File::Iterator(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-once Meta::Utils::File::Iter supports filters use that and not do the matching here.
