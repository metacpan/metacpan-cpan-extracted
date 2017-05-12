package Form::Sensible::Field::DateTime;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use DateTime::Format::Natural;
use DateTime::Span;
use Form::Sensible::DelegateConnection;
extends 'Form::Sensible::Field';

coerce 'CodeRef' => from 'Str' => via \&_string_to_code_recurrence;

has '+value_delegate' => (
    default     => sub {
        my $self = shift;
        my $value = _validate_datetime( $self->default_value );
        my $sub =  sub {
            my $caller = shift;
            if ( @_ ) {
                my $valid = _validate_datetime($_[0]);
                $value = $valid if defined $valid;
            }
            return $value;
        };
        return FSConnector($sub);
    },
);

has 'recurrence' => (
    is          => 'rw',
    isa         => 'CodeRef',
    required    => 0,
    coerce      => 1,
);

has 'span' => (
    is          => 'rw',
    isa         => 'DateTime::Span',
    required    => 0,
);

sub _validate_datetime {
    my $value = shift;

    return if ! defined $value;
    return $value if 'DateTime' eq ref $value;

    my $parser = DateTime::Format::Natural->new;
    my $date_string = $parser->extract_datetime( $value );

    if ( $date_string ) {
        my $dt = $parser->parse_datetime( $date_string );
        return $dt if $parser->success;
    }

    return;
}

around 'validate' => sub {
    my $orig = shift;
    my $self = shift;

    my @errors;
    push @errors, $self->$orig(@_);

    my $span_error = $self->_validate_span;
    push @errors, $span_error if length $span_error;

    return @errors;
};

sub _string_to_code_recurrence {
    my %recurrence;
    %recurrence = (
        yearly => sub {
            return $_[0] if $_[0]->is_infinite;
            return $_[0]->truncate( to => 'year' )->add( years => 1 );
        },
        by_year => $recurrence{'yearly'},
        monthly => sub {
            return $_[0] if $_[0]->is_infinite;
            return $_[0]->truncate( to => 'month' )->add( months => 1 );
        },
        by_month => $recurrence{'monthly'},
        daily => sub {
            return $_[0] if $_[0]->is_infinite;
            return $_[0]->truncate( to => 'day' )->add( days => 1 );
        },
        by_day => $recurrence{'daily'},
        '_DEFAULT' => sub { },
    );
    return $recurrence{$_} if exists $recurrence{$_};
    return $recurrence{'_DEFAULT'};
}

sub _validate_span {
    my ( $self ) = @_;

    return if ref($self->value) ne 'DateTime' || ! $self->span;

    my ($span, $recurrence ) = ( $self->span, $self->recurrence );

    if ( $recurrence ) {
        $span = DateTime::Set->from_recurrence(
            span => $span, recurrence => $recurrence,
        );
    }

    if ( ! $span->contains( $self->value ) ) {
        my $format = '_FIELDNAME_ (%s) is not between %s and %s';
        $format .= ' OR not a valid recurrence within that span'
            if ! $recurrence;
        return sprintf $format, $self->value, $span->min, $span->max;
    }
    return;
}

sub set_selection {
    my ( $self ) = @_;
    return $self->value;
}

sub get_options {
    my ($self, $recurrence ) = @_;

    my $options = [ { name => $self->value, value => $self->value } ];
    $recurrence ||= $self->recurrence;
    if ( defined $self->span && defined $recurrence ) {
        my $dates = DateTime::Set->from_recurrence(
            span => $self->span, recurrence => $recurrence,
        );
        my @dates = grep { defined } $dates->as_list;
        $options = [ map { { name => $_, value => $_ } } @dates ] if @dates;
    }
    return $options;
}

sub accepts_multiple {
    my ($self) = @_;

    return 0;
}

sub get_additional_configuration {
    my $self = shift;

    return { map { defined ($self->$_) ? ( $_ => $self->$_ ) : () }
             qw/span recurrence/ };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible::Field::DateTime - A DateTime field type.

=head1 SYNOPSIS

    use Form::Sensible::Field::DateTime;
    
    my $object = Form::Sensible::Field::DateTime->new(
                    span => datetime_span_object,
                    recurrence => $recurrence_sub,
    );

    $object->do_stuff();

    my $object2 = Form::Sensible::Field::DateTime->new(
                    span => datetime_span_object,
                    recurrence => 'hourly',
    );

    $object2->do_stuff();

=head1 DESCRIPTION

The datetime field type is one of the more advanced field types in
Form::Sensible. It uses DateTime::Format::Natural to format user input into a
valid DateTime object, and uses DateTime::Set to allow date range
numbers.  It can be set to have a lower and upper bound, allowing validation
to ensure that the value selected is within a range.

Finally, it can be rendered in a number of ways including select boxes, drop
downs or even ranged-sliders if your renderer supports it. It can have a
'recurrence', which provides a constraint to what values are valid between the
datetime span, otherwise it just returns the DateTime value set for the field.


=head1 ATTRIBUTES

=over 8

=item C<recurrence>

A  subroutine that is used when this field is used as a Select field. See the
C<from_recurrence> method in L<DateTime::Set|DateTime::Set/"METHODS"> for more
information on how you might structure the subroutine. Only useful when
C<span> is defined. As a convenience, if you pass the following strings, they
will DWYM:

=over 4

=item yearly

=item by_year

=item monthly

=item by_month

=item daily

=item by_day

=back

=item C<span>

A L<DateTime::Span> object that is used to represent the valid date range for
this field.

=head1 METHODS

=over 8

=item C<validate>

Validates the field against the numeric constraints set for the field.

=item C<get_additional_configuration>

Returns a hashref consisting of the attributes for this field and their
values.

=back

The following two methods allow DateTime fields to be treated like Select
Fields for rendering purposes.

=over 8

=item C<get_options()>

An array ref containing the allowed options. Each option is represented as a
hash containing a C<name> element and a C<value> element for the given option.

=item C<set_selection()>

Sets whatever is the current C<< $self->value >> option as the selected option
selected. This is used when a C<DateTime> field is used as a C<Select> field
and overrides L<Select|Form::Sensible::Field::Select/"METHODS">'s
C<set_selection> method.

=item C<accepts_multiple>

On a Select field, this defines whether the field can have multiple values.  For
a DateTime field, only one value is allowed, so this always returns false.

=back

=head1 AUTHOR

David Romano - E<lt>unobe@cpan.orgE<gt>

=head1 SPONSORED BY

Ionzero LLC. L<http://ionzero.com/>

=head1 SEE ALSO

L<Form::Sensible>

=head1 LICENSE

Copyright (c) 2012 by Ionzero LLC

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

