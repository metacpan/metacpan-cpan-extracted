package Mason::Plugin::SliceFilter::t::Basic;

use Test::Class::Most parent => 'Mason::Test::Class';
sub test_slice_filter :Test(11){
  my $self = shift;

  my $STASH = {};

  $self->setup_interp( plugins => [ '@Default', 'SliceFilter' ] , allow_globals => [qw($STASH)]);
  $self->interp->set_global('$STASH' , $STASH);

  ## Just one slice without any param
  $self->test_comp( src =>
q|
% $.Slice(slice_id => 'aslice'){{
SliceA
% }}
|,
                    expect => 'SliceA');

  ## One slice with yield_noslice false
  $self->test_comp( src =>
q|
% $.Slice(slice_id => 'aslice' , yield_noslice => 0 ){{
SliceA
% }}
|,
                    expect => '');


  ## One slice with yield_noslice false, hitting the slice
  $self->test_comp( src =>
q|
% $.Slice(slice_id => 'aslice' , yield_noslice => 0 ){{
SliceA
% }}
|,
                    expect => 'SliceA' , args => { slice => 'aslice' } );



## Hit the first slice
  $self->test_comp( src =>
q|
% $.Slice(slice_id => 'aslice'){{
SliceA
% }}
% $.Slice(slice_id => 'bslice' ){{
SliceB
% }}
|,
                    expect => 'SliceA' , args => { slice => 'aslice' });

## Hit the second slice
  $self->test_comp( src =>
q|
% $.Slice(slice_id => 'aslice'){{
SliceA
% }}
% $.Slice(slice_id => 'bslice' ){{
SliceB
% }}
|,
                    expect => 'SliceB' , args => { slice => 'bslice' });

## Nested ones.
  $self->test_comp( src =>
q|
% $.Slice(slice_id => 'aslice'){{
Before nest
% $.Slice(slice_id => 'nest' ){{
Nested
% }}
After nest
% }}
% $.Slice(slice_id => 'bslice' , can_skip => 1 ){{
SliceB
% }}
|,
                    expect => 'Nested' , args => { slice => 'nest' });

## Nested ones. Hitting the wrapping one should output the whole
## thing, even if the nested slice is can_skip
  $self->test_comp( src =>
q|
% $.Slice(slice_id => 'aslice'){{
Before nest
% $.Slice(slice_id => 'nest' , can_skip => 1 ){{
Nested
% }}
After nest
% }}
% $.Slice(slice_id => 'bslice' , can_skip => 1 ){{
SliceB
% }}
|,
                    expect => "Before nest\nNested\nAfter nest\n" , args => { slice => 'aslice' });




$STASH->{side_effect} = 0;
## After nesting with skipping
  $self->test_comp( src =>
q|
% $.Slice(slice_id => 'aslice' , can_skip => 1 ){{
Before nest
% $.Slice(slice_id => 'nest' ){{
% $STASH->{side_effect} = 1;
Nested
% }}
After nest
% }}
% $.Slice(slice_id => 'bslice' , can_skip => 1 ){{
SliceB
% }}
|,
                    expect => 'SliceB' , args => { slice => 'bslice' });

ok( $STASH->{side_effect} == 0 , "Side effect is still zero because of can_skip");

# Without skipping

  $self->test_comp( src =>
q|
% $.Slice(slice_id => 'aslice' , can_skip => 0 ){{
Before nest
% $.Slice(slice_id => 'nest' ){{
% $STASH->{side_effect} = 1;
Nested
% }}
After nest
% }}
% $.Slice(slice_id => 'bslice' , can_skip => 1 ){{
SliceB

% }}
|,
                    expect => 'SliceB' , args => { slice => 'bslice' });

ok( $STASH->{side_effect} == 1 , "Side effect occured because can_skip is 0");

}

1;
