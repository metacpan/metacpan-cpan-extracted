package Language::Tea::Traverse;

use strict;
use warnings;
use UNIVERSAL qw(isa can);
use Scalar::Util qw(blessed);

sub visit_prefix {
    my ( $node, $visitor, $parent );
    my $path;
    if ( ref( $_[0] ) eq 'PATH' ) {
        $node = $_[0];
        $path = $node->[0];
    }
    else {
        ( $node, $visitor, $parent ) = ( shift, shift, shift );
    }

    if ( ref($node) eq 'ARRAY' ) {

        my $h = [];
        for my $key ( 0 .. $#$node ) {
            my $res = visit_prefix( $node->[$key], $visitor, $parent, @_ );
            if ($res) {
                push @$h, $res;
            }
            else {
                push @$h, $node->[$key];
            }
        }
        return $h;
    }
    elsif ( ref $node eq 'HASH' || blessed $node) {

        my $visited = $visitor->( $node, $parent, @_ );
        return $visited if defined $visited;

        my $h = {};
        for my $key ( sort keys %$node ) {
            my $res;
            if ( $key ne '__node_parent__' ) {
                $res =
                  visit_prefix( $node->{$key}, $visitor,
                    ref $node eq 'HASH' ? $parent : $node, @_ );
            }
            if ($res) {
                $h->{$key} = $res;
            }
            else {
                $h->{$key} = $node->{$key};
            }
        }
        bless $h, ref($node)
          unless ref($node) eq 'HASH';

        return $h;
    }
    else {
        return $node;
    }
}

sub visit_postfix {
    my ( $node, $visitor, $parent ) = ( shift, shift, shift );
    if ( ref($node) eq 'ARRAY' ) {
        my $h = [];
        for my $key ( 0 .. $#$node ) {
            my $res = visit_postfix( $node->[$key], $visitor, $parent, @_ );
            if ($res) {
                push @$h, $res;
            }
            else {
                push @$h, $node->[$key];
            }
        }
        return $h;
    }
    elsif ( ref $node eq 'HASH' || blessed $node) {

        #print ref($node),"\n";
        my $h = {};
        for my $key ( sort keys %$node ) {
            my $res;
            if ( $key ne '__node_parent__' ) {
                $res =
                  visit_postfix( $node->{$key}, $visitor,
                    ref $node eq 'HASH' ? $parent : $node, @_ );
            }
            if ($res) {
                $h->{$key} = $res;
            }
            else {
                $h->{$key} = $node->{$key};
            }
        }
        bless $h, ref($node)
          unless ref($node) eq 'HASH';

        my $res = $visitor->( $h, $parent, @_ );
        return $res if $res;

        return $h;
    }
    else {
        return $node;
    }
}

1;

__END__

=head1 NAME

Language::Tea::Traverse - Iterates into the Tea Op Tree

=head1 SYNOPSIS

  use Language::Tree::Traverse;
  my $node = traverse_postfix($root, sub { }, []);
  my $node = traverse_prefix($root, sub { }, []);

=head1 DESCRIPTION

This module iterates through the tree in two different ways

=over

=item traverse_postfix($node, $visitor = sub { my ($node, \@children, @_) = @_ });

Bottom-up traversal. The visitor will receive both the current node
and the result of the processing for each sub-node. As any other
arguments passed to traverse_postfix.

=item traverse_prefix($node, $visitor = sub { my ($node, \@parents, @_) = @_ });

Top-Down traversal. The visitor will receive both the current node and
the result of the processing for each upper level in the three (from
the closest to the farest). It will also receive any other argument
passed to traverse_prefix.

=cut

