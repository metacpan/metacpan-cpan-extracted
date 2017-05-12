package HTML::TurboForm::Constraint::Required;
use warnings;
use strict;
use base qw(HTML::TurboForm::Constraint);
__PACKAGE__->mk_accessors( qw/ emptyval / );

sub check{
  my ($self)=@_;
  my $request=$self->request;
  my $result=0;
  my $empty = '';
  $empty=$self->emptyval if ($self->emptyval);  
  if (exists($request->{$self->{name}})) {
    $result=1 if ($request->{$self->{name}} ne $empty );    
  }  
  return $result;
}

sub message{
  my ($self)=@_;
  return $self->{text};
}

1;


__END__

=head1 HTML::TurboForm::Constraint::Required

Representation class for Required constraint.

=head1 DESCRIPTION

Straight forward so no need for much documentation.
See HTML::TurboForm doku for mopre details.

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
