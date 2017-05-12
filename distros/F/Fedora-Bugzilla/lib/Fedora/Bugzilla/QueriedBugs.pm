#############################################################################
#
# A collection of bugs resulting from a query.
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/05/2009 09:23:20 AM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::Bugzilla::QueriedBugs;

use Moose;

use MooseX::StrictConstructor;

use namespace::clean -except => 'meta';

#use overload '""' => sub { shift->as_string }, fallback => 1;

extends 'Fedora::Bugzilla::Bugs';

our $VERSION = '0.13';

has sql => 
    (is => 'ro', isa => 'Str',      predicate => 'has_sql', required => 1);
has raw => 
    (is => 'ro', isa => 'ArrayRef', predicate => 'has_raw', required => 1);

has display_columns => (
    is        => 'ro', 
    isa       => 'ArrayRef[Str]', 
    required  => 1,
    predicate => 'has_display_columns',
);

has '+ids' => (lazy => 1, builder => '_build_ids');

sub _build_ids { [ map { $_->{bug_id} } @{ shift->raw } ] }

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Fedora::Bugzilla::QueriedBugs - A set of bugs resulting from a query/search

=head1 SYNOPSIS

    # from known #'s/aliases
    $bugs = $bz->bugs(123456, 789012, ...);

    # from a query
    $bugs = $bz->query(...);

    # ...

    print $bugs->count . " bugs found: $bugs";

=head1 DESCRIPTION

This class represents a collection of bugs, either returned from a query or
pulled via get_bugs().


=head1 SUBROUTINES/METHODS

=head2 new()

You'll never need to call this yourself, most likely. L<Fedora::Bugzilla>
tends to handle the messy bits for you.

=head2 raw()

The raw array ref of hashes returned.

=head2 sql()

The SQL Bugzilla executed to run this query.

=head2 as_string()

Stringifies.  The "" operator is also overloaded, so you can just use the
reference in a string context.

=head1 ACCESSORS

All accessors are r/o, and are pretty self-explanitory.

=over 4

=item B<bz>

A reference to the parent Fedora::Bugzilla instance.

=item B<num_bugs>

=item B<first_bug>

=item B<last_bug>

=item B<map_over_bugs>

=item B<get_bug>

=back

=head1 SEE ALSO

L<Fedora::Bugzilla>

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



