package HTML::TurboForm::Constraint::Regex;
use warnings;
use strict;
use base qw(HTML::TurboForm::Constraint);
__PACKAGE__->mk_accessors( qw/ regex / );

sub check{
  my ($self)=@_;
  my $result=0;
  
  my $request=$self->request;    
  my $regex = $self->regex;
  
  my $value=$request->{$self->{name}};
  return 1 if (!$value);
  if ($regex){ return 1 if( $value =~ qr/$regex/ ); }
  return 0;  
}

sub message{
  my ($self)=@_;
  return $self->{text};
}

1;

__END__

=head1 HTML::TurboForm::Constraint::Regex

Representation class for Regex constraint.

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