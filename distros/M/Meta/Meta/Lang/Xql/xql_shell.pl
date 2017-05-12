#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Template::Sub qw();
use Meta::Lang::Xql::Shell qw();

my($prompt,$startup,$startup_file,$history,$history_file,$verbose);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_stri("opt_prompt","what prompt to use ?","XQL# ",\$prompt);
$opts->def_bool("opt_startup","use startup file ?",1,\$startup);
$opts->def_stri("opt_startup_file","what startup file ?","[% home_dir %]/.xql_shell.rc",\$startup_file);
$opts->def_bool("opt_history","use history ?",1,\$history);
$opts->def_stri("opt_history_file","what history file to use ?","[% home_dir %]/.xql_shell.hist",\$history_file);
$opts->def_bool("opt_verbose","be verbose ?",1,\$verbose);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

$prompt=Meta::Template::Sub::interpolate($prompt);
$startup_file=Meta::Template::Sub::interpolate($startup_file);
$history_file=Meta::Template::Sub::interpolate($history_file);

my($shell)=Meta::Lang::Xql::Shell->new();

$shell->set_prompt($prompt);
$shell->set_startup($startup);
$shell->set_startup_file($startup_file);
$shell->set_history($history);
$shell->set_history_file($history_file);
$shell->set_verbose($verbose);

$shell->run();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

xql_shell.pl - experiment with xql expressions over xml files until you get the right ones.

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

	MANIFEST: xql_shell.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	xql_shell.pl [options]

=head1 DESCRIPTION

This program is a Readline terminal where you can experiment with Perls
implementation of the XQL standard (XML::XQL). When run, this program
provides you with history and prompt and allows you to evaluate XQL
expressions the results of which are printed on the screen (this is very
similar to various SQL interfaces to various database systems). You
can change the XML input you are working on using the FILE command.

Auto completion is also starting to be worked into this.

Have fun!

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

=item B<opt_prompt> (type: stri, default: XQL# )

what prompt to use ?

=item B<opt_startup> (type: bool, default: 1)

use startup file ?

=item B<opt_startup_file> (type: stri, default: [% home_dir %]/.xql_shell.rc)

what startup file ?

=item B<opt_history> (type: bool, default: 1)

use history ?

=item B<opt_history_file> (type: stri, default: [% home_dir %]/.xql_shell.hist)

what history file to use ?

=item B<opt_verbose> (type: bool, default: 1)

be verbose ?

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

	0.00 MV teachers project
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Lang::Xql::Shell(3), Meta::Template::Sub(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-write the URL fetching utilities.

-use the XQL cache object here.

-enable to show history via HISTORY command (new command).

-replace the type of Opts::Opts argument hist_file with a type which means "either a new or an existing rewritable file".

-same for the startup file.
