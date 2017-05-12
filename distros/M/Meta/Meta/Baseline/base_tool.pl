#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Switch qw();
use Meta::Utils::Output qw();

my($type_enum)=Meta::Baseline::Switch::get_type_enum();
my($lang_enum)=Meta::Baseline::Switch::get_lang_enum();
my($verb,$type,$lang);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_stri("verbose","should I be noisy ?",0,\$verb);
$opts->def_enum("type","type of tool",undef,\$type,$type_enum);
$opts->def_enum("lang","language",undef,\$lang,$lang_enum);
$opts->set_free_allo(1);
$opts->set_free_stri("[modu] [srcx] [targ] [path]");
$opts->set_free_mini(4);
$opts->set_free_maxi(4);
$opts->analyze(\@ARGV);

my($modu,$srcx,$targ,$path)=($ARGV[0],$ARGV[1],$ARGV[2],$ARGV[3]);
if($verb) {
	Meta::Utils::Output::print("modu is [".$modu."]\n");
	Meta::Utils::Output::print("srcx is [".$srcx."]\n");
	Meta::Utils::Output::print("targ is [".$targ."]\n");
	Meta::Utils::Output::print("path is [".$path."]\n");
	Meta::Utils::Output::print("type is [".$type."]\n");
	Meta::Utils::Output::print("lang is [".$lang."]\n");
}
my($scod)=Meta::Baseline::Switch::run_module($modu,$srcx,$targ,$path,$type,$lang);
Meta::Utils::System::exit($scod);

__END__

=head1 NAME

base_tool.pl - run baseline tools.

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

	MANIFEST: base_tool.pl
	PROJECT: meta
	VERSION: 0.16

=head1 SYNOPSIS

	base_tool.pl

=head1 DESCRIPTION

This is our swiss army knife as it will activate language modules for you.

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

=item B<verbose> (type: stri, default: 0)

should I be noisy ?

=item B<type> (type: enum, default: )

type of tool

options:
	aspe - aspe
	temp - temp
	ccxx - ccxx
	cxxx - cxxx
	sgml - sgml
	chun - chun
	java - java
	lily - lily
	perl - perl
	pyth - pyth
	rule - rule
	txtx - txtx
	data - data
	rcxx - rcxx
	patc - patc
	ascx - ascx
	html - html
	cssx - cssx
	dirx - dirx
	cook - cook
	aegi - aegi
	xmlx - xmlx
	xslt - xslt
	pngx - pngx
	jpgx - jpgx
	epsx - epsx
	awkx - awkx
	conf - conf
	targ - targ
	texx - texx
	deps - deps
	chec - chec
	clas - clas
	dvix - dvix
	objs - objs
	psxx - psxx
	info - info
	rtfx - rtfx
	mifx - mifx
	midi - midi
	bins - bins
	dlls - dlls
	libs - libs
	pyob - pyob
	dtdx - dtdx
	swig - swig
	gzxx - gzxx
	pack - pack
	dslx - dslx
	pdfx - pdfx
	dbxx - dbxx
	manx - manx
	nrfx - nrfx
	bdbx - bdbx
	late - late
	lyxx - lyxx

=item B<lang> (type: enum, default: )

language

options:
	aspe - aspe
	temp - temp
	ccxx - ccxx
	cxxx - cxxx
	sgml - sgml
	chun - chun
	java - java
	lily - lily
	perl - perl
	pyth - pyth
	rule - rule
	txtx - txtx
	data - data
	rcxx - rcxx
	patc - patc
	ascx - ascx
	html - html
	cssx - cssx
	dirx - dirx
	cook - cook
	aegi - aegi
	xmlx - xmlx
	xslt - xslt
	pngx - pngx
	jpgx - jpgx
	epsx - epsx
	awkx - awkx
	conf - conf
	targ - targ
	texx - texx
	deps - deps
	chec - chec
	clas - clas
	dvix - dvix
	objs - objs
	psxx - psxx
	info - info
	rtfx - rtfx
	mifx - mifx
	midi - midi
	bins - bins
	dlls - dlls
	libs - libs
	pyob - pyob
	dtdx - dtdx
	swig - swig
	gzxx - gzxx
	pack - pack
	dslx - dslx
	pdfx - pdfx
	dbxx - dbxx
	manx - manx
	nrfx - nrfx
	bdbx - bdbx
	late - late
	lyxx - lyxx

=back

minimum of [4] free arguments required
no maximum limit on number of free arguments placed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV better general cook schemes
	0.01 MV languages.pl test online
	0.02 MV history change
	0.03 MV perl packaging
	0.04 MV license issues
	0.05 MV md5 project
	0.06 MV database
	0.07 MV perl module versions in files
	0.08 MV thumbnail user interface
	0.09 MV more thumbnail issues
	0.10 MV website construction
	0.11 MV improve the movie db xml
	0.12 MV web site automation
	0.13 MV SEE ALSO section fix
	0.14 MV move tests to modules
	0.15 MV finish papers
	0.16 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Switch(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
