package JQuery::DataTables::Request;

use 5.012;
use strict;
use warnings;

our $VERSION = '0.109'; # VERSION

use Carp;

use base 'Class::Accessor';

=head1 NAME

JQuery::DataTables::Request - represents a DataTables server-side request

=head1 SYNOPSIS

 my $dt_req = JQuery::DataTables::Request->new( client_params => $client_parameters );
 if ( $dt_req->column(0)->{searchable} ) {
   # do something
 }

 $dt_req->search->{value}; # the global search value
 if ($dt_req->search->{regex}) {
   # global search is set to regex
 }

 # find the column definition with the name 'col_name'
 my $cols = $dt_req->find_columns( by_name => 'col_name' );

 $dt_req->draw; #sEcho or draw parameter
 $dt_req->start; #iDisplayStart or start parameter

=head1 DESCRIPTION

This module represents a DataTables server-side request originating from the DataTables
client side JS library. There are two major versions of DataTables(v1.9 and v1.10) that send
differently named parameters server-side for processing. This module only provides an API
that corresponds to the v1.10 parameters but maps the v1.9 parameters to the corresponding v1.10
parameters. 

The DataTable parameters are documented at the following locations:

=over

=item L<Version 1.10 server-side parameters|http://www.datatables.net/manual/server-side>

=item L<Version 1.9 server-side parameters|http://legacy.datatables.net/usage/server-side>

=back

Each column parameter is represented as a HashRef like so:

 {
   name => 'col_name',
   data => 'col_name',
   orderable => 1,
   searchable => 1,
   search => {
     value => 'search string',
     regex => 0,
   }
 }

e.g.

 $dt_req->column(0)->{search}{value}

Order parameters look like this:

 {
   dir => 'asc',
   column => 1
 }   

e.g.

 $dt_req->order(0)->{dir}

The order and column accessors are indexed the same way as your column parameters so 
C<< $req->column(0) >> returns the column in the client_params C<[columns][0]> column.  

C<order> is similar in that C<< $req->order(0) >> returns the C<order[0]> parameter data.

=head1 METHODS

=cut

# V1.10 accessors
__PACKAGE__->mk_accessors(qw(
    draw
    start
    length
    search
    _version
    _order
    _columns
  )
);

=head2 new

Creates a new JQuery::DataTables::Request object. 

 my $dt_request = JQuery::DataTables::Request->new( client_params => \%parameters );

Accepts the following parameters

=over

=item client_params

This is a HashRef that should contain your DataTables parameters as provided by the DataTables 
JS library. Any parameters provided that are not recognized as DataTables request are silently ignored.
Usually, whatever framework you are using will already have a way to convert these parameters
to a HashRef for you, (e.g. C<< $c->req->parameters >> in a Catalyst app)

=back

new will confess/croak on the following scenarios:

=over

=item client_params is not provided

=item client_params is not a HashRef

=item client_params isn't recognized as containing DataTables parameters

=back

You should catch these if you are worried about it.

=cut

# client_params should be hashref 
sub new {
  my ($class, %options) = @_;  

  confess 'No DataTables parameters provided in the constructor - see client_params option' 
    unless defined($options{'client_params'});
 
  confess 'client_params must be a HashRef' 
    unless ref($options{'client_params'}) eq 'HASH';

  my $obj = bless {}, __PACKAGE__;

  my $version = $obj->version( $options{client_params} );
  if (defined $version && $version eq '1.10') {
    $obj->_process_v1_10_params( $options{'client_params'} );
  } elsif (defined $version && $version eq '1.9') {
    $obj->_process_v1_9_params( $options{'client_params'} );
  } else {
    confess 'client_params provided do not contain DataTables server-side parameters (i.e. this is not DataTables request data)';
  }
  $obj->_version( $version );
  return $obj;
}

=head2 column

 my \%column = $request->column(0);

Returns a single column definition of the requested index

=cut

sub column {
  my ($self,$idx_arr) = @_;
  return if !defined($idx_arr);
  return $self->_columns->[$idx_arr];
}

=head2 columns

 my \@columns = $request->columns([0,1]);

Returns column definitions for the requested indexes. Can accept either an 
arrayref of scalars or a single column scalar. If no column index is provided
all columns are returned. 

=cut

sub columns {
  my ($self, $idx_arr) = @_;
  my $col_ref = $self->_columns;
  return $col_ref if !defined($idx_arr);
  
  $idx_arr = [ $idx_arr ] if ref($idx_arr) ne 'ARRAY';

  my $ret_arr;
  foreach my $idx ( sort @$idx_arr ) {
    push(@$ret_arr, $col_ref->[$idx]);
  }
  return $ret_arr;
}

=head2 columns_hashref

Get all column definitions as a Hashref, with the column index as the key

=cut

sub columns_hashref {
  my ($self) = @_;
  my %col_hash;
  @col_hash{ 0 .. $#{$self->_columns} } = @{$self->_columns};
  return \%col_hash;
}

=head2 find_columns

 $request->find_columns( %options )

where C<%options> hash accepts the following parameters:

=over

=item by_name

by_name accepts a scalar or arrayref of values and returns an arrayref of
column definitions

 my \@columns = $request->find_columns( by_name => ['col_name','col_name2'] );

Searchs the columns C<data> and/or C<name> parameter. 

=item search_field

 my \@columns = $request->find_columns( by_name => 'something', search_field => 'name' );

Set to either C<name> or C<data> to search those respective fields when
doing a C<by_name> seach. If no search_field is specified, C<by_name> searches
that match either field will be returned (i.e. defaults to search both fields)

=item by_idx

 my \@columns = $request->find_columns( by_idx => $col_idx )

This is just a passthrough to C<< $request->columns( $col_idx ); >>

=back

=cut

sub find_columns {
  my ($self, %options) = @_;
  return unless %options;

  if (defined($options{by_idx})) {
    return $self->columns($options{by_idx});
  }

  if (my $searches = $options{by_name}) {
    my $ret_cols; 
    my $key = $options{search_field};
    $searches = [ $searches ] if ref($searches) ne 'ARRAY';
    my $col_ref  = $self->_columns;

    foreach my $search_val ( @$searches ) {
      foreach my $col ( @$col_ref ) {
        if ( defined $key ) { 
          if ( $col->{$key} eq $search_val ) {
            push(@$ret_cols, $col);
          }
        } else {
          if ( $col->{name} eq $search_val || $col->{data} eq $search_val ) {
            push(@$ret_cols, $col);
          }
        }
      }    
    }
    return $ret_cols;
  }
}

=head2 order

 $req->order(0)->{dir}

Returns the order data at provided index.

=cut

sub order
{
  my ($self,$idx) = @_;
  return unless defined($idx);
  return $self->_order->[$idx];
}

=head2 orders

 $req->orders([0,1]);

Returns an arrayref of the order data records at the provided indexes. Accepts an arrayref or scalar.
C<< ->orders([0,1]) >> will get C<orders[0]> and C<orders[1]> data.

=cut

sub orders
{
  my ($self,$ar_idx) = @_;
  my $ord_ref = $self->_order;
  return $ord_ref unless defined($ar_idx);

  $ar_idx = [ $ar_idx ] unless ref($ar_idx) eq 'ARRAY';

  my $ret_arr;
  foreach my $idx ( @$ar_idx ) {
    push(@$ret_arr, $ord_ref->[$idx]);
  }

  return $ret_arr;
}

=head2 version

 my $version = $request->version( \%client_params? )

Returns the version of DataTables we need to support based on the parameters sent. 
v1.9 version of DataTables sends different named parameters than v1.10. Returns a string
of '1.9' if we think we have a 1.9 request, '1.10' if we think it is a 1.10 request or C<undef>
if we dont' think it is a DataTables request at all. 

This can be invoked as a class method as well as an instance method.

=cut

sub version
{
  my ($self,$client_params) = @_;

  if (!ref($self) && !defined($client_params)) {
    return;
  }

  return $self->_version unless $client_params;
  my $ref = $client_params;

  # v1.10 parameters
  if (defined $ref->{draw} && defined $ref->{start} && defined $ref->{'length'}) {
    return '1.10';
  }

  # v1.9 parameters
  if (defined $ref->{sEcho} && defined $ref->{iDisplayStart} && defined $ref->{iDisplayLength}) {
    return '1.9';
  }

  return;
}

=head1 PRIVATE METHODS


=head2 _process_v1_9_params

Processes v1.9 parameters, mapping them to 1.10 parameters

 $self->_process_v1_9_params( \%client_params )

where C<\%client_params> is a HashRef containing the v1.9 parameters that DataTables
client library sends the server in server-side mode.

=cut
  
# maps 1.9 to 1.10 variables
# only thing not mapped is iColumns
my $vmap = {
  top => { 
   'iDisplayStart' => 'start',
   'iDisplayLength' => 'length',
   'sEcho' => 'draw',
  },
  col_and_order => {
   'bSearchable' => ['columns', 'searchable', undef],
   'sSearch' => ['columns', 'search', 'value'],
   'bRegex' => ['columns', 'search', 'regex'],
   'bSortable' => ['columns', 'orderable', undef],
   'mDataProp' => ['columns', 'data', undef],
   'iSortCol' => ['order', 'column', undef],
   'sSortDir' => ['order', 'dir', undef] 
  }
};

sub _process_v1_9_params {
  my ($self, $client_params) = @_;
  my $columns;
  my $order;
  my $search;

  while ( my ($name,$val) = each %$client_params ) {
    # handle top level parameters
    if ( grep { $_ eq $name && $val =~ m/^[0-9]+$/ } keys %{$vmap->{top}} ) {
      my $acc = $vmap->{top}->{$name};
      $self->$acc( $val );
    } elsif ($name eq 'sSearch') {
      $search->{value} = $val;
    } elsif ($name eq 'bRegex') {
      $search->{regex} = $val eq 'true' ? 1 : 0;
    } elsif ($name =~ m/^(?<param>bSearchable|sSearch|bRegex|bSortable|iSortCol|sSortDir|mDataProp)_(?<idx>\d+)$/) {
      my $map = $vmap->{col_and_order}->{$+{param}};
      my ($param,$idx,$sub_param1,$sub_param2,$new_val) = 
        $self->_validate_and_convert( $map->[0], $+{idx}, $map->[1], $map->[2], $val);

      if ($map->[0] eq 'columns') {
        if (defined($sub_param2)) {
          $columns->{$idx}{$sub_param1}{$sub_param2} = $new_val;
        } else {
          $columns->{$idx}{$sub_param1} = $new_val;
          # copy name => data for v1.9 so that find_columns works as expected
          # not really sure how to do this, Data::Alias? alias it eventually
          # right now just copy
          if ($sub_param1 eq 'data') {
            $columns->{$idx}{'name'} = $new_val;
          }
        }
      } elsif ($map->[0] eq 'order') {
        $order->{$idx}{$sub_param1} = $new_val;
      }
    }
  }

  my @col_arr;
  push(@col_arr, $columns->{$_}) for ( sort keys %$columns );

  my @order_arr;
  push(@order_arr, $order->{$_}) for ( sort keys %$order );

  $self->_columns( \@col_arr );
  $self->_order( \@order_arr );
  $self->search( $search );
}

=head2 _process_v1_10_params

 $self->_process_v1_10_params( \%client_params );

where C<\%client_params> is a HashRef containing the v1.10 parameters that DataTables
client library sends the server in server-side mode.

=cut

sub _process_v1_10_params {
  my ($self, $client_params) = @_;

  my $columns; 
  my $order;
  my $search;
  while ( my ($name,$val) = each %$client_params ) {
    $self->$name( $val ) if ( grep { $_ eq $name && $val =~ m/^[0-9]+$/ } qw(draw start length) );

    if ($name =~ m/^(?<param>columns|order)\[(?<idx>[0-9]+)\]\[(?<sub_param1>[^]]+)\](\[(?<sub_param2>[^]]+)\])?$/) {
      my ($param,$idx,$sub_param1,$sub_param2,$new_val) = 
        $self->_validate_and_convert($+{param}, $+{idx}+0, $+{sub_param1}, $+{sub_param2}, $val);

      if ($param eq 'columns') {
        if (defined($sub_param2)) {
          $columns->{$idx}{$sub_param1}{$sub_param2} = $new_val;
        }  else {
          $columns->{$idx}{$sub_param1} = $new_val;
        }
      } elsif ($param eq 'order') {
        $order->{$idx}{$sub_param1} = $new_val;
      }
    } elsif ($name =~ m/^search\[(?<search_param>regex|value)\]$/) {
      my $sp = $+{search_param};
      if ($sp eq 'regex') {
        $search->{$sp} = $val eq 'true' ? 1 : 0;
      } else {
        $search->{$sp} = $val;
      }
    }
  }

  my @col_arr;
  push(@col_arr, $columns->{$_}) for ( sort keys %$columns );

  my @order_arr;
  push(@order_arr, $order->{$_}) for ( sort keys %$order );

  $self->_columns( \@col_arr );
  $self->_order( \@order_arr );
  $self->search( $search );
  return $self;
}

=head2 _validate_and_convert

Validates parameters are set properly and does boolean conversion

=cut

#XXX: make this not a mess
sub _validate_and_convert
{
  my ($self,$param,$idx,$sub1,$sub2,$val) = @_;
  if ($param eq 'columns') {
    if ($sub1 eq 'orderable' || $sub1 eq 'searchable') {
      $val = lc $val eq 'true' ? 1 : 0;
    } elsif ( $sub1 eq 'search' && $sub2 eq 'regex' ) {
      $val = lc $val eq 'true' ? 1 : 0;
    }
  } elsif ($param eq 'order') {
    if ($sub1 eq 'dir' && lc $val ne 'asc' && lc $val ne 'desc') {
      #warn 'Unknown order[dir] value provided. Must be asc or desc, defaulting to asc';
      $val = 'asc';
    }
  }
  return ($param,$idx,$sub1,$sub2,$val);
}

=head1 AUTHOR

Mike Wisener E<lt>xmikew_cpan_orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright E<copy> 2014 by Mike Wisener

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
