package Mason::Plugin::SliceFilter::t::CaptureParam;
use Test::Class::Most parent => 'Mason::Test::Class';
sub test_slice_filter :Test(5){
  my $self = shift;
  $self->setup_interp( plugins => [ '@Default', 'SliceFilter' ] );

  ## Just one slice without any param
  $self->test_comp( src =>
q|
% $.Slice(slice_id => 'aslice' , get_slice => sub{ return undef; } ){{
SliceA
% }}
|,
                    expect => 'SliceA');

## Hit the first slice
  $self->test_comp( src =>
q|
% $.Slice(slice_id => 'aslice' , get_slice => sub{ return 'aslice'; } ){{
SliceA
% }}
% $.Slice(slice_id => 'bslice' ){{
SliceB
% }}
|,
                    expect => 'SliceA');

## Simple Currying
  $self->test_comp( src =>
q|
% my $MySlice = sub{ my (%args) = @_;  return $.Slice(%args, get_slice => sub{ return 'bslice' } ) };
% $MySlice->(slice_id => 'aslice' ){{
SliceA
% }}
% $MySlice->(slice_id => 'bslice' ){{
SliceB
% }}
|,
                    expect => 'SliceB');

## Currying at class level
  $self->test_comp( src =>
q|
<%class>
  has 'MySlice' => ( default =>
                     sub{
                         my $self = shift;
                         return sub{ my (%args) = @_;
                                     return $self->Slice(get_slice => sub{ return 'bslice' } , %args );
                                    };
                        } );
</%class>
% $.MySlice->(slice_id => 'aslice' ){{
SliceA
% }}
% $.MySlice->(slice_id => 'bslice' ){{
SliceB
% }}
|,
                    expect => 'SliceB');


## Hit the second slice
  $self->test_comp( src =>
q|
% my $get_slice = sub{ return 'bslice'};
% $.Slice(slice_id => 'aslice', get_slice => $get_slice ){{
SliceA
% }}
% $.Slice(slice_id => 'bslice', get_slice => $get_slice ){{
SliceB
% }}
|,
                    expect => 'SliceB' );

}

1;
