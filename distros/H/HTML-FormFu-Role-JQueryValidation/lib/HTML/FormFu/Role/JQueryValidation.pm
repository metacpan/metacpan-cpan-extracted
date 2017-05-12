package HTML::FormFu::Role::JQueryValidation;
{
  $HTML::FormFu::Role::JQueryValidation::VERSION = '1.01';
}
use Moose::Role;

use JSON::Any;
use Scalar::Util qw( refaddr reftype );

sub jquery_validation_profile {
    my ( $self ) = @_;

    my %js = (
        rules    => {},
        messages => {},
    );

    for my $field ( @{ $self->get_fields } ) {

        my $name        = $field->nested_name;
        my $constraints = $field->get_constraints;

        if ( $field->can('field_type') && 'url' eq $field->field_type ) {
            $js{rules}{$name}{url} = 1;

            my @regex =
                grep { 'URI' eq $_->common->[0] }
                grep { 'ARRAY' eq reftype $_->common }
                grep { $_->common }
                grep { 'Regex' eq $_->type }
                    @$constraints;

            if ( 1 == @regex ) {
                $js{messages}{$name}{url} = $regex[0]->fetch_error_message;
            }
        }

        for my $constraint ( @$constraints ) {
            my $type = $constraint->type;

            if ( 'Required' eq $type ) {
                $js{rules}{$name}{required}    = 1;
                $js{messages}{$name}{required} = $constraint->fetch_error_message;
            }
            elsif ( 'Email' eq $type ) {
                $js{rules}{$name}{email}    = 1;
                $js{messages}{$name}{email} = $constraint->fetch_error_message;
            }
            elsif ( 'Integer' eq $type ) {
                $js{rules}{$name}{digits}    = 1;
                $js{messages}{$name}{digits} = $constraint->fetch_error_message;
            }
            elsif ( 'Length' eq $type ) {
                $js{rules}{$name}{rangelength}    = [ $constraint->min, $constraint->max ];
                $js{messages}{$name}{rangelength} = $constraint->fetch_error_message;
            }
            elsif ( 'MaxLength' eq $type ) {
                $js{rules}{$name}{maxlength}    = $constraint->max;
                $js{messages}{$name}{maxlength} = $constraint->fetch_error_message;
            }
            elsif ( 'MinLength' eq $type ) {
                $js{rules}{$name}{minlength}    = $constraint->min;
                $js{messages}{$name}{minlength} = $constraint->fetch_error_message;
            }
            elsif ( 'MaxRange' eq $type ) {
                $js{rules}{$name}{max}    = $constraint->max;
                $js{messages}{$name}{max} = $constraint->fetch_error_message;
            }
            elsif ( 'MinRange' eq $type ) {
                $js{rules}{$name}{min}    = $constraint->min;
                $js{messages}{$name}{min} = $constraint->fetch_error_message;
            }
            elsif ( 'Number' eq $type ) {
                $js{rules}{$name}{number}    = 1;
                $js{messages}{$name}{number} = $constraint->fetch_error_message;
            }
            elsif ( 'Range' eq $type ) {
                $js{rules}{$name}{range}    = [ $constraint->min, $constraint->max ];
                $js{messages}{$name}{range} = $constraint->fetch_error_message;
            }
        }
    }

    return \%js;
}

sub jquery_validation_json {
    my ( $self ) = @_;

    return JSON::Any->objToJson( $self->jquery_validation_profile );
}

sub jquery_validation_errors {
    my ( $self )= @_;

    my %message;

    for my $error (@{ $self->get_errors }) {
        my $name = $error->parent->nested_name;
        $message{$name} ||= [];
        push @{ $message{$name} }, $error->message;
    }

    return \%message;
}

sub jquery_validation_errors_join {
    my $self = shift;

    my $errors = $self->jquery_validation_errors;

    for my $name ( keys %$errors ) {
        if ( 2 == @_ ) {
            $errors->{$name} =
                join '',
                map {
                    $_[0] . $_ . $_[1]
                } @{ $errors->{$name} };
        }
        else {
            my $str = ( @_ && defined $_[0] ) ? $_[0]
                    :                           "";

            $errors->{$name} = join $str, @{ $errors->{$name} };
        }
    }

    return $errors;
}

1;

__END__

=head1 NAME

HTML::FormFu::Role::JQueryValidation - Client-side JS constraints

=head1 SYNOPSIS

    $form->roles('JQueryValidation');

In your L<TT|Template> template:

    <!DOCTYPE HTML>
    <html>
    <body>
        [% form %]
        
        <script src="//js/jquery.min.js" />
        <script src="//js/jquery.validate.min.js" />
        <script>
            $("#form").validate( [% form.jquery_validation_json %] );
        </script>
    </body>
    </html>

=head1 DESCRIPTION

Experimental support for client-side constraints with JQuery Validation
L<http://jqueryvalidation.org>.

=head1 CONSTRAINTS

Adds constraints for the following elements:

=over

=item L<HTML::FormFu::Element::Email>

=item L<HTML::FormFu::Element::URL>

=back

Supports the following constraints on any element:

=over

=item L<HTML::FormFu::Constraint::Email>

=item L<HTML::FormFu::Constraint::Integer>

=item L<HTML::FormFu::Constraint::Length>

=item L<HTML::FormFu::Constraint::MaxLength>

=item L<HTML::FormFu::Constraint::MinLength>

=item L<HTML::FormFu::Constraint::MaxRange>

=item L<HTML::FormFu::Constraint::MinRange>

=item L<HTML::FormFu::Constraint::Number>

=item L<HTML::FormFu::Constraint::Range>

=item L<HTML::FormFu::Constraint::Required>

=back

=head1 METHODS

=head2 jquery_validation_profile

Returns a hash-ref with C<rules> and C<messages> keys.

=head2 jquery_validation_json

Returns L<jquery_validation_profile|/jquery_validation_profile> passed through
L<JSON::Any/objToJson>.

=head2 jquery_validation_errors

Returns a hash-ref whose keys are field names with errors, and values are
arrayrefs of error messages.

=head2 jquery_validation_errors_join

Arguments: $join_string

Arguments: $start_string, $end_string

Processes the return value of
L<jquery_validation_errors|/jquery_validation_errors>, changing each arrayref
of error messages into a single string.

Given 1 argument, it is used as a separator to join the error messages.
Given 2 arguments, they are used to start and end each messages.

Example: if L<jquery_validation_errors|/jquery_validation_errors> returned
the following:

    {
        foo => [
            'Error 1',
            'Error 2',
        ],
    }

    # jquery_validation_errors_join( "<br/>" )
    # outputs
    {
        foo => "Error 1<br/>Error 2"
    }

    # jquery_validation_errors_join( "<li>", "</li>" )
    # outputs
    {
        foo => "<li>Error 1</li><li>Error 2</li>"
    }

=head1 SEE ALSO

L<HTML::FormFu>

L<http://jqueryvalidation.org>

=head1 AUTHORS

Carl Franks

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
