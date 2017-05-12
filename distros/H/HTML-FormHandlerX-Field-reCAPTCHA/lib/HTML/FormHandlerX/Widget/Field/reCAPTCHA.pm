package HTML::FormHandlerX::Widget::Field::reCAPTCHA;

use Moose::Role;

sub render {
    my ( $self, $result ) = @_;
    $result ||= $self->result;
    
    if( !$self->value || ($self->value && $self->has_errors)) {
        my @args = $self->prepare_public_recaptcha_args;
        my $output = $self->recaptcha_instance->get_html(@args);
        return $self->wrap_field($result, $output);
    } else {        
        my $security_code = $self->encrypt_hex($self->public_key);
        return <<"END";
        <input type='hidden' name='recaptcha_response_field' value='$security_code' />
        <input type='hidden' name='recaptcha_already_validated' value='1' />
END
    }
}

sub prepare_public_recaptcha_args {
    my $self = shift @_;
    return (
        $self->public_key,
        $self->{recaptcha_error},
        $self->use_ssl,
        $self->recaptcha_options,
    );
}

use namespace::autoclean;
1;
