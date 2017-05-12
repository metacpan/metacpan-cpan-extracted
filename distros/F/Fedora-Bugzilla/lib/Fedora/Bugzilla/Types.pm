#############################################################################
#
# Keep our Bugzilla types/subtypes in one place :-)
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/04/2009 05:29:50 AM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::Bugzilla::Types;

use strict;
use warnings;

use MooseX::Types::Moose     qw{ Str Object ArrayRef HashRef };
use MooseX::Types::DateTimeX 'DateTime';

use DateTime::Format::Pg;
use Email::Address;

use namespace::clean;

use MooseX::Types 
    -declare => [ 'Str20', 'BugzillaDateTime', 'EmailAddress' ];

our $VERSION = '0.13';

subtype Str20,
    as Str,
    where { length $_ <= 20 },
    ;

subtype BugzillaDateTime,
    as DateTime,
    where { $_->formatter->isa('DateTime::Format::Pg') },
    ;

coerce BugzillaDateTime,
    from DateTime,
    via { $_->set_formatter(DateTime::Format::Pg->new()); $_ },
    ;

#coerce BugzillaDateTime
#    => from Str
#    => via { 
#        my $dt = DateTime::Format::Pg->parse_datetime($_);
#        $dt->set_formatter(DateTime::Format::Pg->new());
#        return $dt;
#        }
#    ;

class_type 'Email::Address';

subtype EmailAddress,
    as 'Email::Address'
    ;

for my $type (EmailAddress, 'Email::Address') {
    
    coerce $type,
        from Str,
        via { my @a = Email::Address->parse($_); pop @a },
        from ArrayRef,
        via { Email::Address->new(@$_) },
        from HashRef,
        via { Email::Address->new(%$_) },
        ;
}

1;

__END__

=head1 NAME

Fedora::Bugzilla::Types - Moose types and coercions for Fedora::Bugzilla

=head1 SYNOPSIS

    use Fedora::Bugzilla::Types ':all';

    # ... can now use our types in attribute definitions

=head1 DESCRIPTION

This is simply a collection of Moose types and related coercions for
L<Fedora::Bugzilla>.


=head1 TYPES 

=over 4

=item B<Str20>

A string type with a length at most of 20 characters.

=item  B<BugzillaDateTime>

Simply a L<DateTime> object with a L<DateTime::Format::Pg> as its
formatter.  (Note this may be specific to the database one's Bugzilla instance
is running on.)

Will coerce from DateTime.

=item B<EmailAddress>

Simply an L<Email::Address>.

Will coerce from a Str.

=back

=head1 SEE ALSO

L<Fedora::Bugzilla>, L<MooseX::Types>, L<Moose::Util::TypeConstraints>.

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

