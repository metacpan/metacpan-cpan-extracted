package Devel::WxProf::Treemap::Squarified;
use 5.006;
use strict; use warnings;
use base qw(Devel::WxProf::Treemap);
use version; our $VERSION = qv(0.0.1);

sub _map {
    my $self = shift;
    my ( @p, @q, $tree, $depth);
    my $debug = undef;
    my @map_from = ();
    ( $tree, $depth, $p[0], $p[1], $q[0], $q[1]) = @_;
    $depth++;

    $self->{DEBUG} && print STDERR "Drawing space for $tree->{name}:\n\t@p, @q\n";

    # Draw our rectangle
    $self->{ OUTPUT }->rect( $p[0], $p[1], $q[0], $q[1], $tree->{colour} );

    # Non-empty Set, Descend
    if( $tree->{children} ) {
        my ( $pt, $qt ) = $self->_shrink( \@p, \@q, $self->{PADDING} );
        my @p = @{$pt}; my @q = @{$qt};

        $self->{DEBUG} && print STDERR "\tI have " . scalar( @{$tree->{children}} ) . " children... ";

        # Check number of children
        # If < 3, two slices on the longest side is optimal aspect ratio
        if( scalar(@{$tree->{children}}) < 3 ) {
            $self->{DEBUG} && print STDERR "SLICE.\n";

            my ( @r, @s, $o, $width );
            $o = ( abs($p[0]-$q[0]) > abs($p[1]-$q[1]) ? 0 : 1 );
            @r = @p;
            @s = @q;
            $width = abs( $s[$o] - $r[$o] );
            foreach my $child( @{$tree->{children}} ) {
                $s[$o] = $r[$o] + $width *
                ( $child->{size} / $tree->{size} ) if( $tree->{size} > 0 );
                {
                    my ( $st, $rt ) = $self->_shrink( \@s, \@r, $self->{SPACING} );
                    my @s = @{$st}; my @r = @{$rt};
                    push @map_from, $self->_map( $child, $depth, $r[0], $r[1], $s[0], $s[1] );
                }
                $r[$o] = $s[$o];
            }
        }
        # Otherwise, find optimal aspect ratio
        else {
            $self->{DEBUG} && print STDERR "SQUARIFY.\n";

            # Sort children by size, descending
            my @indices = 0..( scalar( @{$tree->{children}} ) - 1 );
            my @sorted_children = sort {
                $tree->{children}->[$b]->{size} <=> $tree->{children}->[$a]->{size} }
            @indices;

            # Fetch each entry and compute the aspect ratio when their areas are
            # combined.
            #
            # height (h), and area (a) are our "fixed" values, and width (w) will
            # change based on the current 'a'.
            #
            # So:
            #  a = h*w
            #  w = a/h
            #
            # And:
            #  aspect = w/h
            #
            # Therefore:
            #  aspect = (a/h)/h
            #         = a / h**2
            #

            my ( $area, $parent_area, $parent_aspect, $usable_width, $usable_height, @j, @k, $o );
            $area = 0;
            $parent_area = $tree->{size};
            @j = @p;
            @k = @q;
            $o = ( abs($j[0]-$k[0]) > abs($j[1]-$k[1]) ? 0 : 1 );
            $usable_width = 0;

            # Only run if these children consume space, and we indeed have children
            while( $parent_area > 0 && @sorted_children > 0 ) {
                # Remove area that was consumed by 'special children' (see below)
                $parent_area -= $area;

                # Reset consumed area
                $area = 0;

                # Determine new boundary
                $j[$o] = $j[$o] + $usable_width;

                # Exit loop we've run out of pixel drawing space (prevents division
                # by zero errors in aspect ratio calculations)
                last if ( $j[0] == $k[0] || $j[1] == $k[1] );

                # Determine new orientation based on new boundary
                $o = ( abs($j[0]-$k[0]) > abs($j[1]-$k[1]) ? 0 : 1 );

                # Determine new parent aspect ratio based on new boundary
                $parent_aspect = (
                    abs( $j[$o] - $k[$o] ) /
                    abs( $j[($o xor 1)] - $k[($o xor 1)] )
                );

                # Determine new scaled height based on new aspect and available area
                my $scaled_height = sqrt( $parent_area / $parent_aspect );

                # Reset special children to nothing
                my @special_children;

                # Reset apsect ratio
                my $aspect = 0;

                while( scalar( @sorted_children ) > 0 ) {
                    my $child = shift( @sorted_children );
                    push( @special_children, $child );
                    my $area_test = $area + $tree->{children}->[$child]->{size};

               # Find worst aspect ratio in this set of special children
               my $aspect_test = $self->_find_worst( $tree->{children}, \@special_children, $area_test, $scaled_height );

               # If this aspect ratio is better than the last, keep searching
               if( ! $aspect_test || $aspect_test > $aspect ) {

                  $self->{DEBUG} && print STDERR "\t\t$aspect_test is a BETTER aspect ratio than $aspect\n";

                  # getting warmer, keep searching
                  $area = $area_test;
                  $aspect = $aspect_test;
               }
               else {

                  $self->{DEBUG} && print STDERR "\t\t$aspect_test is a WORSE aspect ratio than $aspect\n";

                  # nope, last set was better, undo this scenario.
                  pop( @special_children );
                  unshift( @sorted_children, $child );
                  # last set was the optimum set for this space, so drop out of
                  # the loop and handle these special children
                  last;
               }
            }

            # Handle special children
            if( @special_children > 0 ) {

               $self->{DEBUG} && print STDERR "\t\t\tHandling Special Children: @special_children\n";

               my ( @r, @s );
               my $o_xor = ( $o xor 1 );
               # Amount of width these children are allowed to consume from parent space
               $usable_width = ($k[$o]-$j[$o]) * ( $area / $parent_area );
               # Amount of height these children are allowed to consume from
               # parent space (all in this case)
               $usable_height = $k[$o_xor] - $j[$o_xor];

               @r = @j;
               @s = @k;
               $s[$o] = $r[$o] + $usable_width;

               $self->{DEBUG} && print STDERR "\t\t\tUsable Space for Special Children: $usable_width x $usable_height\n";

               # Each child gets a slice of the available height
               foreach my $child( @special_children ) {
                  $s[$o_xor] = $r[$o_xor] + $usable_height *
                     ( $tree->{children}->[$child]->{size} / $area )
                        if( $area > 0 );
                  {
                     my ( $st, $rt ) = $self->_shrink( \@s, \@r, $self->{SPACING} );
                     my @s = @{$st}; my @r = @{$rt};
                     push @map_from, $self->_map( $tree->{children}->[$child], $depth,
                              $r[0], $r[1], $s[0], $s[1]
                            );
                  }
                  $r[$o_xor] = $s[$o_xor];
               }
            }
            else {
               $self->{DEBUG} && print STDERR "No special children... awww\n";
            }
            # Continue processing remaining children at top of loop
         }
      }
   }
   # Draw label
   $self->{ OUTPUT }->text( $p[0], $p[1], $q[0], $q[1], $tree->{name}, ($tree->{children}?1:undef) );
   $depth--;
   push @map_from, [ $p[0], $p[1], $q[0], $q[1], $tree->{name} ];
   return @map_from;
}

# Expects the 'height' of the area we're filling
# No side-effects.
sub _find_worst {
   my $self = shift;
   my ( $tree, $set, $area, $height ) = @_;

   # Find width
   my $width = $area / $height;
   my $width_squared = $width ** 2;

   # Find worst aspect ratio
   my $worst = undef;
   foreach my $item( @{$set} ) {
      # for our purposes, aspect = w/h, where w>h, but we'll take the inverse
      # if it exeeds 1
      #
      # aspect = w/h; area = w*h, h = area/w
      # aspect = w/(area/w)
      #        = w^2/area

      # An item with a size/area of 0 is the worst possible thing. It's aspect
      # ratio is infinite, which is ... the worst you could wish for ;)
      return 0 if $tree->[$item]->{size} == 0;

      my $aspect = $width_squared / $tree->[$item]->{size};

      # if an aspect ratio is > 1, we take the inverse
      $aspect = 1 / $aspect if ( $aspect > 1 );

      if ( $worst ) {
         $worst = $aspect if ( $aspect < $worst );
      }
      else {
         $worst = $aspect;
      }
   }
   return $worst;
}

1;
__END__

=head1 NAME

Devel::WxProf::Treemap::Squarified - make a squarified treemap for wxprofile

=head1 DESCRIPTION

This is a modified version of L<Treemap::Squarified>. The main difference
is that labels are valigned on top of each square, and there's space reserved
for them.

=head1 SEE ALSO

L<Treemap>

=head1 AUTHORS

Martin Kutter E<lt>martin.kutter fen-net.deE<gt>

Based on Treemap::Squarified by

Simon P. Ditner <simon@uc.org>, and Eric Maki <eric@uc.org>

=head1 CREDITS

Original Treemap Concept: Ben Shneiderman <ben@cs.umd.edu>,
http://www.cs.umd.edu/hcil/treemap-history/index.shtml

Squarified Treemap Concept: Visualization Group of the Technische Universiteit
Eindhoven

=cut
