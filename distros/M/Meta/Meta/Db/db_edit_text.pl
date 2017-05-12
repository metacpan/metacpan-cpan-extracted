#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Tool::Editor qw();
use Meta::Utils::Utils qw();
use Meta::Utils::File::File qw();
use Meta::Baseline::Aegis qw();
use Meta::Db::Dbi qw();
use Meta::Utils::Output qw();
use Meta::Utils::File::Remove qw();

my($connections,$database,$table,$field,$select_field,$select_value);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->def_devf("connections","what XML/connections file to use","xmlx/connections/connections.xml",\$connections);
$opts->def_stri("database","what database to work on","elems",\$database);
$opts->def_stri("table","what table to work on","elems",\$table);
$opts->def_stri("field","what field to work on","content",\$field);
$opts->def_stri("select_field","what field to select on","name",\$select_field);
$opts->def_stri("select_value","what value to select on","main",\$select_value);
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

$connections=Meta::Baseline::Aegis::which($connections);

my($dbi)=Meta::Db::Dbi->new();
$dbi->Meta::Db::Dbi::connect_xml($connections,$database);

# get the content of the field from the database

my($stat)="SELECT ".$field." FROM ".$table." WHERE ".$select_field."=".$dbi->quote_simple($select_value);
#Meta::Utils::Output::print("stat is [".$stat."]\n");
my($res)=$dbi->execute_arrayref($stat);
#Meta::Utils::Output::print("res is [".$res."]\n");
if($#$res!=0) {
	throw Meta::Error::Simple("could not get field from db");
}
my($content)=$res->[0][0];
#Meta::Utils::Output::print("content is [".$content."]\n");
#Meta::Utils::System::exit_ok();

# get a temp file name that we can use for editing (usually in /tmp).

my($temp)=Meta::Utils::Utils::get_temp_file();

# save the current content of the field into that file

Meta::Utils::File::File::save($temp,$content);

# open the favorite editor on that file

Meta::Tool::Editor::edit($temp);

# load the content after the editing

my($content);
Meta::Utils::File::File::load($temp,\$content);

# now save it in the database

my($stat2)="UPDATE ".$table." SET ".$field."=".$dbi->quote_simple($content)." WHERE ".$select_field."=".$dbi->quote_simple($select_value);
#Meta::Utils::Output::print("stat2 is [".$stat2."]\n");
$dbi->execute_single($stat2);

# just remove the temp file

Meta::Utils::File::Remove::rm($temp);

Meta::Utils::System::exit(1);

__END__

=head1 NAME

db_edit_text.pl - edit a text field within the database.

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

	MANIFEST: db_edit_text.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	db_edit_text.pl [options]

=head1 DESCRIPTION

This script will enable you to edit a text field within the database using your favorite
editor.

This script receives:
0. connection data to the database.
1. table to be edited.
2. field to be edited.
3. field to select the record by.
4. value that the field should have.

The script will:
0. connect to the database.
1. check that the field specified is indeed a text field.
2. get the record according to the specifier and exit if there is a problem.
3. save the text to a temp file.
4. launch your favorite editor to edit that file.
5. get the resulting text file and store it in the database using UPDATE.

=head1 OPTIONS

=over 4

=item B<connections> (type: devf, default: xmlx/connections/connections.xml)

what XML/connections file to use

=item B<database> (type: stri, default: elems)

what database to work on

=item B<table> (type: stri, default: elems)

what table to work on

=item B<field> (type: stri, default: content)

what field to work on

=item B<select_field> (type: stri, default: name)

what field to select on

=item B<select_value> (type: stri, default: main)

what value to select on

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

	0.00 MV download scripts
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Db::Dbi(3), Meta::Tool::Editor(3), Meta::Utils::File::File(3), Meta::Utils::File::Remove(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-check that the field requested is indeed of type text.

-enable to edit the file in various other editors (gimp etc for images etc...).
