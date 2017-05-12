package HTML::TurboForm::Constraint::Length;
use warnings;
use strict;
use base qw(HTML::TurboForm::Constraint);
__PACKAGE__->mk_accessors( qw/ maxlength / );

sub check{
  my ($self)=@_;
  my $result=0;
  
  my $request=$self->request;
    
  my $max = $self->maxlength;

  if ($max){
      my $value=$request->{$self->{name}};
      return 1 if( length($value) <= $max );
  }
  return 0;  
}

sub message{
  my ($self)=@_;
  return $self->{text};
}

1;

__END__

=head1 HTML::TurboForm::Constraint::Length

Representation class for Length constraint.

=head1 DESCRIPTION

Straight forward so no need for much documentation.
See HTML::TurboForm doku for mopre details.

=head1 METHODS

=head2 check

Arguments: none

returns 1 if valid, otherwise 0.

=head1 AUTHOR

Thorsten Domsch, tdomsch@gmx.de

=cut