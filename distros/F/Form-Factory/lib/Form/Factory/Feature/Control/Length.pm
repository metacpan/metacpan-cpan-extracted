package Form::Factory::Feature::Control::Length;
$Form::Factory::Feature::Control::Length::VERSION = '0.022';
use Moose;

with qw( 
    Form::Factory::Feature 
    Form::Factory::Feature::Role::Check
    Form::Factory::Feature::Role::Control
    Form::Factory::Feature::Role::CustomControlMessage
);

use Carp ();

# ABSTRACT: A control feature for checking length


has minimum => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_minimum',
);


has maximum => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_maximum',
);

sub BUILDARGS {
    my $class = shift;
    my $args  = @_ == 1 ? $_[0] : { @_ };

    if (defined $args->{minimum} and defined $args->{maximum}
            and $args->{minimum} >= $args->{maximum}) {
        Carp::croak('length minimum must be less than maximum');
    }

    return $class->SUPER::BUILDARGS(@_);
}


sub check_control {
    my ($self, $control) = @_;

    return if $control->does('Form::Factory::Control::Role::ScalarValue');

    Carp::croak("the length feature only works with scalar values\n");
}


sub check {
    my $self  = shift;
    my $value = $self->control->current_value;

    return if length($value) == 0;

    if ($self->has_minimum and length($value) < $self->minimum) {
        $self->control_error(
            "the %s must be at least @{[$self->minimum]} characters long"
        );
        $self->result->is_valid(0);
    }

    if ($self->has_maximum and length($value) > $self->maximum) {
        $self->control_error(
            "the %s must be no longer than @{[$self->maximum]} characters"
        );
        $self->result->is_valid(0);
    }

    $self->result->is_valid(1) unless $self->result->is_validated;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Control::Length - A control feature for checking length

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  has_control login_name => (
      control => 'text',
      feature => {
          length => {
              minimum => 3,
              maximum => 15,
          },
      },
  );

=head1 DESCRIPTION

Linked to a control, it checks to see that the string is not too short or too long.

=head1 ATTRIBUTES

=head2 minumum

The optional minimum length permitted for the string.

=head2 maximum

The optional maximum length permitted for the string.

=head1 METHODS

=head2 check_control

Makes sure the value is a L<Form::Factory::Control::Role::ScalarValue>.

=head2 check

Verifies that the value of the control is not too short or too long.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
