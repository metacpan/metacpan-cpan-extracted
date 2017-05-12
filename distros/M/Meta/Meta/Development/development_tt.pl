#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::File::File qw();
use Template::Parser qw();

my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($file)="temp/html/projects/Website/computing.temp";
my($text);
Meta::Utils::File::File::load_deve($file,\$text);
my($parser)=Template::Parser->new();
my($document)=$parser->parse($text);
if(!$document) {
	throw Meta::Error::Simple("unable to parse document");
}
Meta::Utils::Output::print("document is [".$document."]\n");
while(my($key,$val)=each(%$document)) {
	Meta::Utils::Output::print("key is [".$key."]\n");
}
my($defblocks)=$document->{DEFBLOCKS};
my($block)=$document->{BLOCK};
my($metadata)=$document->{METADATA};
Meta::Utils::Output::print("defblocks is [".$defblocks."]\n");
Meta::Utils::Output::print("block is [".$block."]\n");
Meta::Utils::Output::print("metadata is [".$metadata."]\n");
#while(my($key,$val)=each(%$defblocks)) {
#	Meta::Utils::Output::print("key,val is [".$key.",".$val."]\n");
#}
#my($blocks)=$document->blocks();
#Meta::Utils::Output::print("blocks is [".$blocks."]\n");

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

development_tt.pl - demo template toolkit parsing.

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

	MANIFEST: development_tt.pl
	PROJECT: meta
	VERSION: 0.03

=head1 SYNOPSIS

	development_tt.pl [options]

=head1 DESCRIPTION

This module demos how to parse and analyze Template tookit files. Why
would you need that ? Well - for extracting dependencies for instance
and other stuff. May the source be with you.

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

	0.00 MV web site automation
	0.01 MV SEE ALSO section fix
	0.02 MV move tests to modules
	0.03 MV md5 issues

=head1 SEE ALSO

Meta::Utils::File::File(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), Template::Parser(3), strict(3)

=head1 TODO

Nothing.
