package HTML::TurboForm::Element::Html;
use warnings;
use strict;
use base qw(HTML::TurboForm::Element);
__PACKAGE__->mk_accessors( qw/ pure / );

sub render {
  my ($self, $options, $view)=@_;
  if ($view) { $self->{view}=$view; }

  return $self->{text} if ($self->{pure});
  return $self->vor($options).$self->{text}.$self->nach;
}

sub get_dbix{
    my ($self)=@_;
    return 0;
}

1;


__END__

=head1 HTML::TurboForm::Element::Html

Representation class for Html element .

=head1 DESCRIPTION

Straight forward so no need for much documentation.
See HTML::TurboForm doku for mopre details.

=head1 METHODS

=head2 render

Arguments: $options

returns HTML Code. This element is needed if you want to insert plain HTML Code in a certain Position in a form.


=head1 AUTHOR

Thorsten Domsch, tdomsch@gmx.de

=cut


