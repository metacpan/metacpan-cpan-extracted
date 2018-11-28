# Copyright (c) 2018  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package Game::Collisions;
$Game::Collisions::VERSION = '0.3';
use v5.14;
use warnings;
use List::Util ();

use Game::Collisions::AABB;

# ABSTRACT: Fast, pure Perl collision 2D detection


sub new
{
    my ($class) = @_;
    my $self = {
        root_aabb => undef,
        all_aabbs => {},
    };
    bless $self => $class;


    return $self;
}


sub make_aabb
{
    my ($self, $args) = @_;
    my $aabb = Game::Collisions::AABB->new( $args );
    $self->_add_aabb( $aabb );
    return $aabb;
}

sub get_collisions
{
    my ($self) = @_;
    my @aabbs_to_check = values %{ $self->{all_aabbs} };
    my @collisions;

    foreach my $aabb (@aabbs_to_check) {
        push @collisions => $self->get_collisions_for_aabb( $aabb );
    }

    return @collisions;
}

sub get_collisions_for_aabb
{
    my ($self, $aabb) = @_;
    return () if ! defined $self->{root_aabb};
    my @collisions;

    my @nodes_to_check = ($self->{root_aabb});
    while( @nodes_to_check ) {
        my $check_node = shift @nodes_to_check;

        if( $check_node->is_branch_node ) {
            my $left_node = $check_node->left_node;
            my $right_node = $check_node->right_node;

            if( defined $left_node && $left_node->does_collide( $aabb ) ) {
                push @nodes_to_check, $left_node;
            }
            if( defined $right_node && $right_node->does_collide( $aabb ) ) {
                push @nodes_to_check, $right_node;
            }
        }
        else {
            # We already know it collided, since it wouldn't be added 
            # to @nodes_to_check otherwise.
            push @collisions, [ $aabb, $check_node ];
        }
    }

    return @collisions;
}

sub get_collisions_for_aabb_bruteforce
{
    my ($self, $aabb) = @_;
    my @aabbs = values %{ $self->{all_aabbs} };

    my @collisions = grep { $_->does_collide( $aabb ) } @aabbs;
    return @collisions;
}

sub rebalance_tree
{
    my ($self) = @_;
    my @aabbs = values %{ $self->{all_aabbs} };
    $self->{all_aabbs} = {};

    my $new_root = $self->_new_meta_aabb({
        x => 0,
        y => 0,
        length => 1,
        height => 1,
    });
    $self->{root_aabb} = $new_root;
    $self->_add_aabb( $_ ) for @aabbs;

    return;
}

sub root
{
    my ($self) = @_;
    return $self->{root_aabb};
}


sub _add_aabb
{
    my ($self, $new_node) = @_;

    if(! defined $self->{root_aabb} ) {
        $self->{root_aabb} = $new_node;
    }
    else {
        my $new_root = $self->{root_aabb}->insert_new_aabb( $new_node );
        $self->{root_aabb} = $new_root if defined $new_root;
    }

    $self->{all_aabbs}{"$new_node"} = $new_node;
    return;
}

sub _new_meta_aabb
{
    my ($self, $args) = @_;
    my $aabb = Game::Collisions::AABB->new( $args );
    return $aabb;
}


1;
__END__


=head1 NAME

  Game::Collisions - Fast, pure Perl collision 2D detection

=head1 SYNOPSIS

    my $collide = Game::Collisions->new;

    my $box1 = $collide->make_aabb({
        x => 0,
        y => 0,
        length => 1,
        height => 1,
    });
    my $box2 = $collide->make_aabb({
        x => 2,
        y => 0,
        length => 1,
        height => 1,
    });

    if( $box1->does_collide( $box2 ) ) {
        say "Collides";
    }

    my @collisions = $collide->get_collisions;

=head1 DESCRIPTION

Checks for collisions between objects. Can check for a collision between 
two specific objects, or generate the collisions between all objects in the 
system.

=head2 What's an Axis-Aligned Bounding Box (AABB)?

A rectangle that's aligned with the x/y axis (in other words, not rotated). 
It's common to have the box surround (bound) the entire area of a more complex 
object. Since it's cheap to check for AABB collisions, it's useful to start 
there, and only then use more expensive algorthims to check more accurately.

=head2 Understanding the Tree

This module uses a binary tree to quickly search AABB collisions. Each branch 
of the tree must be big enough to contain all its children. When you move a 
leaf (any actual object you want to check will be a leaf), its parents must 
be resized to accommodate.

If many leaves get moved rather far, you'll want to rebalance the tree. This is 
expensive (which is why we normally resize rather than rebalance), so you 
wouldn't want to do it all the time.

If you would like more details, see:

L<https://www.azurefromthetrenches.com/introductory-guide-to-aabb-tree-collision-detection/>

=head2 Circular References

This module does use circular references to keep track of parent/child 
relationships. This would normally be a problem, but if you're using 
C<<Game::Collisions::AABB-E<gt>remove>> to take nodes out of the tree, then 
references are cleaned up, anyway.

=head1 METHODS

=head2 new

Constructor.

=head2 make_aabb

    my $box1 = $collide->make_aabb({
        x => 0,
        y => 0,
        length => 1,
        height => 1,
    });

Creates an AABB at the specified x/y coords, in the specified dimentions, 
and adds it to the tree.

=head2 get_collisions

Returns a list of all collisions in the system's current state. Each element 
is an array ref containing the two objects that intersect.

=head2 get_collisions_for_aabb

  get_collisions_for_aabb( $aabb )

Returns a list of all collisions against the specific AABB.  Each element 
is an array ref containing the two objects that intersect.

=head2 get_collisions_for_aabb_bruteforce

  get_colisions_for_aabb_bruteforce( $aabb );

Returns a list of all collisions against the specific AABB. Each element 
is an AABB object that collides against the passed object.

This is mainly for benchmarking purposes. It's I<possible> that this method is 
faster than the tree algorithm if the list of AABBs is small. Probably not, but
you can try.

=head2 rebalance_tree

Build a new tree out of the current leaves. You'll want to do this if the 
objects are moving around a lot.

=head1 SEE ALSO

=over 4

=item * L<Game::Collisions::AABB>

=item * L<https://www.azurefromthetrenches.com/introductory-guide-to-aabb-tree-collision-detection/> for a description of the algorithm

=back

=head1 LICENSE

Copyright (c) 2018  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in the 
      documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

=cut
