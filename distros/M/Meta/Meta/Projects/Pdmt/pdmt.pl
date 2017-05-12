#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Pdmt::Pdmt qw();
use Meta::Pdmt::Cvs::Aegis qw();
use Meta::Pdmt::Handlers::PerlChecker qw();
use Meta::Pdmt::Handlers::PerlPod qw();
use Meta::Pdmt::Handlers::Dtd2Html qw();
use Meta::Pdmt::Shell qw();

my($prompt,$startup,$startup_file,$history,$history_file,$verbose);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_stri("opt_prompt","what prompt to use ?","PDMT [% node_number %] # ",\$prompt);
$opts->def_bool("opt_startup","use startup file ?",1,\$startup);
$opts->def_stri("opt_startup_file","what startup file ?","[% home_dir %]/.pdmt_shell.rc",\$startup_file);
$opts->def_bool("opt_history","use history ?",1,\$history);
$opts->def_stri("opt_history_file","what history file to use ?","[% home_dir %]/.pdmt_shell.hist",\$history_file);
$opts->def_bool("opt_verbose","be verbose ?",1,\$verbose);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

#$prompt=Meta::Template::Sub::interpolate($prompt);
$startup_file=Meta::Template::Sub::interpolate($startup_file);
$history_file=Meta::Template::Sub::interpolate($history_file);

my($pdmt)=Meta::Pdmt::Pdmt->new();
$pdmt->set_cvs(Meta::Pdmt::Cvs::Aegis->new());
$pdmt->get_handlers()->insert(Meta::Pdmt::Handlers::PerlChecker->new());
$pdmt->get_handlers()->insert(Meta::Pdmt::Handlers::PerlPod->new());
$pdmt->get_handlers()->insert(Meta::Pdmt::Handlers::Dtd2Html->new());
#$pdmt->add_files();

#Meta::Utils::Output::verbose($verb,"after add_files\n");

#$pdmt->get_graph()->build_all();

my($shell)=Meta::Pdmt::Shell->new();

$shell->set_prompt($prompt);
$shell->set_history($history);
$shell->set_history_file($history_file);
$shell->set_startup($startup);
$shell->set_startup_file($startup_file);
$shell->set_verbose($verbose);

$shell->set_pdmt($pdmt);
$shell->set_graph($pdmt->get_graph());
$pdmt->get_graph()->set_verbose(1);

$shell->run();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

pdmt.pl - run the Pdmt system.

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

	MANIFEST: pdmt.pl
	PROJECT: meta
	VERSION: 0.14

=head1 SYNOPSIS

	pdmt.pl [options]

=head1 DESCRIPTION

This program runs a Pdmt server.
This program will:
0. read sources from your source control management system.
1. build the graph.
2. stat the files involved and get a grip on reality.
3. optionally run a build to build targets that you specify.
4. optionally run a server to listen to incoming messages
	which could be:
	0. hey - I just edited this file.
	1. could you please build this target "foo".
	2. could you please build all targets.
	3. I just removed file "foo" from the source management system.
	4. can you tell me if it's ok to remove file "foo" from source
		management ?
	5. could you please show me the damn graph so I could debug it ?
	6. could you please dump the graph to XML format so I could analyze
		it using something...
	7. could you please kill yourself ? 

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

=item B<opt_prompt> (type: stri, default: PDMT [% node_number %] # )

what prompt to use ?

=item B<opt_startup> (type: bool, default: 1)

use startup file ?

=item B<opt_startup_file> (type: stri, default: [% home_dir %]/.pdmt_shell.rc)

what startup file ?

=item B<opt_history> (type: bool, default: 1)

use history ?

=item B<opt_history_file> (type: stri, default: [% home_dir %]/.pdmt_shell.hist)

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

	0.00 MV perl packaging again
	0.01 MV license issues
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV thumbnail user interface
	0.06 MV more thumbnail issues
	0.07 MV website construction
	0.08 MV improve the movie db xml
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV move tests to modules
	0.12 MV teachers project
	0.13 MV more pdmt stuff
	0.14 MV md5 issues

=head1 SEE ALSO

Meta::Pdmt::Cvs::Aegis(3), Meta::Pdmt::Handlers::Dtd2Html(3), Meta::Pdmt::Handlers::PerlChecker(3), Meta::Pdmt::Handlers::PerlPod(3), Meta::Pdmt::Pdmt(3), Meta::Pdmt::Shell(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
