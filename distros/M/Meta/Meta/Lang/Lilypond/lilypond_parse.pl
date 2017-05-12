#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Lang::Lily::InfoParser qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();

my($file,$debug);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_devf("file","what lilypond file to use ?","lily/src/jazz/autumn_leaves.ly",\$file);
$opts->def_bool("debug","do you want to debug the parser ?",0,\$debug);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

if($debug) {
	$::RD_TRACE=defined;
}

$file=Meta::Baseline::Aegis::which($file);

my($parser)=Meta::Lang::Lily::InfoParser->new();
#Meta::Utils::Output::print("parser is [".$parser."]\n");
$parser->parse($file);
$parser->print(Meta::Utils::Output::get_file());

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

lilypond_parse.pl - demo Meta::Lang::Lily::InfoParser capabilities.

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

	MANIFEST: lilypond_parse.pl
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	lilypond_parse.pl [options]

=head1 DESCRIPTION

This little program demos the capabilities of the Meta::Lang::Lily::InfoParser parser. It
follows that modules documentation to the letter.

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

=item B<file> (type: devf, default: lily/src/jazz/autumn_leaves.ly)

what lilypond file to use ?

=item B<debug> (type: bool, default: 0)

do you want to debug the parser ?

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
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Lang::Lily::InfoParser(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
