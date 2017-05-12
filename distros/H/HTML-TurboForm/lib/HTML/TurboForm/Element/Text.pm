package HTML::TurboForm::Element::Text;
use warnings;
use strict;
use base qw(HTML::TurboForm::Element);

sub render {
  my ($self, $options, $view)=@_;
  if ($view) { $self->{view}=$view; }
  
  my $id='';
  $id=' id="'.$self->id.'" '  if ($self->id);
  
  my $request=$self->request;
  my $result='';
  my $disabled='';
  my $class='form_text';
  $class = $self->class if ($self->class);
  
  
  
  $class = 'class="'.$class.'"';  
  
  my $name=' name="'.$self->name.'" ';
  my $value='';
  $value=' value="'.$request->{ $self->name }.'" ' if ($request->{ $self->name });
  
  if ($options->{frozen}) {
    if ($options->{frozen} eq 1) {
      my $text= $value;
      $disabled=' disabled ';
      $result='<input type="hidden" '.$name.$value.'" />';
    }
  }

  my $limit='';
  $limit=' maxlength="'.$self->limit.'"' if ($self->limit);

  $result .='<input type="'.$self->type.'"'.$disabled.$id.$name.$value.$class.$limit.'/>' ;
  return $self->vor($options).$result.$self->nach;
}

1;


__END__

=head1 HTML::TurboForm::Element::Text

Representation class for HTML Text input element.

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
