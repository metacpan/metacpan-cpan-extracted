package Form::Sensible::Field::Text;

use Moose;
use namespace::autoclean;
extends 'Form::Sensible::Field';

## provides a plain text field

has 'maximum_length' => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 256,
);

has 'minimum_length' => (
    is          => 'rw',
    isa         => 'Int',
    required    => 0,
);

has 'should_truncate' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

## does truncation if should_truncate is set.
around 'value' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig() if ! @_;

    my $value = shift;
    if ($self->should_truncate) {
        return $self->$orig(substr($value,0,$self->maximum_length));
    }
    return $self->$orig($value);
};

sub get_additional_configuration {
    my ($self) = @_;

    return { map { defined( $self->$_ ) ? ( $_ => $self->$_ ) : () }
            qw/maximum_length minimum_length should_truncate/
           };
}

around 'validate' => sub {
    my $orig = shift;
    my $self = shift;

    my @errors;
    push @errors, $self->$orig(@_);
    if (length($self->value) > $self->maximum_length) {
        push @errors, "_FIELDNAME_ is too long";
    }
    if ($self->minimum_length && (length($self->value) < $self->minimum_length)) {
        push @errors, "_FIELDNAME_ is too short";
    }

    return @errors;
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible::Field::Text - Field for representing character-strings

=head1 SYNOPSIS

    use Form::Sensible::Field::Text;
    
    my $textfield = Form::Sensible::Field::Text->new(
                                                    name => 'username',
                                                    maximum_length => 16,
                                                    minimum_length => 6,
                                                    should_truncate => 0
                                                  );


=head1 DESCRIPTION

Form::Sensible::Field subclass for representing character-string based data.

=head1 ATTRIBUTES

=over 8

=item C<maximum_length>

The maximum length this text field should accept. Note that any size of string
can be placed in the field, it will simply fail validation if it is too large.
Alternately if C<should_truncate> is true, the value will be truncated when it
is set.

=item C<minimum_length>

The minimum length this text field should accept. If defined, validation will
fail if the field value is less than this.

=item C<should_truncate>

Indicates that if value is set to a string larger than C<maximum_length>, it
should be automatically truncated to C<maximum_length>. This has to be
manually turned on, by default C<should_truncate> is false.

=back

=head1 METHODS

=over 8

=item C<get_additional_configuration()>

Returns the attributes' names and values as a hash ref.

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
