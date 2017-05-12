package HTML::TurboForm::Element::Hidden;
use warnings;
use strict;
use base qw(HTML::TurboForm::Element);

sub render {
  my ($self, $options, $view)=@_;
  if ($view) { $self->{view}=$view; }
  my $request=$self->request;
  my $result='';
  my $disabled='';
  my $id='';

  $id=" id='".$self->name."' ";

  my $name=' name="'.$self->name.'" ';
  my $value='';
  $value=' value="'.$self->value.'" ' if ($self->value);
  $value=' value="'.$request->{ $self->name }.'" ' if ($request->{ $self->name });

  $result .='<input type="'.$self->type.'" '.$id.' '.$name.$value.'>' ;
  
  
  
  return $result;
}

1;


__END__

=head1 HTML::TurboForm::Element::Hidden

Representation class for HTML Hidden input element.

=head1 DESCRIPTION

Straight forward so no need for much documentation.
See HTML::TurboForm doku for mopre details.

=head1 METHODS

=head2 render

Arguments: $options

returns HTML Code for element.

=head1 AUTHOR

Thorsten Domsch, tdomsch@gmx.de

=cut

