package Form::Processor::Field::Email;
$Form::Processor::Field::Email::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Text';
use Email::Valid;




sub init_size {254}    # http://www.rfc-editor.org/errata_search.php?rfc=3696&eid=1690

sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;


    my $email = Email::Valid->address( $self->input );

    return $self->add_error( 'Email should be of the format [_1]', 'someuser@example.com' )
        unless $email;

    $self->input( lc $email );

    return 1;
}


# ABSTRACT: Validates email uisng Email::Valid



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::Email - Validates email uisng Email::Valid

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Validates that the input looks like an email address uisng L<Email::Valid>.

The final email address is the lower case of the output from
L<Email::Valid::address>.

Note:

    0.184 Email::Valid does not check local length limits and
    does not check for max length.  Also, for domains that exceed
    the 255 limit a warning is issued due to a compare with an undefined value.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Field".

=head1 DEPENDENCIES

L<Email::Valid>

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
