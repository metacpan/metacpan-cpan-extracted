package Form::Factory::Feature::Control::Required;
$Form::Factory::Feature::Control::Required::VERSION = '0.022';
use Moose;

with qw( 
    Form::Factory::Feature 
    Form::Factory::Feature::Role::Check
    Form::Factory::Feature::Role::Control
    Form::Factory::Feature::Role::CustomControlMessage
);

use Carp ();

# ABSTRACT: Makes sure a value is set on a control


sub check_control { }


sub check {
    my $self    = shift;
    my $control = $self->control;

    if ($control->has_current_value) {
        $self->result->is_valid(1);
    }

    else {
        $self->control_error('the %s is required');
        $self->result->is_valid(0);
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Control::Required - Makes sure a value is set on a control

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  has_control last_name => (
      control => 'text',
      features => {
          required => 1,
      },
  );

=head1 DESCRIPTION

Reports a check error if the required value is not set. On scalar value controls, it checks that the value has a length greater than zero. On list value controls, it makes sure the list of selected items has more than zero elements.

=head1 METHODS

=head2 check_control

No op.

=head2 check

Reports an error if a scalar value does not have a length greater than 0. Reports an error if a list value has 0 items in the list.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
