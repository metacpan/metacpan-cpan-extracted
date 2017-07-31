package HTML::FormHandler::Field::PasswordConf;
# ABSTRACT: password confirmation
$HTML::FormHandler::Field::PasswordConf::VERSION = '0.40068';
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';


has '+widget'           => ( default => 'Password' );
has '+password'         => ( default => 1 );
has '+required'         => ( default => 1 );
has 'password_field'    => ( isa     => 'Str', is => 'rw', default => 'password' );
has 'pass_conf_message' => ( isa     => 'Str', is      => 'rw' );

our $class_messages = {
    required => 'Please enter a password confirmation',
    pass_conf_not_matched => 'The password confirmation does not match the password',
};

sub get_class_messages  {
    my $self = shift;
    my $messages = {
        %{ $self->next::method },
        %$class_messages,
    };
    $messages->{pass_conf_not_matched} = $self->pass_conf_message
        if $self->pass_conf_message;
    return $messages;
}


sub validate {
    my $self = shift;

    my $value    = $self->value;
    my $password = $self->form->field( $self->password_field )->value || '';
    if ( $password ne $self->value ) {
        $self->add_error( $self->get_message('pass_conf_not_matched') );
        return;
    }
    return 1;
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::PasswordConf - password confirmation

=head1 VERSION

version 0.40068

=head1 DESCRIPTION

This field needs to be declared after the related Password field (or more
precisely it needs to come after the Password field in the list returned by
the L<HTML::FormHandler/fields> method).

=head2 password_field

Set this attribute to the name of your password field (default 'password')

Customize error message 'pass_conf_not_matched' or 'required'

    has_field '_password' => ( type => 'PasswordConf',
         messages => { required => 'You must enter the password a second time' },
    );

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
