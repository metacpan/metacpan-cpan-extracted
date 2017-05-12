#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Dom;

use strict qw(vars refs subs);
use XML::DOM::ValParser qw();
use XML::DOM qw();
use Meta::Baseline::Aegis qw();

our($VERSION,@ISA);
$VERSION="0.11";
@ISA=qw();

#sub new($);
#sub new_vali($$);
#sub parsefile($$);
#sub parsedeve($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	$self->{PARSER}=XML::DOM::ValParser->new();
	bless($self,$class);
	return($self);
}

sub new_vali($$) {
	my($class,$vali)=@_;
	my($self)={};
	if($vali) {
		$self->{PARSER}=XML::DOM::ValParser->new();
	} else {
		$self->{PARSER}=XML::DOM::Parser->new();
	}
	bless($self,$class);
	return($self);
}

sub parsefile($$) {
	my($self,$file)=@_;
	return($self->{PARSER}->parsefile($file));
}

sub parsedeve($$) {
	my($self,$file)=@_;
	$self->parsefile(Meta::Baseline::Aegis::which($file));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Dom - XML/DOM parser.

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

	MANIFEST: Dom.pm
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Dom qw();
	my($object)=Meta::Xml::Dom->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This object is here to be an XML::DOM::ValParser object which will hide some
of the drawbacks of the Perl native XML::DOM::ValParser object. For instace,
I would like to set, at runtime, whether the object will do validation or
not. I would also like to hide the multi directory structure of where the
source file is coming from.

=head1 FUNCTIONS

	new($)
	new_vali($$)
	parsefile($$)
	parsedeve($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Xml::Dom object.
By default it constructs a validating parser.

=item B<new_vali($$)>

This is a constructor for the Meta::Xml::Dom object.
It also receives a boolean telling it whether or not to construct a validating parser.

=item B<parsefile($$)>

This method parses a file using the parser.

=item B<parsedeve($$)>

This method will ultimately perform a "parsefile" but will retrieve the file from the
project hierarchy.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV fix database problems
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV movies and small fixes
	0.05 MV thumbnail user interface
	0.06 MV more thumbnail issues
	0.07 MV md5 project
	0.08 MV website construction
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), XML::DOM(3), XML::DOM::ValParser(3), strict(3)

=head1 TODO

Nothing.
