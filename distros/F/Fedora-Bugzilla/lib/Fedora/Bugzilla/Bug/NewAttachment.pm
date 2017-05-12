#############################################################################
#
# Define the parameters of a new attachment.
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/24/2009 11:13:14 AM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::Bugzilla::Bug::NewAttachment;

use Moose;

use MooseX::StrictConstructor;
use MooseX::Types::Path::Class ':all';

with 'Fedora::Bugzilla::Role::NewHash';

use MIME::Base64;
use Path::Class;

use namespace::clean -except => 'meta';

our $VERSION = '0.13';

my @d = (is => 'rw', required => 1);

# mandatory
has filename    => (@d, isa => File, coerce => 1, predicate => 'has_filename');
has description => (@d, isa => 'Str', predicate => 'has_description'         );

# optional
has filetype    => (is => 'rw', lazy_build => 1, isa => 'Str' );
has contenttype => (
    is => 'rw', 
    isa => 'Str', 
    predicate => 'has_contenttype', 
    builder => '_build_contenttype',
);
has ispatch     => (is => 'rw', lazy_build => 1, isa => 'Bool');
has isprivate   => (is => 'rw', lazy_build => 1, isa => 'Bool');
has comment     => (is => 'rw', lazy_build => 1, isa => 'Str' );

sub _build_filetype    { undef }
sub _build_contenttype { 'text/plain' }
sub _build_ispatch     { undef }
sub _build_isprivate   { undef }
sub _build_comment     { undef }

has data => (is => 'ro', lazy_build => 1);

sub _build_data {
    my $self = shift @_;

    return encode_base64(file($self->filename)->slurp);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Fedora::Bugzilla::Bug::NewAttachment - Define the paramaters needed to create an attachment

=head1 SYNOPSIS

	use <Module::Name>;
	# Brief but working code example(s) here showing the most common usage(s)

	# This section will be as far as many users bother reading
	# so make it as educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e. =head2, =head3, etc.)


=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.
These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module provides.
Name the section accordingly.

In an object-oriented module, this section should begin with a sentence of the
form "An object of this class represents...", to give the reader a high-level
context to help them understand the methods that are subsequently described.


=head1 SEE ALSO

L<Fedora::Bugzilla::Bug>, L<Fedora::Bugzilla::Attachment>.

=head1 BUGS AND LIMITATIONS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or (preferably) 
add the bug to the camelus ticket tracker at 
L<https://fedorahosted.org/camelus/newticket>.

Patches are welcome.

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the 

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut

