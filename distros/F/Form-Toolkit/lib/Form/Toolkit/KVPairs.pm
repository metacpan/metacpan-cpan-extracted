package Form::Toolkit::KVPairs;
{
  $Form::Toolkit::KVPairs::VERSION = '0.008';
}
use Moose;

=head1 NAME

Form::Toolkit::KVPairs - An abstract source of Key Value Pairs.

=cut

=head2 size

Gives the size of the Key Value Pairs set.

Usage:

  there is $this->size() key-value pairs in this Set.

=cut

sub size{
  my ($self) = @_;
  confess("Please implement this in $self");
}

=head2 lookup

Looks up the key in the Set and return undef if not found, or the value.

usage:

  if( my $value = $this->lookup($key) ){

  }

=cut

sub lookup{
  my ($self , $key ) = @_;
  confess("Please implement this in self");
}

=head2 next_kvpair

Returns () or the next ( key => value ) tuple of this set. Calling that turns this source into an iterator.

So you can do:

while( my @kv = $this->next_kvpair() ){
  print "Key,value: ".join(',' , @kv);
}

=cut

sub next_kvpair{
  my ($self) = @_;
  confess("Please implement this in self");
}


1;
