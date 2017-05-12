package Form::Toolkit::FieldRole::MinMax;
{
  $Form::Toolkit::FieldRole::MinMax::VERSION = '0.008';
}
use Moose::Role;
with qw/Form::Toolkit::FieldRole/;

has 'v_min' => ( is => 'rw' , isa => 'Num' , clearer => 'clear_min');
has 'v_max' => ( is => 'rw' , isa => 'Num' , clearer => 'clear_max');

has '_v_min_exclude' => ( is => 'rw' , isa => 'Bool', default => 0 );
has '_v_max_exclude' => ( is => 'rw' , isa => 'Bool' , default => 0);

=head1 NAME

Form::Toolkit::FieldRole::MinMax - A Role that add a min and a max value to a field (for Numeric fields of course).

=head2 set_min

Chainable setter for v_min()

Additionaly, use that to set the exclusion flag if you want this minimum
value to be exclusive.

Usage:

 ## Set inclusive min [0..
 $this->set_min(0);
 $this->set_min(0, undef);

 ## Set exclusive min ]0..
 $this->set_min(0 ,'exclude');

=cut

sub set_min{
  my ($self , $min , $exclude ) = @_;
  $self->v_min($min);
  $self->_v_min_exclude($exclude ? 1 : 0);
  return $self;
}

=head2 set_max

Chainable setter for v_max();
Works the same way as set_min.

Usage:

   ## Set inclusive max .. 10]
   $this->set_max(10);
   $this->set_max(10, undef);

   ## Set exclusive max .. 10[
   $this->set_max(10, 'exclusive');

=cut

sub set_max{
  my ($self, $max , $exclude ) = @_;
  $self->v_max($max);
  $self->_v_max_exclude($exclude ? 1 : 0);
  return $self;
}


after 'validate' => sub{
  my ($self) = @_;
  my $v = $self->value();
  unless( defined $v){
    return;
  }

  if( defined $self->v_min() ){
    if( $self->_v_min_exclude() ){
      unless( $v > $self->v_min() ){
        $self->add_error("Please enter a Minimum value of ".$self->v_min()." (Exclusive)");
      }
    }else{
      unless( $v >= $self->v_min() ){
        $self->add_error("Please enter a Minimum value of ".$self->v_min());
      }
    }
  }
  ## Done with min.

  if( defined $self->v_max() ){
    if( $self->_v_max_exclude() ){
      unless( $v < $self->v_max() ){
        $self->add_error("Please enter a Maximum value of ".$self->v_max()." (Exclusive)");
      }
    }else{
      unless( $v <= $self->v_max() ){
        $self->add_error("Please enter a Maximum value of ".$self->v_max());
      }
    }
  }
  ## Done with max
};

1;
