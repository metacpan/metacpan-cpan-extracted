package HTML::TurboForm::Constraint::Equation;
use warnings;
use strict;
use base qw(HTML::TurboForm::Constraint);
__PACKAGE__->mk_accessors( qw/ operator comp / );
sub check{
  my ($self)=@_;
  my $result=0;
  my $request=$self->request;

  my $op=''; 
  my $comp_val;
  my $val=$request->{ $self->name };
  $op=          $self->operator;
  $comp_val =   $self->comp ;

  if (($op eq "eq") or ($op eq "ne")) {
    if (($val)&&($comp_val)){
    $val="'$val'";
    $comp_val="'$comp_val'";
    }
  }

  if ($val and $op and $comp_val ){
    my $equation=$val." ".$op." ".$comp_val ;
    return 1 if( eval($equation) );
  }
    
  return 0;  
}

sub message{
  my ($self)=@_;
  return $self->text;
}

1;


__END__

=head1 HTML::TurboForm::Constraint::Equation

Representation class for Equation constraint.

=head1 DESCRIPTION

The equation constraint is supposed to be used whenever two values are to be compared. 
You have to give it the perl operator (ne, eq, <,>, whatever) and the two values to be compared via the params hash.
Straight forward so no need for much documentation. See HTML::TurboForm doku for mopre details.

=head1 METHODS

=head2 check

Arguments: none

returns 1 if valid, otherwise 0.

=head2 message

Arguments: none

returns Errormessage of Element which is connected to constraint.

=head1 AUTHOR

Thorsten Domsch, tdomsch@gmx.de

=cut

