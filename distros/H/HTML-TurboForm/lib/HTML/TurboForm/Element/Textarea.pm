package HTML::TurboForm::Element::Textarea;
use warnings;
use strict;
use base qw(HTML::TurboForm::Element);
__PACKAGE__->mk_accessors( qw/ id tinymce / );

sub init{
    my ($self)=@_;

    @{$self->{modules}} = ('tinymce/tiny_mce') if ($self->tinymce);
}

sub render {
  my ($self, $options, $view)=@_;
  if ($view) { $self->{view}=$view; }
    
  my $request=$self->request;
  my $result='';
  my $disabled='';
  my $class='form_textarea';

  $class = $self->class if ($self->class);
  my $id='';
  $id = ' id="'.$self->id.'" ' if ($self->id);
  $class = 'class="'.$class.'"';
  my $name=' name="'.$self->name.'" ';
  my $value=$request->{ $self->name };
  
  if ($options->{frozen}) {
      if ($options->{frozen} == 1) {
	  my $text= $value;
          $disabled=' disabled ';
	  $result='<input type="hidden" '.$name.' value="'.$value.'" />';
      }
  }

  my $tinytext='';
  if ($self->tinymce){
       $tinytext = '
      <script type="text/javascript">
	    tinyMCE.init({
		mode : "textareas",
		theme : "simple"
	   });
      </script>';
  }
  
  $value='' if (!$value);
  $result =$result.$tinytext.'<textarea '.$disabled.$id.$name.$class.'>'.$value.'</textarea>' ;
  return $self->vor($options).$result.$self->nach;
}

1;

__END__

=head1 HTML::TurboForm::Element::Textarea

Representation class for HTML Textarea input element.

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

