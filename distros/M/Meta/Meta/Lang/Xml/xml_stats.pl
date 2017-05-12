#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Ds::Ohash qw();
use XML::Parser qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();

my($file);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->def_devf("file","which xml file to use","xmlx/movie/movie.xml",\$file);
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($hash)=Meta::Ds::Ohash->new();
$file=Meta::Baseline::Aegis::which($file);

sub handle_start($$) {
	my($expat,$tag)=@_;
#	Meta::Utils::Output::print("arg1 is [".$arg1."]\n");
#	Meta::Utils::Output::print("arg2 is [".$arg2."]\n");
#	Meta::Utils::Output::print("tag is [".$tag."]\n");
#	my($elem)=$hash->get($tag);
#	Meta::Utils::Output::print("elem is [".$elem."]\n");
	if($hash->has($tag)) {
		my($curr)=$hash->get($tag);
#		Meta::Utils::Output::print("in here with tag [".$tag."]\n");
#		Meta::Utils::Output::print("in here with curr [".$curr."]\n");
		$curr+=1;
		$hash->overwrite($tag,$curr);
	} else {
		$hash->put($tag,1);
	}
}

my($parser)=XML::Parser->new(Handlers=>{
		Start=>\&handle_start,
});
$parser->parsefile($file);
for(my($i)=0;$i<$hash->size();$i++) {
	Meta::Utils::Output::print($hash->key($i)." ".$hash->val($i)."\n");
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

xml_stats.pl - print statistics about an XML file.

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

	MANIFEST: xml_stats.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	xml_stats.pl [options]

=head1 DESCRIPTION

This program accepts an input XML file and prints statistics about its content.
For each element and attrbitues it will print number of times they appeared.
For each element it will print the expectancy and variance of number of elements
within it.

The output of the program may change with time and more statistics and attributes
will be calculated and added to the output. Methods of controlling which statistics
are gathered may also be added.

=head1 OPTIONS

=over 4

=item B<file> (type: devf, default: xmlx/movie/movie.xml)

which xml file to use

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

	0.00 MV move tests to modules
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Ds::Ohash(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), XML::Parser(3), strict(3)

=head1 TODO

Nothing.
