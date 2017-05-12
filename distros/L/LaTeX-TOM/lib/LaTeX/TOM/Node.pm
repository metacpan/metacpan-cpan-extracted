###############################################################################
#
# LaTeX::TOM::Node
#
# This package defines an object for nodes in the TOM tree, and methods to go
# with them.
#
###############################################################################

package LaTeX::TOM::Node;

use strict;
use warnings;
use constant true  => 1;
use constant false => 0;

our $VERSION = '0.03';

# Make a new Node: turn input hash into object.
#
sub new {
    my $class = shift;
    my ($node) = @_;

    return bless $node || {};
}

# "copy constructor"
#
sub copy {
    my $node = shift;

    return bless $node;
}

# Split a text node into two text nodes, with the first ending before point a,
# and the second starting after point b. actually returns NEW nodes, does not
# alter the input node.
#
# Note: a and b are relative to the contents of the node, not the original
# document.
#
# Note2: a and b are not jointly constrained. You can split after location x
# without losing any characters by setting a = x + 1 and b = x.
#
sub split {
    my $node = shift;
    my ($a, $b) = @_;

    return (undef) x 2 unless $node->{type} eq 'TEXT';

    my $left_text  = substr $node->{content}, 0, $a;
    my $right_text = substr $node->{content}, $b + 1, length($node->{content}) - $b;

    my $left_node = LaTeX::TOM::Node->new({
         type    => 'TEXT',
         start   => $node->{start},
         end     => $node->{start} + $a - 1,
         content => $left_text,
    });

    my $right_node = LaTeX::TOM::Node->new({
         type    => 'TEXT',
         start   => $node->{start} + $b + 1,
         end     => $node->{start} + length $node->{content},
         content => $right_text,
    });

    return ($left_node, $right_node);
}

#
# accessor methods
#

sub getNodeType {
    my $node = shift;

    return $node->{type};
}

sub getNodeText {
    my $node = shift;

    return $node->{content};
}

sub setNodeText {
    my $node = shift;
    my ($text) = @_;

    $node->{content} = $text;
}

sub getNodeStartingPosition {
    my $node = shift;

    return $node->{start};
}

sub getNodeEndingPosition {
    my $node = shift;

    return $node->{end};
}

sub getNodeMathFlag {
    my $node = shift;

    return $node->{math} ? true : false;
}

sub getNodePlainTextFlag {
    my $node = shift;

    return $node->{plaintext} ? true : false;
}

sub getNodeOuterStartingPosition {
    my $node = shift;

    return (defined $node->{ostart} ? $node->{ostart} : $node->{start});
}

sub getNodeOuterEndingPosition {
    my $node = shift;

    return (defined $node->{oend} ? $node->{oend} : $node->{end});
}

sub getEnvironmentClass {
    my $node = shift;

    return $node->{class};
}

sub getCommandName {
    my $node = shift;

    return $node->{command};
}

#
# linked-list accessors
#

sub getChildTree {
    my $node = shift;

    return $node->{children};
}

sub getFirstChild {
    my $node = shift;

    if ($node->{children}) {
        return $node->{children}->{nodes}[0];
    }

    return undef;
}

sub getLastChild {
    my $node = shift;

    if ($node->{children}) {
        return $node->{children}->{nodes}[-1];
    }

    return undef;
}

sub getPreviousSibling {
    my $node = shift;

    return $node->{prev};
}

sub getNextSibling {
    my $node = shift;

    return $node->{'next'};
}

sub getParent {
    my $node = shift;

    return $node->{parent};
}

# This is an interesting function, and kind of a hack because of the way the
# parser makes the current tree. Basically it will give you the next sibling
# that is a GROUP node, until it either hits the end of the tree level, a TEXT
# node which doesn't match /^\s*$/, or a COMMAND node.
#
# This is useful for finding all GROUPed parameters after a COMMAND node. You
# can just have a while loop that calls this method until it gets 'undef'.
#
# Note: this may be bad, but TEXT Nodes matching /^\s*\[[0-9]+\]$/ (optional
# parameter groups) are treated as if they were whitespace.
#
sub getNextGroupNode {
    my $node = shift;

    my $next = $node;
    while ($next = $next->{'next'}) {

        # found a GROUP node.
        if ($next->{type} eq 'GROUP') {
            return $next;
        }

        # see if we should skip a node
        elsif ($next->{type} eq 'COMMENT' ||
                ($next->{type} eq 'TEXT' &&
                ($next->{content} =~ /^\s*$/ ||
                 $next->{content} =~ /^\s*\[\s*[0-9]+\s*\]\s*$/
                ))) {

            next;
        }

        else {
            return undef;
        }
    }

    return undef;
}

1;
