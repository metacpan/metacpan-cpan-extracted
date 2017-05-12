################################################################################
# Example tied hash for testing
# Based on Tie::Hash::MultiValue from CPAN
#   Lets TIEHASH accept initial values. Does not support 'unique'. 
#   Lets FETCH return array in array context
################################################################################
package TieMV;
use strict;
use Tie::Hash;
use Scalar::Util qw(refaddr);
our @ISA = qw(Tie::StdHash);
our %DESTROYED;		       	# for DESTROY tests
our $TIEHASH_PARAM;		# for testing TIEHASH params vs. initial values in autohash_new

sub TIEHASH {
  my($class,@hash)=@_;
  my $self=bless {},$class;
  if (@hash==1) {		# for testing TIEHASH params vs. initial values in autohash_new
    $TIEHASH_PARAM=shift @hash;
  } else {
    while (@hash>1) {
      my($key,$value)=splice @hash,0,2; # shift 1st two elements
      $self->STORE($key,$value);
    }}
  $DESTROYED{refaddr($self)}=0;	# for DESTROY tests
  $self;
}
sub FETCH {
  my($self,$key)=@_;
  my $value=$self->{$key};
  if (wantarray) {
    return defined $value? @$value: ();
  }
  $value;
}
sub STORE {
  my($self,$key,@values)=@_;
  push @{$self->{$key}}, @values;
}
sub DESTROY  { 			# for DESTROY tests
  my $self=shift;
  $DESTROYED{refaddr($self)}++;
}
1;
