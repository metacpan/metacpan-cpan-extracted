#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Lily::InfoParser;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();
use Parse::RecDescent qw();
use Meta::Utils::Output qw();
use Meta::Utils::File::File qw();

our($VERSION,@ISA,$grammar,$curr);
$VERSION="0.03";
@ISA=qw(Parser::RecDescent);

#sub BEGIN();
#sub new($);
#sub parse($$);
#sub deslashify($);
#sub handle_assignment();
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_filename",
		-java=>"_title",
		-java=>"_subtitle",
		-java=>"_composer",
		-java=>"_enteredby",
		-java=>"_copyright",
		-java=>"_style",
		-java=>"_source",
	);
	Meta::Class::MethodMaker->print(
		[
		"filename",
		"title",
		"subtitle",
		"composer",
		"enteredby",
		"copyright",
		"style",
		"source",
		]
	);
}

#sub new($) {
#	#$Parse::RecDescent::skip='[ \t]+';
#	my($class)=@_;
#	my($self)=Parse::RecDescent->new($grammar);;
#	if(!$self) {
#		throw Meta::Error::Simple("unable to generate parser");
#	}
#	bless($self,$class);
#	return($self);
#}

sub parse($$) {
	my($self,$file)=@_;
	# all the magic is here
	$Parse::RecDescent::skip='[ \v\t\n]*';
	my($parser)=Parse::RecDescent->new($grammar);;
	if(!$parser) {
		throw Meta::Error::Simple("unable to generate parser");
	}
	my($text);
	Meta::Utils::File::File::load($file,\$text);
	$curr=$self;
	if(!$parser->lilyfile($text)) {
		throw Meta::Error::Simple("failed in parsing [".$file."]");
	}
}

sub deslashify($) {
	my($string)=@_;
	$string=~s/\\//g;
	return($string);
}

sub handle_assignment($$) {
	my($key,$val)=@_;
	#Meta::Utils::Output::print("in assignment\n");
	#Meta::Utils::Output::print("key is [".$key."]\n");
	#Meta::Utils::Output::print("val is [".$val."]\n");
	$val=substr($val,1,-1);
	$val=deslashify($val);
	if($key eq "filename") {
		$curr->set_filename($val);
	}
	if($key eq "title") {
		$curr->set_title($val);
	}
	if($key eq "subtitle") {
		$curr->set_subtitle($val);
	}
	if($key eq "composer") {
		$curr->set_composer($val);
	}
	if($key eq "enteredby") {
		$curr->set_enteredby($val);
	}
	if($key eq "copyright") {
		$curr->set_copyright($val);
	}
	if($key eq "style") {
		$curr->set_style($val);
	}
	if($key eq "source") {
		$curr->set_source($val);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

our($curr);

#value: /"[\éA-Za-z0-9 _&]*"/
#value: /".*"/
# <skip: '[ \t\v]+'>
our($grammar)=q{
	lilyfile: section(s)
	section: keyword '{' statement(s?) '}' | keyword '{' any '}'
	statement: assignment
	assignment: var '=' quoted_value
	{
		Meta::Lang::Lily::InfoParser::handle_assignment($item[1],$item[3]);
		1;
	}
	var: /[A-Za-z0-9_]+/
	quoted_value: /"[\.@\éA-Z��\\\\a-z0-9 _,()&]*"/
	any: /.*/
	keyword:
		'\chords' |
		'\header' |
		'\alternative' |
		'\break' |
		'\bar'
};

1;

__END__

=head1 NAME

Meta::Lang::Lily::InfoParser - parser for Lilypond general info.

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

	MANIFEST: InfoParser.pm
	PROJECT: meta
	VERSION: 0.03

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Lily::InfoParser qw();
	my($parser)=Meta::Lang::Lily::InfoParser->new();
	my($res)=$parser->parse("autumn_leaves.ly");
	if(!$res) {
		die("bad bad file!!!");
	}
	my($composer)=$object->get_composer();
	# composer should now be Joseph Kosma & Jacques Prévert

=head1 DESCRIPTION

This documentation assumes that you know what Lilypond is. If not
then get to know it (http://www.lilypond.org).

This module takes lilypond files as input and extracts the header
information out of them.

A Lilypond header looks like this:

\header{
	filename="chega_de_saudae.ly"
	title="Chega De Saudade"
	subtitle="No More Blues"
	composer="Antonio Carlos Jobim"
	enteredby="Laurent Martelli"
	copyright="© 1962,1967 Editora Musical Arapua, Sao Paulo, Brazil"
	style="Jazz"
	source="laurent@bearteam.org"
}

And the tags here are the only ones currently supported by this module.

To use this module all you need to do is create a parser and then call its
parse method. After the method is over you can you the accessor methods
to get the various tags. Any tag that wasn't found will have the default
value of "" (nothing).

If you need any enhancements to this module please email me.

This module uses the excellect Parse::RecDescent module to do it's thing.

=head1 FUNCTIONS

	BEGIN()
	new($)
	parse($$)
	deslashify($)
	handle_assignment()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is an object initializer which sets up accessor methods for the
following attributes:
title : title of the piece.
subtitle : sub title of the piece.
composer : composer of the piece.
enteredby : the author of the lilypond file.
copyright : holder of copyright for the piece.
style : style of the piece.
source : source of the piece.

=item B<new($)>

A constructor for this object.

=item B<parse($$)>

This is the actual method which does the parsing. You need to give
it a parser object and a file to parse.

=item B<deslashify($)>

This method removes slashes put in the lilypond values to protect
certain characters.

=item B<handle_assignment()>

This method handles assignments to variables.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Parser::RecDescent(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV web site development
	0.01 MV web site automation
	0.02 MV SEE ALSO section fix
	0.03 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Utils::File::File(3), Meta::Utils::Output(3), Parse::RecDescent(3), strict(3)

=head1 TODO

-add more parsing capabilities (midi, score etc...).

-make this module inherit from Parse::RecDescent. I had problems with it so I stopped trying and some of the code is still there commented out.

-this module is not threading safe. (because of the global var).

-the declaration of the values here do not allow for all special characters and so I added a few there but this is hardly satisfactory.
