################################################################################
# Example tied hash for testing options
################################################################################
package TieOptions;
use strict;
use Tie::Hash;
use Hash::AutoHash;
our @ISA = qw(Tie::ExtraHash);

use constant STORAGE=>0;
use constant OPTIONS=>1;

sub TIEHASH {
  my($class,@hash)=@_;
  my $self=bless [{},new Hash::AutoHash],$class;
  while (@hash>1) {
    my($key,$value)=splice @hash,0,2; # shift 1st two elements
    $self->STORE($key,$value);
  }
  $self;
}
sub FETCH {
  my($self,$key)=@_;
  my $storage=$self->[STORAGE];
  $storage->{$key};
}
sub STORE {
  my($self,$key,$value)=@_;
  my $storage=$self->[STORAGE];
  $storage->{$key}=$value;
}
sub CLEAR {
  my($self)=@_;
  %{$self->[STORAGE]}=();
  %{$self->[OPTIONS]}=();
}
use vars qw($AUTOLOAD);
sub AUTOLOAD {
  my $self=shift;
  $AUTOLOAD=~s/^.*:://;		               # strip class qualification
  return if $AUTOLOAD eq 'DESTROY';            # the books say you should do this
  my $option=$AUTOLOAD;
  my $options=$self->[OPTIONS];
  $options->$option(@_);
}
1;
