package Form::Sensible::Field::Number;

use Moose;
use namespace::autoclean;
extends 'Form::Sensible::Field';

has 'integer_only' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

has 'lower_bound' => (
    is          => 'rw',
    isa         => 'Num',
    required    => 0,
);

has 'upper_bound' => (
    is          => 'rw',
    isa         => 'Num',
    required    => 0,
);

has 'step' => (
    is          => 'rw',
    isa         => 'Num',
    required    => 0,
);


around 'validate' => sub {
    my $orig = shift;
    my $self = shift;

    my @errors;
    push @errors, $self->$orig(@_);

    my $regex = qr/^[-+]?                   # Sign
                    (?: [0-9]+              # Integer portion
                        (?: \. [0-9]* )?    # Fractional portion
                    |   \. [0-9]+           # Just a decimal
                    )
                    $/xms;

    if (defined($self->validation->{'regex'})) {
        $regex = $self->validation->{'regex'};
        if (ref($regex) ne 'Regexp') {
            $regex = qr/$regex/;
        }
    }

    if ($self->value !~ $regex ) {
        push @errors, "_FIELDNAME_ is not a number";
    }

    if (defined($self->lower_bound) && $self->value < $self->lower_bound) {
        push @errors, "_FIELDNAME_ is lower than the minimum allowed value";
    }
    if (defined($self->upper_bound) && $self->value > $self->upper_bound) {
        push @errors, "_FIELDNAME_ is higher than the maximum allowed value";
    }

    if ( $self->integer_only && $self->value != int($self->value)) {
        push @errors, "_FIELDNAME_ must be an integer.";
    }

    ## we ran the gauntlet last check is to see if value is in step.
    if (defined($self->step) && !$self->in_step()) {
        push @errors, "_FIELDNAME_ must be a multiple of " . $self->step;
    }
    return @errors;
};


## this is used when generating a slider or select of valid values.
sub get_potential_values {
    my ($self, $step, $lower_bound, $upper_bound) = @_;

    if (!$step) {
        $step = $self->step || 1;
    }
    if (!defined($lower_bound) && defined $self->lower_bound ) {
        $lower_bound = $self->lower_bound;
    }
    if (!defined($upper_bound) && defined $self->upper_bound ) {
        $upper_bound = $self->upper_bound;
    }

    # If either the lower or upper bound is not set, no potential values
    return if ! defined $upper_bound || ! defined $lower_bound;

    my $value = $lower_bound;

    ## this check ensures that we start with a value that is within our
    ## bounds.  If $self->lower_bound does not lie on a step boundary,
    ## and we generated all our numbers from lower_bound, we would be
    ## producing a bunch of options that were always invalid.
    ## Technically speaking, we shouldn't have a lower bound that is invalid
    ## but who are we kidding?  It will happen.

    if (!$self->in_step($value, $step)) {
        # lower bound doesn't lie on a step boundary.  Bump $div by 1 and
        # multiply by step.  Should be the first value that lies above our
        # provided bound.
        my $div = $value / $step;

        $value = (int($div)+1) * $step;
    }

    my @vals;
    while ($value <= $upper_bound) {
        push @vals, $value;
        $value += $step;
    }
    return @vals;
}

## this allows a Number to behave like a Select if used that way.
sub get_options {
    my ($self) = @_;

    my @values = $self->get_potential_values();
    return [ map { { name => $_, value => $_ } } @values ] if @values;
    return $self->value;
}

sub accepts_multiple {
    my ($self) = @_;

    return 0;
}

sub in_step {
    my ($self, $value, $step) = @_;

    if (!$step) {
        $step = $self->step || 1;
    }
    if (!defined($value)) {
        $value = $self->value;
    }

    ## we have to do the step check this way, because % will not deal with
    ## a fractional step value.
    my $div = $value / $step;
    return ($div == int($div));

}

sub get_additional_configuration {
    my $self = shift;

    return { map { defined ($self->$_) ? ( $_ => $self->$_ ) : () }
            qw/step lower_bound upper_bound integer_only/
        };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible::Field::Number - A Numeric field type.

=head1 SYNOPSIS

    use Form::Sensible::Field::Number;
    
    my $object = Form::Sensible::Field::Number->new(
                                                        integer_only => 1,
                                                        lower_bound => 10,
                                                        upper_bound => 100,
                                                        step => 5,
                                                    );

    $object->do_stuff();

=head1 DESCRIPTION

The number field type is one of the more advanced field types in
Form::Sensible. It has a number of features for dealing specifically with
numbers.  It can be set to have a lower and upper bound, allowing validation
to ensure that the value selected is within a range.  It can also be set to
have a 'step', which provides a constraint to what values are valid between
the upper and lower bounds.  It can also be made to accept integers only, or
fractional values.

Finally, it can be rendered in a number of ways including select boxes, drop
downs or even ranged-sliders if your renderer supports it.

=head1 ATTRIBUTES

=over 8

=item C<integer_only>

True/false value indicating whether this field is able to accept fractional
values. Required attribute.

=item C<lower_bound>

Lower bound of valid values for the field.

=item C<upper_bound>

Upper bound of valid values for the field.

=item C<step>

When step is provided, the value provided must be a multiple of C<step> in
order to be valid.

=back

=head1 METHODS

=over 8

=item C<validate>

Validates the field against the numeric constraints set for the field.

=item C<get_potential_values($step, $lower_bound, $upper_bound)>

Returns an array containing all the valid values between the
upper and lower bound.  Used internally to the number field.


=item C<in_step($value, $step)>

Returns true if $value lies on a $step boundary. Otherwise returns false.

=item C<get_additional_configuration>

Returns a hashref consisting of the attributes for this field and their
values.

=back

The following two methods allow Number fields to be treated like Select
Fields for rendering purposes.

=over 8

=item C<get_options>

An array ref containing the allowed options. Each option is represented as a
hash containing a C<name> element and a C<value> element for the given option.

=item C<accepts_multiple>

On a Select field, this defines whether the field can have multiple values.  For
a Number field, only one value is allowed, so this always returns false.


=back

=head1 VALIDATION OPTIONS

=over 8

=item C<regex>

The number field type by default checks that what was passed looks like a
number based on the following regex:

    qr/^[-+]?                   # Sign
        (?: [0-9]+              # Integer portion ...
            (?: \. [0-9]* )?    # Fractional portion
        |   \. [0-9]+           # Just a decimal
        )
      $/xms

This will handle most numbers you are likely to encounter. However, if this
regex is insufficient, such as when you need to process numbers in exponential
notation, you can provide a replacement regex in the field's 'validation'
hash:

    my $object = Form::Sensible::Field::Number->new(
                                                    validation => {
                                                        # allow exponential notation
                                                        regex => qr/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/,
                                                    }
                                                );

Note that the Number validation routines outlined above are not built to
handle numbers perl can not handle natively. That is to say, if you are
working with numbers that perl can not parse, or that require you to use
modules such as L<Math::BigInt>, you can still use the Number class, but it's
best to avoid Number's builtin validation. You can perform your validation
yourself in a C<code> validation block or by subclassing Form::Sensible's
Number or Text field classes.

=back

=head1 AUTHOR

Jay Kuri - E<lt>jayk@cpan.orgE<gt>

=head1 SPONSORED BY

Ionzero LLC. L<http://ionzero.com/>

=head1 SEE ALSO

L<Form::Sensible>

=head1 LICENSE

Copyright 2009 by Jay Kuri E<lt>jayk@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

