package Devel::WxProf::Treemap;
use 5.006;
use strict; use warnings;
use version; our $VERSION = qv(0.0.1);

sub new {
   my $class = shift;
   my $self = {
      RECT => undef,
      TEXT => undef,
      CACHE => 1,
      INPUT => undef,
      OUTPUT => undef,
      PADDING => 5,
      SPACING => 5,
      @_,               # Override previous attributes
   };

   die "No 'INPUT' object was specified in call to " . $class . "::new, cannot proceed.\nSee: perldoc Treemap\nError occured" if ( ! $self->{INPUT} );
   die "No 'OUTPUT' object was specified in call to " . $class . "::new, cannot proceed.\nSee: perldoc Treemap\nError occured" if ( ! $self->{OUTPUT} );

   bless $self, $class;
   return $self;
}

sub map {
    my $self = shift;

    # Get dimensions from OUTPUT object
    my $width = $self->{OUTPUT}->width;
    my $height=  $self->{OUTPUT}->height;
    my $data = $self->{INPUT}->treedata;

    # Call _map function with tree data from INPUT object.
    return $self->_map($data , 0, 0, 0, $width-1, $height-1 );
}

=for apidoc

 _map( $self, $treedata, $left, $top, $right, $bottom )

=cut

sub _map {
   my $self = shift;
   my ( @left_top, @right_bottom, $tree, $o );
   ( $tree, $left_top[0], $left_top[1], $right_bottom[0], $right_bottom[1], $o ) = @_;
   $o = $o || 0;  # Orientation of our slicing

   # Draw our rectangle
   #&{$self->{ RECT }}( $left_top[0], $left_top[1], $right_bottom[0], $right_bottom[1], $tree->{colour} );
   $self->{ OUTPUT }->rect( $left_top[0], $left_top[1], $right_bottom[0], $right_bottom[1], $tree->{colour} );

   # Shrink the space available to children
   my( $left_topt, $right_bottomt ) = $self->_shrink( \@left_top, \@right_bottom, $self->{PADDING} );
   my @r = @$left_topt;
   my @s = @$right_bottomt;

   # Non-empty Set, Descend
   if( $tree->{children} ) {
      my $width = abs($r[$o] - $s[$o]);
      my $size = $tree->{size};

      # Process each child
      foreach my $child( @{$tree->{children}} )
      {
         # Give this child a percentage of the parent's space, based on
         # parent's size (make sure we don't cause divide by zero errors)
         $s[$o] = $r[$o] + $width * ( $child->{size} / $size ) if ( $size > 0 );

         # Rotate the space by 90 degrees, by xor'ing the 'o'rientation
         {
            my( $rt, $st ) = $self->_shrink( \@r, \@s, $self->{SPACING} );
            my @r = @{$rt}; my @s = @{$st};
            $self->_map( $child, $r[0], $r[1], $s[0], $s[1], ($o xor 1) );
         }
         $r[$o] = $s[$o];
      }
   }
   # Draw label
   #&{ $self->{ TEXT } }( $tree->{name} );
   $self->{ OUTPUT }->text( $left_top[0], $left_top[1], $right_bottom[0], $right_bottom[1], $tree->{name}, ($tree->{children}?1:undef) );
}

sub _shrink {
    my $self = shift;
    my ( $p, $q, $shr ) = @_;
    my ( $w, $h, $r, $s );

    my %shrink = ref $shr eq 'HASH' ? %{ $shr } : (
           top => $shr,
           bottom => $shr,
           left => $shr,
           right => $shr,
   );
    $shrink{ min_height } ||= 0;
    $shrink{ min_width } ||= 0;

   $w = $q->[0] - $p->[0];
   $h = $q->[1] - $p->[1];

   if ( abs( $w ) < $shrink{ left } + $shrink{ right } + $shrink{ min_width }) {
        return ( [0,0], [0,0] );
   }
    if ($w < 0) {
        $shrink{ left } = - $shrink{ left };
        $shrink{ right } = - $shrink{ right };
    }

   if ( abs( $h ) < $shrink{top} + $shrink{bottom} + $shrink{ min_height }) {
        return ( [0,0], [0,0] );
   }
   if ($h < 0) {
        $shrink{ top } = - $shrink{ top };
        $shrink{ bottom } = - $shrink{ bottom };
    }

   # Perfomr shrink
   $r->[0] = $p->[0] + $shrink{'left'};
   $r->[1] = $p->[1] + $shrink{'top'};

   $s->[0] = $q->[0] - $shrink{'right'};
   $s->[1] = $q->[1] - $shrink{'bottom'};
   return ( $r, $s );
}

1;

__END__


=head1 NAME

Devel::WxProf::Treemap - Calculate Treemap for wxprofile

=head1 DESCRIPTION

This is a modified/rewritten version of L<Treemap|Treemap>.
The main difference is, that the SPACING and PADDING parameters can take
hash refs in the following form:

 {
     top    => 5,
     bottom => 5,
     left   => 5,
     right  => 5
 }

This allows for creating different spacings/paddings for each side, thus
eases top-aligned labeling.

Note that treemaps with spacing and padding may be misleading - even more
if spacing/padding is not (visually) equal on all borders.

=head1 AUTHORS

Martin Kutter E<lt>martin.kutter fen-net.deE<gt>

This is a modified/rewritten version of L<Treemap|Treemap> by

Simon Ditner <simon@uc.org>, and Eric Maki <eric@uc.org>

=head1 CREDITS

Original Treemap Concept: Ben Shneiderman <ben@cs.umd.edu>,
http://www.cs.umd.edu/hcil/treemap-history/index.shtml

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
