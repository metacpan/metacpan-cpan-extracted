# $Id: Node.pm,v 1.9 2007/07/13 00:00:15 ask Exp $
# $Source: /opt/CVS/Getopt-LL/lib/Getopt/LL/DLList/Node.pm,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.9 $
# $Date: 2007/07/13 00:00:15 $
package Getopt::LL::DLList::Node;
use strict;
use warnings;
use Carp;
use Scalar::Util qw( weaken );
use version; our $VERSION = qv('1.0.0');
use 5.006_001;
{

    use vars qw($ALLOCATED_TOTAL);
    $ALLOCATED_TOTAL = 0;

    use Class::Dot qw( property isa_Object isa_Data );
    property    prev => isa_Object();
    property    next => isa_Object();
    property    data => isa_Data;

    sub new {
        my ($class, $opt_data) = @_;

        $ALLOCATED_TOTAL++;

        my $self = bless {}, $class;

        if ($opt_data) {
            $self->set_data($opt_data);
        }

        return $self;
    }

    sub free {
        my ($self) = @_;
        my $next = $self->next;
        my $prev = $self->prev;
        weaken $next;
        weaken $prev;
        undef $self->{next};
        undef $self->{prev};
        undef $self->{data};

        # Class::Dot 1.0 weirdness.
        undef $self->{__x__next__x__};
        undef $self->{__x__prev__x__};
        undef $self->{__x__data__x__};
        return;
    }

    sub DEMOLISH {
        $ALLOCATED_TOTAL--;
        return;
    }

    sub END {
        my ($self) = @_;

        #if ($ALLOCATED_TOTAL) {
        #    carp "DLList::Node Warning: There were $ALLOCATED_TOTAL nodes "
        #        .'not properly freed during destruction.';
        #}

    }

}
1;

__END__

=for stopwords expandtab shiftround

=begin wikidoc

= NAME

Getopt::LL::DLList::Node - Node in a doubly linked list.

= VERSION

This document describes Getopt::LL::DLList::Node version %%VERSION%%

= SYNOPSIS


= DESCRIPTION

    use Getopt:LL::DLList::Node;

    my $head_node   = Getopt::LL::DLList::Node->new('top');
    my $middle_node = Getopt::LL::DLList::Node->new('middle');
    my $bottom_node = Getopt::LL::DLList::Node->new('bottom');

    $head_node->set_next(   $middle_node );
    $middle_node->set_prev( $head_node   );
    $middle_node->set_next( $bottom_node );
    $bottom_node->set_prev( $middle_node );

    my $current_node = $head_node;
    while ($current_node) {
        print $current_node->data, q{, }; 

        $current_node = $current_node->next;
    }

    # prints: top, middle, bottom


    # got to free the nodes, as they use circular references.
    for my $node ($head_node, $middle_node, $bottom_node) {
        $node->free;
    }

            

= SUBROUTINES/METHODS


== CONSTRUCTOR


=== {new($data)}

Create a new node.

== ATTRIBUTES

=== {next}

=== {set_next}

The next node in the linked list.

=== {prev}

=== {set_prev}

The previous node in the linked list.


=== {data}

=== {set_data}

The data for this node.

== INSTANCE METHODS

=== {free()}

Free the memory for this node.
As linked lists uses circular references this is necessary.

=== {DEMOLISH}

Run when the node goes out of scope.
Just keeps track of how many nodes have been allocated/deallocated.

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

== Getopt::LL::DLList

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
