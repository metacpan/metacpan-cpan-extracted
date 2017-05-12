#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Test qw();
use XML::Parser qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::Output qw();
use Error qw(:try);

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

sub handle_init($$) {
	my($pars,$elem)=@_;
	Meta::Utils::Output::print("in handle init\n");
}

sub handle_final($$) {
	my($pars,$elem)=@_;
	Meta::Utils::Output::print("in handle final\n");
}

sub handle_start($$) {
	my($pars,$elem)=@_;
	Meta::Utils::Output::print("in handle start with elem [".$elem."]\n");
	Meta::Utils::Output::print("context is [".join(".",$pars->context())."]\n");
	print $pars->namespace($elem)."\n";
}

sub handle_end($$) {
	my($pars,$elem)=@_;
	Meta::Utils::Output::print("in handle end with elem [".$elem."]\n");
}

sub handle_char($$) {
	my($pars,$elem)=@_;
	Meta::Utils::Output::print("in handle char with elem [".$elem."]\n");
	Meta::Utils::Output::print("context is [".join(".",$pars->context())."]\n");
}

Meta::Baseline::Test::redirect_on();

my($file)=Meta::Baseline::Aegis::which("xmlx/def/chess.xml");
my($parser)=XML::Parser->new(ErrorContext=>2);
if(!$parser) {
	throw Meta::Error::Simple("didnt get a parser");
}
$parser->setHandlers(
	Init=>\&handle_init,
	Final=>\&handle_final,
	Start=>\&handle_start,
	End=>\&handle_end,
	Char=>\&handle_char,
);
$parser->parsefile($file);

Meta::Baseline::Test::redirect_off();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

parser.pl - test the external XML::Parser module.

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

	MANIFEST: parser.pl
	PROJECT: meta
	VERSION: 0.27

=head1 SYNOPSIS

	parser.pl

=head1 DESCRIPTION

This is a test suite for the XML::Parser package.

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
	0.03 MV correct die usage
	0.04 MV perl code quality
	0.05 MV more perl quality
	0.06 MV more perl quality
	0.07 MV get graph stuff going
	0.08 MV perl qulity code
	0.09 MV revision change
	0.10 MV languages.pl test online
	0.11 MV more c++ stuff
	0.12 MV move def to xml directory
	0.13 MV automatic data sets
	0.14 MV perl packaging
	0.15 MV XSLT, website etc
	0.16 MV license issues
	0.17 MV md5 project
	0.18 MV database
	0.19 MV perl module versions in files
	0.20 MV thumbnail user interface
	0.21 MV more thumbnail issues
	0.22 MV website construction
	0.23 MV improve the movie db xml
	0.24 MV web site automation
	0.25 MV SEE ALSO section fix
	0.26 MV move tests to modules
	0.27 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Baseline::Aegis(3), Meta::Baseline::Test(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), XML::Parser(3), strict(3)

=head1 TODO

Nothing.
