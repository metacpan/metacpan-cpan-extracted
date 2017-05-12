#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Aegis qw();
use Meta::Info::Enum qw();
use Meta::Utils::Parse::Text qw();
use Meta::Utils::Hash qw();
use Meta::Utils::List qw();
use Meta::Tool::Editor qw();
use Meta::Utils::Output qw();
#use Error qw(:try);

my($verb,$demo,$logx,$acti);
my($opts)=Meta::Utils::Opts::Opts->new();
my($enum)=Meta::Info::Enum->new();
$enum->insert("print","print out the actions");
$enum->insert("checkout","checkout the files");
$enum->insert("edit","edit the files");
$enum->set_default("print");
$opts->set_standard();
$opts->def_bool("verbose","noisy or quiet ?",0,\$verb);
$opts->def_bool("demo","play around or do it for real ?",0,\$demo);
$opts->def_devf("log","what log file to use ?","aegis.log",\$logx);
$opts->def_enum("action","what action to apply to the files ?","print",\$acti,$enum);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

$logx=Meta::Baseline::Aegis::which($logx);
my($pars)=Meta::Utils::Parse::Text->new();
my(%hash);
$pars->init_file($logx);
my($infi)=0;
my($cfil);
while(!$pars->get_over()) {
	my($line)=$pars->get_line();
	if($line=~/^cook: doing \[.*\]$/) {
		($cfil)=($line=~/^cook: doing \[(.*)\]$/);
		$infi=1;
	} else {
		if($line=~/^aegis:/) {
		} else {
			if($infi) {
				my($curr)=Meta::Baseline::Aegis::which($cfil);
				$hash{$curr}=defined;
			} else {
#				throw Meta::Error::Simple("error not in a file [".$line."]");
			}
		}
	}
	$pars->next();
}
$pars->fini();

if($enum->is_selected($acti,"print")) {
	Meta::Utils::Hash::print(Meta::Utils::Output::get_file(),\%hash);
}
if($enum->is_selected($acti,"checkout")) {
	my($change)=Meta::Baseline::Aegis::change_files_hash(1,1,0,1,1,1);
	Meta::Utils::Hash::remove_hash(\%hash,$change,0);
	Meta::Baseline::Aegis::checkout_hash(\%hash);
}
if($enum->is_selected($acti,"edit")) {
	if(!$demo) {
	my($list)=Meta::Utils::Hash::to_list(\%hash);
		if(Meta::Utils::List::notempty($list)) {
			Meta::Tool::Editor::edit_mult($list);
		}
	}
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

base_tool_log_do.pl - parse log and operate on error files.

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

	MANIFEST: base_tool_log_do.pl
	PROJECT: meta
	VERSION: 0.25

=head1 SYNOPSIS

	base_tool_log_do.pl

=head1 DESCRIPTION

The purpose of this tool is to parse the log file from the build, find
the files that had problems and do something on them like:
1. checkout.
2. open them up in an editor.
3. checkout and open them up in an editor.
4. checkout and auto replace them.

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

=item B<demo> (type: bool, default: 0)

play around or do it for real ?

=item B<log> (type: devf, default: aegis.log)

what log file to use ?

=item B<action> (type: enum, default: print)

what action to apply to the files ?

options:
	print - print out the actions
	checkout - checkout the files
	edit - edit the files

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

	0.00 MV silense all tests
	0.01 MV more perl quality
	0.02 MV correct die usage
	0.03 MV perl code quality
	0.04 MV more perl quality
	0.05 MV more perl quality
	0.06 MV revision change
	0.07 MV languages.pl test online
	0.08 MV perl reorganization
	0.09 MV perl packaging
	0.10 MV PDMT
	0.11 MV license issues
	0.12 MV md5 project
	0.13 MV database
	0.14 MV perl module versions in files
	0.15 MV thumbnail user interface
	0.16 MV more thumbnail issues
	0.17 MV website construction
	0.18 MV improve the movie db xml
	0.19 MV web site automation
	0.20 MV SEE ALSO section fix
	0.21 MV move tests to modules
	0.22 MV bring movie data
	0.23 MV finish papers
	0.24 MV teachers project
	0.25 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Info::Enum(3), Meta::Tool::Editor(3), Meta::Utils::Hash(3), Meta::Utils::List(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::Parse::Text(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
