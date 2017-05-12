#!/bin/echo This is a perl module and should not be run

package Meta::Info::SecurityKey;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw();

#sub BEGIN();
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_title",
		-java=>"_code",
		-java=>"_server",
		-java=>"_passphrase",
		-java=>"_public_key_url",
		-java=>"_sig_name",
		-java=>"_sig_comment",
		-java=>"_sig_email",
	);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Info::SecurityKey - Store a single system IM information for author.

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

	MANIFEST: SecurityKey.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Info::SecurityKey qw();
	my($object)=Meta::Info::SecurityKey->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class stores the details of a single security key.

=head1 FUNCTIONS

	BEGIN()
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is a bootstrap method to set the following attributes:
0. "title" - title for this security key.
1. "code" - the hex code for this security key.
2. "server" - key server for this key.
3. "passphrase" - pass phrase for this key.
4. "public_key_url" - url where public key can be downloaded from.
5. "sig_name" - name on signature of key.
6. "sig_comment" - comment on signature of key.
7. "sig_email" - email on signature of key.

=item B<TEST($)>

This is a testing suite for the Meta::Info::SecurityKey module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

This test currently does nothing.

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

	0.00 MV finish papers
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), strict(3)

=head1 TODO

Nothing.
