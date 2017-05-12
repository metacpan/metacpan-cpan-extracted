package HTML::TurboForm::Constraint::Mintime;
use warnings;
use strict;
use base qw(HTML::TurboForm::Constraint);
use Crypt::Lite;
__PACKAGE__->mk_accessors( qw/ mintime session keyphrase keyname / );

sub check{
  my ($self)=@_;
  my $request=$self->request;
  
  my $result=0;
  my $mintime = 5;  
  $mintime=$self->mintime if ($self->mintime);  
  my $time=time();
  my $id=$self->name;
  $id=$self->name.$self->keyname if ($self->keyname);  
  my $t=$self->session->{$id};
    
  my $crypt = Crypt::Lite->new( debug => 0, encoding => 'hex8' );  
  if ($self->keyphrase) {
      $t=$crypt->decrypt($t,$self->keyphrase);
  }
  
  $result=1 if (($time-$mintime) > $t);
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
