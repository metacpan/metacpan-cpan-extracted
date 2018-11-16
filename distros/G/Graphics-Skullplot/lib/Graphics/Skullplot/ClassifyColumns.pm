package Graphics::Skullplot::ClassifyColumns;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Graphics::Skullplot::ClassifyColumns - simple type inference of columns of tabular data

=head1 VERSION

Version 0.01

=cut 

# TODO revise these before shipping
our $VERSION = '0.02';
my $DEBUG = 1;

=head1 SYNOPSIS

  use Graphics::Skullplot::ClassifyColumns;

  my $cc = Graphics::Skullplot::ClassifyColumns->new( data => $data );  
  my $plot_cols = 
    $cc->classify_columns_simple( { indie_count => $indie_count, } );

=head1 DESCRIPTION

Graphics::Skullplot::ClassifyColumns is a stripped down version 
of an old experimental module I was developing I called Data::Classify.
I expect to go back to that project and develop a more elaborate 
system of plug-ins to target different kinds of databases and so on,
most likely named Table::TypeInference.

This particular module just needs a "classify_columns_simple" routine 
that works well enough to figure out how to plot some data via 
ggplot2 in R (i.e. the "Graphics::Skullplot" project).

=cut

use 5.10.0;
use strict;
use warnings;
use Carp;
use Data::Dumper;

use Scalar::Classify qw();

=over

=item new

Creates a new Graphics::Skullplot::ClassifyColumns object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item data

A required field, columns of data as an array of array references, 
with a header in the first row.

=back

=cut

# Example attribute:
# has is_loop => ( is => 'rw', isa => Int, default => 0 );
# Tempted to use Mouse over Moo so I can do my usual "isa => 'Int'"

has data => ( is => 'ro', isa => ArrayRef );

has patterns => ( is => 'ro', isa => HashRef, builder => "define_regxeps" );

# $DB::single = 1;


=item classify_columns_simple

Note: here "simple" might be thought of as "stub":
This does the simplest possible categorization using only 
a single numeric hint for the number of independent fields.

The presumption here is the incoming data is organized like 
the output of a typical sql group by select, x-axis in the 
first column a number of columns of dependent data as the
end, and (possibly) a certain number of categorical variables
(ones with a small number of allowed values) in-between.

This returns a hash indicating how different columns should be
handled in the plotting stage, the keys are:

  x    (rename: indie_x )
  y             but just for when there's only one dependent 
  gb_cats
  dep_fields  (rename: dependents_y }

Example usage:

  my $cc = Graphics::Skullplot::ClassifyColumns->new( data => $data );  
  my $opt = { indie_count => 1, };
  my $plot_cols_href = 
    $cc->classify_columns_simple( $opt ); 

=cut

sub classify_columns_simple {
  my $self = shift;

  my $opt          = shift;
  my $indie_count  = $opt->{ indie_count } // 1;

  my %field_data; # return values

  my $dependent_requested   = $opt->{ dependent_requested };
  my $independent_requested = $opt->{ independent_requested };

  my $data = $self->data;
  my @header = @{ $data->[0] };

  # when we're told what to do there's no need to guess
  if ( $dependent_requested && $independent_requested ) {

    # TODO might be better to just use the empty set
    # my @gb_cats = grep{ !/^$dependent_requested$/ } grep{ !/^$independent_requested$/ } @header;
    my @gb_cats = ();

    %field_data =
      ( indie_x       => $independent_requested,  
        y             => $dependent_requested,   # redundant with dependents_y
        gb_cats       => [ @gb_cats ],
        dependents_y  => [ $dependent_requested ],
      );
  } else { 
    # use first col as the default independent variable (x-axis)
    my $independent_default  = $header[ 0 ];
    my $x_field = $independent_default;
  
    # to start might presume we're just plotting the last column as the y-axis
    my $dependent_default = $header[ -1 ];

    # the middle columns, excluding first and the trailing dependents
    my @gb_cats = @header[ 1 .. ( $#header - $indie_count) ]; 

    # the trailing dependents
    my @dependents_y = @header[ ( ( $#header - $indie_count ) + 1 ) .. $#header ]; 

    my $y_field = '';
    if ($indie_count == 1 ) { 
      $y_field = $dependent_default;
    }

    %field_data =
      ( indie_x     => $x_field       || '',    
        y           => $y_field       || '', # redundant with dependents_y
        gb_cats     => [ @gb_cats ],
        dependents_y  => [ @dependents_y ],
      );
  }
  return \%field_data;
}





=item column_types

Given a reference to tabular data in an array-of-arrays format-
with a header expected in the first row- tries to infer the 
rough data type of each column.

Returns a list (or aref) of the type codes, in sequence.

=cut

sub column_types {
  my $self = shift;
  my $data = $self->data;

  my @header = @{ $data->[0] };

  my @types = ();
  foreach my $col ( 0 .. $#header ) {
    # initialize vars to summarize the column parameters
    my %type_count = ();
    foreach my $idx ( 1 .. $#{ $data } ) {
      my $row = $data->[ $idx ];
      my $item = $row->[ $col ];

      my $overall_type = $self->classify( $item );
      $type_count{ $overall_type } += 1;  
    }
    my $type = $self->most_common( \%type_count );
    push @types, $type;
  }
  return wantarray ? @types : \@types; 
}


=item classify

A wrapper around Scalar::Classify's "classify", which also
subdivides the string category, looking for datetime types.

The type is most often (but not limited to) one of the following:

   ARRAY
   HASH
   :NUMBER:
   :STRING:

This code examines any string values to see if a date/time code
is more appropriate:

   :DATE: 
   :DATETIME: 
   :TIME:

=cut

sub classify {
  my $self = shift;
  my $item = shift;

  # my $yyyymmdd_pat = qr{ \d\d\d\d - \d\d - \d\d }x;
  my $pats = $self->patterns;
  my $yyyymmdd_pat = $pats->{ yyyymmdd };
  my $datetime_pat = $pats->{ datetime };
  my $time_pat     = $pats->{ time };

  my $type = '';
  my $overall_type = ( Scalar::Classify::classify( $item ) )[0];
  if ( $overall_type eq ':STRING:' ) {
     # check if this looks like a date, time, or date-time
    if( $item =~ m{ $yyyymmdd_pat }x ){  
      $type = ':DATE:';  
    } elsif( $item =~ m{ $datetime_pat }x ){  
      $type = ':DATETIME:';  
    } elsif( $item =~ m{ $time_pat }x ){  
      $type = ':TIME:';  
    } else {
      $type = ':STRING:';
    };
  } elsif ($overall_type eq ':NUMBER:' ) {
    $type = ':NUMBER:';
  } else {
    warn "$overall_type may not be handled well.";
    $type = $overall_type;
  }
  return $type;
}


=item most_common

Given a hash of numeric counts, returns the key of the maximum count.

In the case of a tie, the return will be one of the tie values,
which one is undefined.

=cut

sub most_common {
  my $self = shift;
  my $counts = shift;

  my $max = 0;
  my $pick = '';
  foreach my $k  ( keys %{ $counts } ) {
    my $c = $counts->{ $k };
    if ( $c > $max ) {
      $pick = $k;
    }
  }
  return $pick;
}


=item define_regxeps

Generates a hashref of locally useful regexps.

These are mostly intended to identify dates and times.
TODO just look up existing solutions, e.g. Regexp::Common.

=cut

sub define_regxeps {
  my $self = shift;

  my $d    = qr{ [0-9] }x;
  my $d01  = qr{ [0-1] }x;
  my $d03  = qr{ [0-3] }x;
  my $d02  = qr{ [0-2] }x;
  my $d04  = qr{ [0-4] }x;
  my $d06  = qr{ [0-6] }x;

  # None of these patterns allow for leading zeros, trailing am/pm or timezones
  my %patterns =
    (  yyyymmdd1  => qr{ ^ \d\d\d\d - \d\d - \d\d $ }x,
       yyyymmdd2  => qr{ ^ $d$d$d$d - $d$d - $d$d $  }x,
       yyyymmdd   => qr{ ^ $d$d$d$d - $d01$d - $d03$d $ }x,

       hhmm       => qr{ ^ $d02$d : $d06$d }x, # note: unpinned at end
       hhmmss     => qr{ ^ $d02$d : $d06$d : $d06$d $ }x,

       time       => qr{ ^ $d02$d : $d06$d [:\d]* $}x,

       datetime   => qr{ ^ $d$d$d$d - $d01$d - $d03$d \s+ $d02$d : $d06$d [:\d]* $ }x,

    );
  return \%patterns;
}





=back

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
22 May 2018

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

No warranty is provided with this code.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
