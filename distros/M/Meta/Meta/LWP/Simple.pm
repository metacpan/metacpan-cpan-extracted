#!/bin/echo This is a perl module and should not be run

package Meta::LWP::Simple;

use strict qw(vars refs subs);
use Meta::Projects::Webcache::Content qw();
use LWP::Simple qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(LWP::Simple);

#sub get_cache($$);
#sub TEST($);

#__DATA__

sub get_cache($$) {
	my($self,$url)=@_;
	my(@data)=Meta::Projects::Webcache::Content->search(url=>$url);
	if($#data>0) {
		throw Meta::Error::Simple("something terribyl wrong happened");
	} else {
		if($#data==-1) {
			return($self->SUPER::get($url));
		} else {
			return($data[0]->content());
		}
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::LWP::Simple - extend LWP::Simple with RDMBS caching.

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

	MANIFEST: Simple.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::LWP::Simple qw();
	my($object)=Meta::LWP::Simple->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module extends LWP::Simple with RDMBS caching using my webcache database
and the object which support using it for web cache storage.

=head1 FUNCTIONS

	get_cache($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<get_cache($$)>

Use this method instead of the regular LWP::Simple::get method to get content. In case the
content is in the cache it will be retrieved from the RDBMS cache. Please make sure that
the connection to the RDBMS is faster than to the remote website...:)

=item B<TEST($)>

This is a testing suite for the Meta::LWP::Simple module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

Currently this test does nothing.

=back

=head1 SUPER CLASSES

LWP::Simple(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV more pdmt stuff
	0.01 MV md5 issues

=head1 SEE ALSO

Error(3), LWP::Simple(3), Meta::Projects::Webcache::Content(3), strict(3)

=head1 TODO

Nothing.
