package HTML::FormHandlerX::Field::reCAPTCHA;

use 5.008;
use Captcha::reCAPTCHA;
use Crypt::CBC;

use Moose;
extends 'HTML::FormHandler::Field';

our $VERSION = '0.04';
our $AUTHORITY = 'cpan:JJNAPIORK';

has '+widget' => ( default => 'reCAPTCHA' );
has '+input_param' => ( default => 'recaptcha_response_field' );

has [qw/public_key private_key/] => (is=>'rw', isa=>'Str', lazy_build=>1);
has 'use_ssl' => (is=>'rw', isa=>'Bool', required=>1, default=>0);
has 'remote_address' => (is=>'rw', isa=>'Str', lazy_build=>1);
has 'recaptcha_options' => (is=>'rw', isa=>'HashRef', required=>1, default=>sub{ +{} });
has 'recaptcha_message' => (is=>'rw', isa=>'Str', default=>'Error validating reCAPTCHA');
has 'recaptcha_instance' => (is=>'ro', init_arg=>undef, lazy_build=>1);
has 'encrypter' => (is=>'ro', init_arg=>undef, lazy_build=>1,
  handles=>[qw/encrypt_hex decrypt_hex/]);

sub _build_public_key {
    my $self = shift @_;
    my $form = $self->form;
    my $method = $self->name.'_public_key';
    if ($form->can($method)) {
        return $form->$method;
    } else {
        die "You either have to set the 'public_key' field option or defined a $method method in your form!";
    }
}

sub _build_private_key {
    my $self = shift @_;
    my $form = $self->form;
    my $method = $self->name.'_private_key';
    if ($form->can($method)) {
        return $form->$method;
    } else {
        die "You either have to set the 'private_key' field option or defined a $method method in your form!";
    }
}

sub _build_encrypter {
    my $self = shift @_;
    my $key = pack("H16",$self->private_key);
    return Crypt::CBC->new(-key=>$key,-cipher=>"Blowfish");   
}

sub _build_remote_address {
    $ENV{REMOTE_ADDR};
}

sub _build_recaptcha_instance {
    Captcha::reCAPTCHA->new();
}

sub prepare_private_recaptcha_args {
    my $self = shift @_;
    return (
        $self->private_key,
        $self->prepare_recaptcha_args,
    );
}

sub prepare_recaptcha_args {
    my $self = shift @_;
    return (
        $self->remote_address,
        $self->form->params->{'recaptcha_challenge_field'},
        $self->form->params->{'recaptcha_response_field'},
    );
}

sub validate {
    my ($self, @rest) = @_;
    unless(my $super = $self->SUPER::validate) {
        return $super;
    }
    my $recaptcha_response_field = $self->form->params->{'recaptcha_response_field'};
    if($self->form->params->{'recaptcha_already_validated'}) {
        if($recaptcha_response_field &&
          ($self->decrypt_hex($recaptcha_response_field) eq $self->public_key)
        ) { 
            return 1;
        } else {
            $self->add_error("Previous reCAPTCHA validation lost. Please try again.");
            return undef;
        }
    } else {
        my @args = $self->prepare_private_recaptcha_args;
        my $result = $self->recaptcha_instance->check_answer(@args);
        if($result->{is_valid}) {
            return 1;
        } else {
            $self->{recaptcha_error} = $result->{error};
            $self->add_error($self->recaptcha_message);
            return undef;
        }
    }
}

=head1 NAME

HTML::FormHandlerX::Field::reCAPTCHA - A Captcha::reCAPTCHA field for HTML::FormHandler

=head1 SYNOPSIS

The following is example usage.

In your L<HTML::FormHandler> subclass, "MyApp::HTML::Forms::MyForm":

    has_field 'recaptcha' => (
        type=>'reCAPTCHA', 
        public_key=>'[YOUR PUBLIC KEY]',
        private_key=>'[YOUR PRIVATE KEY]',
        recaptcha_message => "You're failed to prove your Humanity!",
        required=>1,
    ); 

Example L<Catalyst> controller:

    my $form = MyApp::HTML::Forms::MyForm->new;
    my $params = $c->request->body_parameters;
    if(my $result = $form->process(params=>$params) {
        ## The Form is totally valid. Go ahead with whatever is next.
    } else {
        ## Invalid results, you need to display errors and try again.
    }

=head1 DESCRIPTION

Uses L<Captcha::reCAPTCHA> to add a "Check if the agent is human" field.  You 
will need an account from L<http://recaptcha.net/> to make this work.

This is a thin wrapper on top of L<Captcha::reCAPTCHA> so you should review the
docs for that.  However there's not much too it, just register for an account
over at L<http://recaptcha.net> and use it.

=head1 FIELD OPTIONS

We support the following additional field options, over what is inherited from
L<HTML::FormHandler::Field>

=head2 public_key

The public key you get when you create an account on L<http://recaptcha.net/>

=head2 private_key

The private key you get when you create an account on L<http://recaptcha.net/>

=head2 use_ssl

control the 'use_ssl' option in L<Captcha::reCAPTCHA> when calling 'get_html'.

=head2 recaptcha_options

control the 'options' option in L<Captcha::reCAPTCHA> when calling 'get_html'.

=head2 recaptcha_message

What to show if the recaptcha fails.  Defaults to 'Error validating reCAPTCHA'.
This error message is in addition to any other constraints you add, such as
'required'.

Please note that the recaptcha control also displays an error message internal
to itself.

=head1 FORM METHODS

The following methods or attributes can be set in the form which contains the
recapcha field.

=head2 $name_public_key or $name_private_key

"$name" is the name you gave to the reCAPTCHA field (the word directy after the
"has_field" command.

You may wish to set your public key from a method or attribute contained from
within the form.  This would make it easier to have one form class and use
configuration tools, such as what L<Catalyst> offers, to set the pubic key.
For example:

    ## In my form "MyApp::Form::MyForm
    has ['MY_recaptcha_public_key', 'MY_recapcha_private_key'] => (
        is=>'ro', isa=>'Str', required=>1,
    );
    has_field 'MY_recaptcha' => (
        type=>'reCAPTCHA', 
        recaptcha_message => "You're failed to prove your Humanity!",
        required=>1,
    ); 

Then you might construct this in a L<Catalyst::Controller>:

    my $form = MyApp::Form::MyForm->new(
        MY_recaptcha_public_key => $self->controller_public_key,
        MY_recaptcha_private_key => $self->controller_private_key,
    );

    ## 'process', etc.

Then your controller could populate the attributes 'controller_public_key' and
'controller_private_key' from your global L<Catalyst> configuration, allowing
you to use one set of keys in development and another for production, or even 
use different keys for different forms if you wish.

=head1 SEE ALSO

The following modules or resources may be of interest.

L<HTML::FormHandler>, L<Captch::reCAPTCHA>

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 CONTRIBUTORS

Ferruccio Zamuner (ferz)

=head1 COPYRIGHT & LICENSE

Copyright 2013, John Napiorkowski C<< <jjnapiork@cpan.org> >>

Original work sponsered by Shutterstock, LLC. 
L<http://shutterstock.com>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;
