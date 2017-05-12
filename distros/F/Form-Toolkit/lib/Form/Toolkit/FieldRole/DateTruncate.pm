package Form::Toolkit::FieldRole::DateTruncate;
{
  $Form::Toolkit::FieldRole::DateTruncate::VERSION = '0.008';
}
use Moose::Role;
use DateTime;
with qw/Form::Toolkit::FieldRole/;

=head1 NAME

Form::Toolkit::FieldRole::DateTruncate - Truncate a Date to the given date_truncation.

=cut

has 'date_truncation' => ( is => 'rw' , isa => 'Str', required => 1);

around 'value' => sub{
  my ($orig, $self, $new_date) = @_;
  unless( $new_date ){ return $self->$orig();};

  return $self->$orig($new_date->truncate( to => $self->date_truncation ));
};

around 'value_struct' => sub{
  my ($orig, $self, @rest) = @_;
  unless(defined $self->value() ){
    return undef;
  }
  if( grep { $_ eq $self->date_truncation() } ( "year", "month", "week", "day" ) ){
    return $self->value()->ymd();
  }else{
    return $self->value()->iso8601();
  }
};

=head2 value_matches

Returns true if the held value matches the given date given the set date_truncation.

Usage:

 $this->value_matches(DateTime->now());

=cut

sub value_matches{
  my ($self, $other) = @_;
  unless( defined $self->value() ){ return; }
  unless( defined $other){ return; }
  return DateTime->compare($self->value(), $other->clone()->truncate( to => $self->date_truncation() )) == 0;
}

=head2 value_before

Is the value before (inclusive) the given date in the set date_truncation?

Usage:

 if( $this->value_before(DateTime->now()) ){

 }

=cut

sub value_before{
  my ($self, $other) = @_;
  unless( defined $self->value() ){ return; }
  unless( defined $other){ return; }
  return DateTime->compare($self->value(), $other->clone()->truncate( to => $self->date_truncation() )) <= 0;
}

1;
