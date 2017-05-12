#############################################################################
#
# A collection of bugs
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

package Fedora::Bugzilla::Bugs;

use Moose;

use MooseX::AttributeHelpers;
use MooseX::StrictConstructor;

use URI::Fetch;
use XML::Twig;

use Fedora::Bugzilla::Bug;

use namespace::clean -except => 'meta';

use overload '""' => sub { shift->as_string }, fallback => 1;

our $VERSION = '0.13';

has bz => (is => 'ro', isa => 'Fedora::Bugzilla', required => 1);

has bugs => (
    metaclass => 'Collection::List',

    is         => 'ro',
    isa        => 'ArrayRef[Fedora::Bugzilla::Bug]',
    auto_deref => 1,
    #required   => 1,
    lazy       => 1,
    builder    => '_build_bugs',

    provides => {
        'count' => 'num_bugs',
        'first' => 'first_bug',
        'last'  => 'last_bug',
        'map'   => 'map_over_bugs',
        'get'   => 'get_bug',
        'join'  => '_join',
        # ...
    },
);

has ids => (
    metaclass => 'Collection::List',

    is => 'ro', 
    isa => 'ArrayRef[Int|Str]', 
    required => 1,
    auto_deref => 1,

    provides => {
        'count' => 'num_ids',
    #    'join'  => 'join_ids',
    }
);

has aggressive => (is => 'rw', isa => 'Bool', lazy_build => 1); 

sub as_string { shift->_join(', ') }

sub _build_aggressive { shift->bz->aggressive_fetch }

sub _build_bugs {
    my $self = shift @_;
    
    my $bz    = $self->bz;
    my $class = $bz->default_bug_class;

    # do the actual XMLRPC call
    my $ret_hash = $bz->rpc->simple_request(
        'Bug.get_bugs',
        { ids => [ $self->ids ] }
    );

    my @bugs_hash = @{ $ret_hash->{bugs} };
    my @data;

    # FIXME we can probably separate this out a little better...
    if ($self->aggressive) {
    
        # aggressively pre-fetch XML.
        my $uri = 
            'https://bugzilla.redhat.com/show_bug.cgi?ctype=xml&id=' .
            join(q{,}, $self->ids)
        ;
   
        my $res = URI::Fetch->fetch($uri, UserAgent => $self->bz->ua);

        die 'Cannot fetch XML?! ' . URI::Fetch->errstr
            unless $res;
    
        my $handle_bug = sub { 
            my $b_hash   = shift @bugs_hash;

            # generate a new twig for each bug
            my $new_twig = XML::Twig->new->parse('<bugzilla/>');
            $_->cut;
            $_->paste(first_child => $new_twig->root);

            push @data, [ 
                bz   => $bz,
                data => $b_hash,
                id   => $b_hash->{id},
                twig => $new_twig,
                xml  => $new_twig->sprint,
            ];
        };

        XML::Twig
            ->new(twig_handlers => { bug => $handle_bug })
            ->parse($res->content)
            ;

    }
    else {

        # just the data, thanks
        @data = map { [ bz => $bz, data => $_, id => $_->{id} ] } @bugs_hash;
    }

    my @bugs = map { $class->new(@$_) } @data;
    
    return \@bugs;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Fedora::Bugzilla::Bugs - A set of bugs

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



