package HTML::SuperForm::Field::Textarea;

use base 'HTML::SuperForm::Field';
use strict;

sub to_html {
    my $self = shift;
    my $tag = '<textarea';
    $tag .= $self->attribute_str();
    $tag .= $self->readonly_str();
    $tag .= $self->disabled_str();
    $tag .= '>';
    $tag .= $self->value();
    $tag .= '</textarea>';

    $tag = $self->label() . " $tag" if $self->has_label();

    return $tag;
}

1;

__END__

=head1 NAME

HTML::SuperForm::Field::Textarea - Textarea field used by HTML::SuperForm

=head1 SYNOPSIS

 my $textarea = HTML::SuperForm::Field::Textarea->new( name => 'my_textarea',
                                                       default => 'default text' );

 print $textarea;

=head1 SEE ALSO

 HTML::SuperForm::Field

=head1 AUTHOR

John Allwine E<lt>jallwine86@yahoo.comE<gt>

=cut
