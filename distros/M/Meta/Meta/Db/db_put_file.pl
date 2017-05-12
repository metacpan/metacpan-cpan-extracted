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

my($verbose,$connections,$database,$table,$field,$select_field,$select_value,$file);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->def_bool("verbose","should I be noisy ?",0,\$verbose);
$opts->def_devf("connections","what XML/connections file to use","xmlx/connections/connections.xml",\$connections);
$opts->def_stri("database","what database to work on","elems",\$database);
$opts->def_stri("table","what table to work on","elems",\$table);
$opts->def_stri("field","what field to work on","content",\$field);
$opts->def_stri("select_field","what field to select on","name",\$select_field);
$opts->def_stri("select_value","what value to select on","logo",\$select_value);
$opts->def_devf("file","what file to put","jpgx/simul.jpg",\$file);
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

$connections=Meta::Baseline::Aegis::which($connections);
$file=Meta::Baseline::Aegis::which($file);

my($dbi)=Meta::Db::Dbi->new();
$dbi->Meta::Db::Dbi::connect_xml($connections,$database);

# get the content of the field from the file

my($content);
Meta::Utils::File::File::load($file,\$content);

# now save it in the database

my($stat2)="UPDATE ".$table." SET ".$field."=".$dbi->quote_simple($content)." WHERE ".$select_field."=".$dbi->quote_simple($select_value);
Meta::Utils::Output::verbose($verbose,"stat2 is [".$stat2."]\n");
$dbi->execute_single($stat2);

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

db_put_file.pl - edit a text field within the database.

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

	MANIFEST: db_put_file.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	db_put_file.pl [options]

=head1 DESCRIPTION

This script enables you to load the content of a file into a database field
(long text, image, audio, video or whatever).

This script receives:
0. connection data to the database.
1. table to be edited.
2. field to be edited.
3. field to select the record by.
4. value that the field should have.
5. file whos content should be loaded into the database.

The script will:
0. connect to the database.
1. check that the field specified is indeed a binary field.
2. load the file you gave it into ram.
3. save the content into the database.

=head1 OPTIONS

=over 4

=item B<verbose> (type: bool, default: 0)

should I be noisy ?

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

=item B<select_value> (type: stri, default: logo)

what value to select on

=item B<file> (type: devf, default: jpgx/simul.jpg)

what file to put

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

-enacpsulate what this script is doing in a module so I can write massive upload script easily.
