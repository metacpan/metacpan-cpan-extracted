package Math::CPWLF;

use warnings;
use strict;

use Carp;
use Want;
use List::Util;

use overload
   fallback => 1,
   '&{}'    => sub
      {
      my $self = $_[0];
      return _top_interp_closure( $self, $self->{_opts} )
      };
      
=head1 NAME

Math::CPWLF - interpolation using nested continuous piece-wise linear functions

=head1 VERSION

Version 0.15

=cut

our $VERSION = '0.15';

=head1 SYNOPSIS

C<Math::CPWLF> provides an interface for defining continuous piece-wise linear
functions by setting knots with x,y pairs.

   use Math::CPWLF;
    
   $func = Math::CPWLF->new;

   $func->knot( 0 => 0 );             ## set the knot at f(0) equal to 0
   $func->knot( 1 => 2 );             ## set the knot at f(1) equal to 2
    
   $y = $func->( 0.5 );               ## interpolate f(0.5) ($y == 1)
    
Functions can be used in multiple dimensions, by specifying a C<Math::CPWLF>
object as the y value of a knot.

   $nested_func = Math::CPWLF->new;

   $nested_func->knot( 0 => 0 );
   $nested_func->knot( 1 => 3 );
   
   $func->knot( 2 => $nested_func );
   
   $deep_y = $func->( 1.5 )( 0.5 );   ## $deep_y == 1.75
   
As a convenience, you can specify arbitrarily deep knots by passing more than
two values two the C<knot> method.

   $func->knot( 2, 2 => 4 );          ## same as $nested_func->( 2 => 4);

If any of the intermediate knots do not exist they will be autovivified as
C<Math::CPWLF> objects, much like perl hashes.

   $func->knot( 3, 2 => 4 );          ## autovivify top level f(3)

=head1 FUNCTIONS

=head2 new

Construct a new C<Math::CPWLF> function with no knots, and the default out of
bounds behavior.

   my $func = Math::CPWLF->new;
   
Optional parameters:

=over 4

=item * oob

The C<oob> parameter controls how a function behaves when a given x value is out
of bounds of the current minimum and maximum knots. If a function defines an
C<oob> method in its constructor, that method is also used for any nested
functions that were not explicitly constructed with their own C<oob> methods.

=over 4

=item * C<die> - Throw an exception (default).

=item * C<extrapolate> - Perform a linear extrapolation using the two nearest knots.

=item * C<level> - Return the y value of the nearest knot.

=item * C<undef> - Return undef.

=back

Construct an instance that returns C<undef> or empty list when the requested x
is out of bounds:

   my $func = Math::CPWLF->new( oob => 'undef' );

=back

=cut

sub new
  {
  my $self        = bless {}, shift();
  my %opts        = @_;
  $self->{_opts}  = \%opts;
  return $self;
  }
  
=head2 knot

This instance method adds a knot with the given x,y values.

   $func->knot( $x => $y );
  
Knots can be specified at arbitrary depth and intermediate knots will autovivify
as needed. There are two alternate syntaxes for setting deep knots. The first
involves passing 3 or more values to the C<knot()> call, where the last value
is the y value and the other values are the depth-ordered x values:

   $func->knot( $x1, $x2, $x3 => $y );
   
The other syntax is a bit more hash-like in that it separates the x values. Note
that it starts with invoking the C<knot()> method with no arguments.

   $func->knot->($x1)($x2)( $x3 => $y );

=cut

sub knot
  {
  my $self = shift @_;
  
  delete $self->{_x_vals_order};

  ## caller intends to use hash-like multi-dimensional syntax
  ## $f->knot->(1)(2)( 3 => 4 );
  if ( @_ == 0 )
     {
     return sub
        {
        $self->knot( @_ );
        };
     }
  ## caller is in the middle of using hash-like multi-dimensional syntax
  elsif ( @_ == 1 )
     {
     my $x = shift;

     if ( ! defined $self->{_data}{$x} ||
          ! ref $self->{_data}{$x} )
        {
        $self->{_data}{$x} = ( ref $self )->new;
        }

     return sub
        {
        $self->{_data}{$x}->knot( @_ );
        };
     }
  ## args are an x,y pair
  elsif ( @_ == 2 )
     {
     my ( $x, $y ) = @_;
     $x += 0;
     $self->{_data}{$x} = $y;
     }
  ## caller is using bulk multi-dimensional syntax
  ## $f->knot( 1, 2, 3 => 4 );
  elsif ( @_ > 2 )
     {
     my $x = shift;
     
     $x += 0;
     
     if ( ! defined $self->{_data}{$x} || ! ref $self->{_data}{$x} )
        {
        $self->{_data}{$x} = ( ref $self )->new;
        }
        
     $self->{_data}{$x}->knot(@_);
     
     }

  return $self;
  }

## - solves the first dimension lookup, or
## - returns first dimension closure as needed  
sub _top_interp_closure
   {
   my ( $func, $opts ) = @_;
   
   my $interp = sub
      {
      my ( $x_given ) = @_;

      $x_given += 0;

      my $node = $func->_make_node($x_given, $opts);
      
      return _nada() if ! defined $node;

      my @slice = ( $node );
      my @tree  = ( \@slice );

      return ref $node->{y_dn} || ref $node->{y_up}
           ? _nested_interp_closure( \@tree, $opts )
           : _reduce_tree( \@tree )
      };
   
   }

## - solves the 2+ dimension lookups, or
## - returns 2+ dimension closures as needed
sub _nested_interp_closure
   {
   my ( $tree, $opts ) = @_;
   
   my $interp = sub
      {
      my ($x_given) = @_;
      
      $x_given += 0;
      
      my @slice;
      my $make_closure;
      
      for my $node ( @{ $tree->[-1] } )
         {
            
         for my $y_pos ( 'y_dn', 'y_up' )
            {
            
            next if ! ref $node->{$y_pos};
            
            my $new_node = $node->{$y_pos}->_make_node($x_given, $opts);
            
            return _nada() if ! defined $new_node;
         
            $make_closure = ref $new_node->{y_dn} || ref $new_node->{y_up};
            
            $new_node->{into} = \$node->{$y_pos};
               
            push @slice, $new_node;

            }

         }
         
      push @{ $tree }, \@slice;
      
      return $make_closure ? _nested_interp_closure( $tree, $opts )
                           : _reduce_tree( $tree )
      
      };

   return $interp;   
   }

## converts the final tree of curried line segments and x values to the final
## y value
sub _reduce_tree
   {
   my ($tree) = @_;

   for my $slice ( reverse @{ $tree } )
      {
         
      for my $node ( @{ $slice } )
         {

         my @line = grep defined, @{ $node }{ qw/ x_dn x_up y_dn y_up / };
         
         my $y_given = _mx_plus_b( $node->{x_given}, @line );
         
         return $y_given if ! $node->{into};

         ${ $node->{into} } = $y_given;

         }

      }
      
   }

## used to handle 'undef' oob exceptions
##   - returns a reference to itself in CODEREF context
##   - else returns undef   
sub _nada
   {
   return want('CODE') ? \&_nada : ();
   }   
   
{

my $default_opts =
   {
   oob => 'die',
   };   

## - merges the options, priority from high to low is:
##    - object
##    - inherited
##    - defaults
sub _merge_opts
   {
   my ($self, $inherited_opts) = @_;
   
   my %opts;
   
   for my $opts ( $self->{_opts}, $inherited_opts, $default_opts )
      {
      for my $opt ( keys %{ $opts } )
         {
         next if defined $opts{$opt};
         $opts{$opt} = $opts->{$opt};
         }
      }
   
   return \%opts;
   }
   
}

## - locate the neighboring x and y pairs to the given x values
## - handles oob exceptions
## - handles direct hits
## - handles empty functions
sub _make_node
   {
   my ($self, $x, $opts) = @_;
  
   if ( ! exists $self->{_x_vals_order} )
      {
      $self->_order_x_vals;
      $self->_index_x_vals;
      }
     
   if ( ! @{ $self->{_x_vals_order} } )
      {
      die "Error: cannot interpolate with no knots";
      }

   my ( $x_dn_i, $x_up_i, $oob );
      
   if ( exists $self->{_x_vals_index}{$x} )
      {
      $x_dn_i = $self->{_x_vals_index}{$x};
      $x_up_i = $x_dn_i;
      }
   elsif ( $x < $self->{_x_vals_order}[0] )
      {
      $x_dn_i = 0;
      $x_up_i = 0;
      $oob    = 1;
      }
   elsif ( $x > $self->{_x_vals_order}[-1] )
      {
      $x_dn_i = -1;
      $x_up_i = -1;
      $oob    = 1;
      }
   else
      {
      ( $x_dn_i, $x_up_i ) = do
         {
         my $min = 0;
         my $max = $#{ $self->{_x_vals_order} };
         _binary_search( $self->{_x_vals_order}, $x, $min, $max );
         };
      }
   
   if ( $oob )
      {
      my $merge_opts = $self->_merge_opts( $opts );
      if ( $merge_opts->{oob} eq 'die' )
         {
         Carp::confess "Error: given X ($x) was out of bounds of"
            . " function min or max";
         }
      elsif ( $merge_opts->{oob} eq 'extrapolate' )
         {
         if ( $x < $self->{_x_vals_order}[0] )
            {
            $x_up_i = List::Util::min( $#{ $self->{_x_vals_order} }, $x_up_i + 1 );
            }
         elsif ( $x > $self->{_x_vals_order}[-1] )
            {
            $x_dn_i = List::Util::max( 0, $x_dn_i - 1 );
            }
         }
      elsif ( $merge_opts->{oob} eq 'level' )
         {
         }
      elsif ( $merge_opts->{oob} eq 'undef' )
         {
         return;
         }
      else
         {
         Carp::confess "Error: invalid oob option ($merge_opts->{oob})";
         }
      }

   my $x_dn = $self->{_x_vals_order}[ $x_dn_i ];
   my $x_up = $self->{_x_vals_order}[ $x_up_i ];

   my $y_dn = $self->{_data}{$x_dn};
   my $y_up = $self->{_data}{$x_up};
   
   return
      {
      x_given => $x,
      x_dn    => $x_dn,
      x_up    => $x_up,
      y_dn    => $y_dn,
      y_up    => $y_up,
      };
   }

## converts a given x value and two points that define a line
## to the corresponding y value
sub _mx_plus_b
  {
  my ( $x, $x_dn, $x_up, $y_dn, $y_up ) = @_;
  
  if ( $y_dn == $y_up )
     {
     return $y_dn;
     }

  my $slope     = ( $y_up - $y_dn ) / ( $x_up - $x_dn );
  my $intercept = $y_up - ( $slope * $x_up );
  my $y = $slope * $x + $intercept;

  return $y;
  }

## vanilla binary search algorithm used to locate a given x value
## that is within the defined range of the function  
sub _binary_search
   {
   my ( $array, $value, $min_index, $max_index ) = @_;
   
   my $range_max_index = $max_index - $min_index;
   
   while ( $range_max_index > 1 )
      {

      ## size:  3 4 5 6 7 8 9 10 20
      ##  mid:  1 2 2 3 3 4 4  5 10
      my $mid_index  = $min_index + int( $range_max_index / 2 );
      
      ## value is inside the upper half
      if ( $value > $array->[$mid_index] )
         {
         $min_index = $mid_index;
         }
      ## value is inside the lower half
      else
         {
         $max_index = $mid_index;
         }

      $range_max_index = $max_index - $min_index;

      }

   return $range_max_index > -1
        ? ( $min_index, $max_index )
        : ( undef, undef );

   }
   
## - called on the first lookup after a knot has been set   
## - caches an array of ordered x values
sub _order_x_vals
   {
   my ( $self ) = @_;
   
   my @ordered_x_vals = sort { $a <=> $b } keys %{ $self->{_data} };
   
   $self->{_x_vals_order} = \@ordered_x_vals;
   }

## - called on the first lookup after a knot has been set   
## - creates an index mapping knot x values to their ordered indexes
sub _index_x_vals
   {
   my ( $self ) = @_;

   delete $self->{_x_vals_index};
   for my $i ( 0 .. $#{ $self->{_x_vals_order} } )
      {
      $self->{_x_vals_index}{ $self->{_x_vals_order}[$i] } = $i;
      }
   }

=head1 AUTHOR

Dan Boorstein, C<< <dan at boorstein.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-cpwlf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-CPWLF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::CPWLF


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-CPWLF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-CPWLF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-CPWLF>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-CPWLF/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Dan Boorstein.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Math::CPWLF
