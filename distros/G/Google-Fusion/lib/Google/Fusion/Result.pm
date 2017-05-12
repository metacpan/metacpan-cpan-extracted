package Google::Fusion::Result;
use 5.006;
use Moose;
use Carp;

=head1 NAME

Google::Fusion::Result - A Query result

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

  my $fusion = Google::Fusion->new( %fusion_params );

  # Get the result for a query
  my $result = $fusion->query( $sql );
  
  # Print out the rows returned
  foreach( @{ $result->rows } ){
      print join( ',', @{ $_ } ) . "\n";
  }

=head1 PARAMS/ACCESSORS

=over 2

=item * query <Str>

The query string

=item * response <HTTP::Response>

The response object associated with the query

=item * error <Str>

Error string, if an error occurred

=item * num_columns <Int>

Number of columns the result has

=item * num_rows <Int>

Number of rows this result has (excluding headers).

=item * max_lengths <ArrayRef[Int]>

Array of the maximum lengths of fields for each column

=item * has_headers <Bool>

True if this result has headers

=item * query_time <Num>

Seconds (using Time::HiRes) the query took

=item * auth_time <Num>

Seconds (using Time::HiRes) the authentication part of the query took

=item * total_time <Num>

Total time for the query

=item * rows <ArrayRef[ArrayRef]>

The actual results

=item * columns <ArrayRef>

The column names (if has_headers is true).

=back

=cut

has 'query'         => ( is => 'ro', isa => 'Str',                required => 1                       );
has 'response'      => ( is => 'ro', isa => 'HTTP::Response',     required => 1                       );
has 'error'         => ( is => 'rw', isa => 'Str',                                                    );
has 'num_columns'   => ( is => 'rw', isa => 'Int',                required => 1, default => 0         );
has 'num_rows'      => ( is => 'rw', isa => 'Int',                required => 1, default => 0         );
has 'max_lengths'   => ( is => 'rw', isa => 'ArrayRef',           required => 1, default => sub{ [] } );
has 'has_headers'   => ( is => 'rw', isa => 'Bool',               required => 1, default => 0         );
has 'query_time'    => ( is => 'rw', isa => 'Num',                required => 1, default => 0         );
has 'auth_time'     => ( is => 'rw', isa => 'Num',                required => 1, default => 0         );
has 'total_time'    => ( is => 'rw', isa => 'Num',                required => 1, default => 0         );
has 'rows'          => ( 
    is          => 'rw',
    isa         => 'ArrayRef[ArrayRef]',
    required    => 1,
    default     => sub{ [] },
    trigger     => sub{ $_[0]->num_rows( scalar( @{ $_[1] } ) ) },
    );

has 'columns'       => ( 
    is          => 'rw',
    isa         => 'ArrayRef',           
    required    => 1, 
    default     => sub{ [] },
    trigger     => sub{ $_[0]->num_columns( scalar( @{ $_[1] } ) ) },
    );

=head1 AUTHOR

Robin Clarke, C<< <perl at robinclarke.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
