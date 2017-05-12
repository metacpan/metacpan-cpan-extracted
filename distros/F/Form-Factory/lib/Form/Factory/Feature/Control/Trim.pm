package Form::Factory::Feature::Control::Trim;
$Form::Factory::Feature::Control::Trim::VERSION = '0.022';
use Moose;

with qw( 
    Form::Factory::Feature 
    Form::Factory::Feature::Role::Clean
    Form::Factory::Feature::Role::Control
);

use Carp ();

# ABSTRACT: Trims whitespace from a control value


sub check_control {
    my ($self, $control) = @_;

    return if $control->does('Form::Factory::Control::Role::ScalarValue');

    Carp::croak("the trim feature only works on scalar values, not $control");
}


sub clean {
    my $self    = shift;
    my $control = $self->control;

    my $value   = $control->current_value;
    $value =~ s/^\s*//;
    $value =~ s/\s*$//;

    $control->current_value($value);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Control::Trim - Trims whitespace from a control value

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  has_control title => (
      control => 'text',
      features => {
          trim => 1,
      },
  );

=head1 DESCRIPTION

Strips whitespace from the front and back of the given values.

=head1 METHODS

=head2 check_control

Reports an error unless the control is a scalar value.

=head2 clean

Strips whitespace from the start and end of the control value.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
