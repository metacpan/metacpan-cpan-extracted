package Form::Toolkit::Field::Set;
{
  $Form::Toolkit::Field::Set::VERSION = '0.008';
}
use Moose;

extends qw/Form::Toolkit::Field/;

=head1 NAME

Form::Toolkit::Field::Set - A Set of Pure scalar Value's (Not references).

=head1 NOTES

The 'value' field of this is in fact a set of values.

=cut

has '+value' => ( isa => 'ArrayRef[Value]' , trigger => \&_value_set );

has '_values_idx' => ( isa => 'HashRef[Value]' , is => 'rw' , required => 1 , default => sub{ {}; } );

__PACKAGE__->meta->short_class('Set');
__PACKAGE__->meta->make_immutable();

=head2 value_clone

Returns a shallow clone of the set of contained values (or undef)

=cut

sub value_clone{
  my ($self) = @_;
  unless( $self->value() ){ return ; }
  return [ @{$self->value()} ];
}

=head2 has_value

Tests if this field is currently holding the given value.

Usage:

 if( $this->has_value($whatever_value) ){
    ...
 }

=cut

sub has_value{
  my ($self, $v) = @_;
  return exists $self->_values_idx->{$v};
}


=head2 add_value

Adding value to this set. Will NOT add duplicates.
Return false on duplicate and true on success.

=cut

sub add_value{
  my ($self, $v) = @_;
  if( $self->has_value($v) ){ return; }
  ## Initialize if needed.
  $self->value() // $self->value([]);
  my $last_idx = scalar(@{$self->value()});
  push @{$self->value()} , $v;
  $self->_values_idx()->{$v} = $last_idx;
  return 1;
}

=head2 remove_value

Removes value from this set. Returns false on failure (it was not in this set)
and true on success.

=cut

sub remove_value{
  my ($self, $v) = @_;
  my $idx = $self->_values_idx()->{$v};
  unless( defined $idx ){ return; };

  # Splice the array for one element at idx
  splice( @{$self->value()} , $idx , 1);

  ## Delete index key for $v
  delete $self->_values_idx()->{$v};

  ## Update the index so all values from idx onward gets decremented.
  foreach my $value ( @{$self->value}[$idx..scalar(@{$self->value})-1] ){
    $self->_values_idx()->{$value} -= 1;
  }
  return 1;
}

sub _value_set{
  my ($self , $value, $old_value ) = @_;
  $self->_values_idx({});
  my $v_index = 0;
  foreach my $v ( @$value ){
    $self->_values_idx()->{$v} = $v_index++;
  }
}

=head2 value_struct

See superclass.

=cut

sub value_struct{
  my ($self) = @_;
  unless( $self->value() ){
    return undef;
  }
  return $self->value();
}

=head2 clear

Overrides clear so it maintains the value index.

=cut

sub clear{
   my ($self) = @_;
   $self->next::method();
   $self->_values_idx({});
};

__PACKAGE__->meta->make_immutable();

