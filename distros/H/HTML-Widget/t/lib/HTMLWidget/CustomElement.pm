package HTMLWidget::CustomElement;

use warnings;
use strict;
use base 'HTML::Widget::Element';

__PACKAGE__->mk_accessors(qw/comment label value/);
__PACKAGE__->mk_attr_accessors(qw/size maxlength/);

sub prepare {
    my ($self) = @_;
    
    $self->attributes->{class} = "my_tag";
}

sub containerize {
    my ( $self, $w, $value, $errors ) = @_;

    $value ||= $self->value;

    $value = ref $value eq 'ARRAY' ? shift @$value : $value;

    my $l = $self->mk_label( $w, $self->label, $self->comment, $errors );
    my $i = $self->mk_input( $w, { type => 'text', value => $value }, $errors );
    my $e = $self->mk_error( $w, $errors );

    return $self->container( { element => $i, error => $e, label => $l } );
}

1;
