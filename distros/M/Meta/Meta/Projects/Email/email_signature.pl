#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Info::Author qw();
use Meta::Utils::Output qw();
use Meta::Template::Sub qw();
use Meta::Utils::File::File qw();
use XML::LibXSLT qw();
use XML::LibXML qw();
use Meta::Info::Enum qw();

my($enum)=Meta::Info::Enum->new();
$enum->set_name("type selector");
$enum->set_description("this selects which type of signature you want");
$enum->insert("default","standard type");
$enum->insert("friends","signature for friends");
$enum->insert("business","signature for business associates");
$enum->insert("kernel","signature for kernel hacking");
$enum->set_default("source");

my($xml_modu,$xslt_modu,$outf,$write,$type);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("authors_file","what authors/XML file to use as input ?","xmlx/authors/authors.xml",\$xml_modu);
$opts->def_modu("xslt_file","what XSL file to use for the transformation ?","xslt/signature.xsl",\$xslt_modu);
$opts->def_stri("output_file","what output file to write ?","[% home_dir %]/.signature",\$outf);
$opts->def_bool("write","write output file or print to stdout ?",0,\$write);
$opts->def_enum("type","what type of signature ?","default",\$type,$enum);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

$outf=Meta::Template::Sub::interpolate($outf);

my($xml_parser)=XML::LibXML->new();
my($xslt_parser)=XML::LibXSLT->new();
my($source)=$xml_parser->parse_file($xml_modu->get_abs_path());
my($style_doc)=$xml_parser->parse_file($xslt_modu->get_abs_path());
my($stylesheet)=$xslt_parser->parse_stylesheet($style_doc);
my($results)=$stylesheet->transform($source);
my($out)=$stylesheet->output_string($results);
if($write) {
	Meta::Utils::File::File::save($outf,$out);
} else {
	Meta::Utils::Output::print($out);
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

email_signature.pl - provide you with a signature fit for an email.

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

	MANIFEST: email_signature.pl
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	email_signature.pl [options]

=head1 DESCRIPTION

This program assumes that you're using an XML/author file to store
all of your personal information (email, name, address etc...).
It reads this information and provides you with a text which looks
good as a signature at the end of your emails. You can use this
software from your email client directly if it supports running an
external program to provide your signature. This script support having
different types of signatures and if your email client supports running
different stuff for different users then you can combine the two
to make different signatures for different people.

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

=item B<authors_file> (type: modu, default: xmlx/authors/authors.xml)

what authors/XML file to use as input ?

=item B<xslt_file> (type: modu, default: xslt/signature.xsl)

what XSL file to use for the transformation ?

=item B<output_file> (type: stri, default: [% home_dir %]/.signature)

what output file to write ?

=item B<write> (type: bool, default: 0)

write output file or print to stdout ?

=item B<type> (type: enum, default: default)

what type of signature ?

options:
	default - standard type
	friends - signature for friends
	business - signature for business associates
	kernel - signature for kernel hacking

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

	0.00 MV database
	0.01 MV perl module versions in files
	0.02 MV thumbnail user interface
	0.03 MV more thumbnail issues
	0.04 MV website construction
	0.05 MV improve the movie db xml
	0.06 MV web site automation
	0.07 MV SEE ALSO section fix
	0.08 MV move tests to modules
	0.09 MV bring movie data
	0.10 MV web site development
	0.11 MV finish papers
	0.12 MV teachers project
	0.13 MV md5 issues

=head1 SEE ALSO

Meta::Info::Author(3), Meta::Info::Enum(3), Meta::Template::Sub(3), Meta::Utils::File::File(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), XML::LibXML(3), XML::LibXSLT(3), strict(3)

=head1 TODO

-append my public key automatically.

-do some fortune type stuff.

-do different XSLT running according to type received.
