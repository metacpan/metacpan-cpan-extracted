package Form::Factory::Control::Role::BooleanValue;
$Form::Factory::Control::Role::BooleanValue::VERSION = '0.022';
use Moose::Role;

excludes qw(
    Form::Factory::Control::Role::ListValue
    Form::Factory::Control::Role::ScalarValue
);

# ABSTRACT: boolean valued controls


has true_value => (
    is        => 'ro',
    required  => 1,
    default   => 1,
);


has false_value => (
    is        => 'ro',
    required  => 1,
    default   => '',
);


sub _is_it_true {
    my ($self, $value) = @_;

    # blow off these warnings rather than test for them
    no warnings 'uninitialized'; 

    return 1  if $value eq $self->true_value;
    return '' if $value eq $self->false_value;
    return scalar undef;
}

sub is_currently_true {
    my $self = shift;

    if (@_) {
        my $is_true = shift;
        $self->current_value($is_true ? $self->true_value : $self->false_value);
    }

    return $self->_is_it_true($self->value)         if $self->has_value;
    return $self->_is_it_true($self->default_value) if $self->has_default_value;
    return scalar undef;
}


sub is_true {
    my $self = shift;
    return $self->_is_it_true($self->value);
}


around current_value => sub {
    my $next  = shift;
    my $self  = shift;
    my $truth = $self->is_currently_true;

    $self->value(@_) if @_;

    if ($truth) {
        return $self->true_value;
    }
    elsif (defined $truth) {
        return $self->false_value;
    }
    else {
        return scalar undef;
    }
};


around has_current_value => sub {
    my $next = shift;
    my $self = shift;
    return defined $self->is_currently_true;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Control::Role::BooleanValue - boolean valued controls

=head1 VERSION

version 0.022

=head1 DESCRIPTION

Controls that implement this role have a boolean value. This say much about how that is actually implemented, just that is has a L</true_value> a L</false_value> and then a flag stating whether the true value or false value is currently selected.

=head1 ATTRIBUTES

=head2 true_value

The string value the control should have when the control L</is_true>.

=head2 false_value

The string value the control should have when the control is not L</is_true>.

=head1 METHODS

=head2 is_currently_true

Returns a true value when the C<current_value> is set to L</true_value> or a false value when the C<current_value> is set to L</false_value>.

This method returns C<undef> if it is neither true nor false.

If passed a value, e.g.:

  $self->is_currently_true(1);

This will set the C<current_value>. If a true value is given, the C<value> will be set to L</true_value>. Otherwise, it will cause the C<current_value> to take on the contents of L</false_value>.

=head2 is_true

Returns a true value when the C<value> is set to L</true_value> or a false value when the C<value> is set to L</false_value>.

This method returns C<undef> if it is neither true nor false.

Unlikely L</is_currently_true>, this may not be used as a setter.

=head2 current_value

We need to handle current value special.

=head2 has_current_value

If the value is true or false, it has a current value. Otherwise, it does not.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
