package Form::Processor::Field::Password;
$Form::Processor::Field::Password::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Text';

# use Data::Password ();
#


sub init_widget     { return 'password' }
sub init_min_length { return 6 }
sub init_password   { return 1 }



sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    my $value = $self->input;

    return $self->add_error( 'Passwords must not contain spaces' )
        if $value =~ /\s/;

    return $self->add_error( 'Passwords must be made up from letters, digits, or the underscore' )
        if $value =~ /\W/;

    #return $self->add_error( 'Passwords must include one or more digits' )
    #    unless $value =~ /\d/;

    return $self->add_error( 'Passwords must not be all digits' )
        if $value =~ /^\d+$/;




    # This is too strcit.
    # Need to make sure it doesn't match login
    # my $msg = Data::Password::IsBadPassword( $self->input );
    #return $self->SUPER::validate unless $msg;
    #$self->add_error( $msg );

    # So hack it.
    my $params = $self->form->params;

    for ( qw/ login username / ) {
        next if $self->name eq $_;

        return $self->add_error( 'Password must not match ' . $_ )
            if $params->{$_} && $params->{$_} eq $value;
    }

    return 1;


}

sub required_message { return 'Please enter a password in this field' }


# ABSTRACT: Input a password




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::Password - Input a password

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

DEPRECATED -- do not use.  Too restrictive.

The password field validates that the does not contain spaces (\s),
contains only wordcharacters (alphanumeric and underscore \w),
is not all digets, and is at least 6 characters long.

If there is another field called "login" or "username" will validate
that it does not match this field (preventing the same text for both login
and password.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from:

=head1 SUPPORT / WARRANTY

L<Form::Processor> is free software and is provided WITHOUT WARRANTY OF ANY KIND.
Users are expected to review software for fitness and usability.

=head1 AUTHOR

Bill Moseley <mods@hank.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Bill Moseley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
