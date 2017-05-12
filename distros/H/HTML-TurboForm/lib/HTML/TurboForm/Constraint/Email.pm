package HTML::TurboForm::Constraint::Email;
use warnings;
use strict;
use Email::Valid;
use base qw(HTML::TurboForm::Constraint);

sub check{
  my ($self)=@_;
  my $request=$self->request;
  
  return 1 if Email::Valid->address( -address => $request->{$self->name} );
  return 0;  
}

sub message{
  my ($self)=@_;
  return $self->{text};
}

1;

__END__

=head1 HTML::TurboForm::Constraint::Email

Representation class for Email constraint.

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


