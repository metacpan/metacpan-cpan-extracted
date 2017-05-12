#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Curses::UI qw();
use Meta::Utils::Output qw();
use Meta::Projects::Weblog::Item qw();
use Meta::Utils::Time qw();
use Meta::Db::Connections qw();
use Meta::Class::DBI qw();

my($connections_file,$con_name,$name);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("connections_file","what connections XML file to use ?","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("con_name","what connection name ?",undef,\$con_name);
$opts->def_stri("name","what database name ?","weblog",\$name);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($connections)=Meta::Db::Connections->new_modu($connections_file);
my($connection)=$connections->get_con_null($con_name);
Meta::Class::DBI::set_connection($connection,$name);

my($entry_name,$entry_description,$entry_content);

sub do_add($) {
	my($self)=@_;
	#Meta::Utils::Output::print("self is [".$self."]\n");
	my($new_entry)=Meta::Projects::Weblog::Item->new({});
	$new_entry->personid(1);
	$new_entry->name($entry_name->get());
	$new_entry->description($entry_description->get());
	$new_entry->content($entry_content->get());
	$new_entry->time(Meta::Utils::Time::now_mysql());
	$new_entry->commit();
	# now clear all the entries
	$entry_name->text("");
	$entry_name->draw();
	$entry_description->text("");
	$entry_description->draw();
	$entry_content->text("");
	$entry_content->draw();
}

sub do_quit() {
	my($self)=@_;
	Meta::Utils::System::exit_ok();
}

my($cui)=Curses::UI->new(
	-clear_on_exit=>0,
	-debug=>undef,
);
my($win)=$cui->add(
	'window_id','Window',
	-title=>'Weblog event adder',
	-border=>1,
);
my($buttons)=$win->add(
	'buttons','Buttonbox',
	'-y'=>-1,
	-buttons=> [
		{
			-label=>'<Add>',
			-value=>'add',
			-onpress=>\&do_add,
		},
		{
			-label=>'<Quit>',
			-value=>'quit',
			-onpress=>\&do_quit,
		},
	],
	-border=>1,
);
$entry_name=$win->add(
	'entry_name','TextEntry',
	-title=>'Name',
	-y=>0,
	-border=>1,
);
$entry_description=$win->add(
	'entry_description','TextEntry',
	-title=>'Description',
	-y=>3,
	-border=>1,
);
$entry_content=$win->add(
	'entry_content','TextEditor',
	-title=>'Content',
	-y=>6,
	-padbottom=>3,
	-border=>1,
);
#$cui->dialog("Hello,\sWorld!");
Curses::UI::MainLoop();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

weblog_cui.pl - curses based interface to the weblog system.

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

	MANIFEST: weblog_cui.pl
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	weblog_cui.pl [options]

=head1 DESCRIPTION

This is a program which provides you with a curses interface to the META weblog system.
It will present you with a user interface to insert new weblog items, search for weblog
items matching certain criteria and delete weblog items.

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

=item B<name> (type: stri, default: weblog)

what database name ?

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

	0.00 MV weblog issues
	0.01 MV teachers project
	0.02 MV md5 issues

=head1 SEE ALSO

Curses::UI(3), Meta::Class::DBI(3), Meta::Db::Connections(3), Meta::Projects::Weblog::Item(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Time(3), strict(3)

=head1 TODO

Nothing.
