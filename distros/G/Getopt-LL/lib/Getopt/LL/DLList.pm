# $Id: DLList.pm,v 1.9 2007/07/13 00:00:14 ask Exp $
# $Source: /opt/CVS/Getopt-LL/lib/Getopt/LL/DLList.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.9 $
# $Date: 2007/07/13 00:00:14 $
package Getopt::LL::DLList;
use strict;
use warnings;
use Carp qw(croak);
use Getopt::LL::DLList::Node;
use Scalar::Util qw();
#use Class::InsideOut::Policy::Modwheel qw( :std );
use version; our $VERSION = qv('1.0.0');
use 5.006_001;
{

    use Class::Dot qw( property isa_Object );

    property head => isa_Object();

    sub new {
        my ($class, $array_ref) = @_;

        if ($array_ref && !_ARRAYLIKE($array_ref)) {
            croak 'Argument to Getopt::LL::DLList must be array reference.';
        }

        my $self = bless { }, $class;

        $self->_init($array_ref);

        return $self;
    }

    sub _init {
        my ($self, $array_ref) = @_;
        return if not ref $array_ref;
        return if not scalar @{$array_ref};

        my $prev_node   = Getopt::LL::DLList::Node->new();
        my $list_head   = $prev_node;

        for my $array_element (@{$array_ref}) {

            $prev_node->set_data($array_element);

            my $next_node = Getopt::LL::DLList::Node->new();
            $prev_node->set_next($next_node);
            $next_node->set_prev($prev_node);
            $prev_node = $next_node;

        }

        # last node is always empty, so delete it.
        $prev_node->prev->set_next(undef);
        $prev_node->free();

        $self->set_head($list_head);

        return;
    }

    sub traverse {
        my ($self, $handler_object, $handler_method) = @_;
        my $dll    = $self->head;

        my $current_node    = $dll;
        my $nodes_so_far    = 0;
        while ($current_node) {
            $handler_object->$handler_method($current_node->data,
                $current_node,$nodes_so_far++);

            $current_node = $current_node->next;
        }

        return $nodes_so_far;
    }

    sub delete_node {
        my ($self, $node) = @_;
        return if not $node;

        my $node_data = $node->data;

        my $prev_node = $node->prev;
        my $next_node = $node->next;

        if ($prev_node) {
            $prev_node->set_next($next_node);
        }
        else {
            $self->set_head($next_node);
        }

        if ($next_node) {
            $next_node->set_prev($prev_node);
        }

        $node->free;

        return $node_data;
    }

    sub DEMOLISH {
        my ($self) = @_;
        my $head = $self->head;
        if ($head) {
            $head->free();
        }
        undef $self->{__x__head__x__}; # << Class::Dot 1.0 weirdness.
        undef $self->{head};
        return;
    }

    # Taken from Params::Util
    sub _ARRAYLIKE { ## no critic

        (defined $_[0] and ref $_[0] and (
        (Scalar::Util::reftype($_[0]) eq 'ARRAY')
        or
        overload::Method($_[0], '@{}')
        )) ? $_[0] : undef;
    }
}
1;

__END__

=pod

=for stopwords Initialize expandtab shiftround

=begin wikidoc

= NAME

Getopt::LL::DLList - A doubly linked list.

= VERSION

This document describes Getopt::LL::DLList version %%VERSION%%

= SYNOPSIS


= DESCRIPTION

    use Getopt:LL::DLList qw(getoptions);

    my @array = qw(The quick brown fox jumps over the lazy dog);

    # Create a doubly linked list out of the array.
    my $dllist = Getopt::LL::DLList->new(\@array);

    my $printer = DLList::Traverser::Print->new( );
   
    # Run the print_node method in the DLList::Traverser::Print object
    # for every node in our linked list. 
    $dllist->traverse($printer, 'print_node');

    package DLList::Traverser::Print;
    sub new {
        return bless { }, shift;
    };
    sub print_node {
        my ($self, $node_data, $node, $nodes_so_far) = @_;
        print "Node #$nodes_so_far: $node_data\n";
    }

            

= SUBROUTINES/METHODS


== CONSTRUCTOR


=== {new(\@from_array)

Create a doubly linked list out of the given array.

== ATTRIBUTES

=== {head}

=== {set_head}

The head (also called top node or root node) of the doubly linked list.

== INSTANCE METHODS

=== {traverse($handler_object, $handler_method)}

Traverse the doubly linked list, and for each element in the list
run the $handler_method with the $handler_object.

=== {delete_node($node)}

Delete a node from the list.
Returns the value of the node deleted.

== PRIVATE INSTANCE METHODS

=== {_init()}

Initialize the doubly linked list.

=== {DEMOLISH()}

Run at destruction.


= DIAGNOSTICS


= CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables.

= DEPENDENCIES

* [Class::Dot]

* [version]

= INCOMPATIBILITIES

None known.

= BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-getopt-ll@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

= SEE ALSO

== Getopt::LL::Node

== Getopt::LL

= AUTHOR

Ask Solem, C<< ask@0x61736b.net >>.


= LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

= DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=end wikidoc


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
