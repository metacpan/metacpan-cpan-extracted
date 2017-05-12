#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Xml::Resolver;

use strict qw(vars refs subs);
use Meta::Utils::Output qw();
use Data::Dumper qw();
use Meta::Baseline::Aegis qw();
use Meta::IO::File qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw();

#sub new($);
#sub resolve_entity($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	CORE::bless($self,$class);
	return($self);
}

sub resolve_entity($$) {
	my($self,$hash)=@_;
	Meta::Utils::Output::print("self is [".$self."]");
	Meta::Utils::Output::print("hash is [".$hash."]");
#	print Data::Dumper::Dumper($hash);
#	print Data::Dumper::Dumper($self);
	my($SystemId)=$hash->{"SystemId"};
	my($full)="dtdx/".$SystemId;
	my($resolved)=Meta::Baseline::Aegis::which($full);
#	The following line does not work (not yet imlemented).
#	return(Source=>{SystemId=>$resolved});
	my($io)=Meta::IO::File->new_reader($resolved);
	return(Source=>{ByteStream=>$io});
#	return(undef);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Xml::Resolver - external entity (DTD) resolver for Aegis type development.

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

	MANIFEST: Resolver.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Xml::Resolver qw();
	my($object)=Meta::Lang::Xml::Resolver->new();
	my($result)=$object->resolve_entity($self,$Name,...);

=head1 DESCRIPTION

Use this resolver whenever you create SAX type XML parsers so that external
entities (DTDs) are resolved corretly in an Aegis type development
environment.

=head1 FUNCTIONS

	new($)
	resolve_entity($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Lang::Xml::Resolver object.

=item B<resolve_entity($$)>

This method actually does the resolving.

=item B<TEST($)>

This is a testing suite for the Meta::Lang::Xml::Resolver module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

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

	0.00 MV move tests into modules
	0.01 MV md5 issues

=head1 SEE ALSO

Data::Dumper(3), Meta::Baseline::Aegis(3), Meta::IO::File(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.
