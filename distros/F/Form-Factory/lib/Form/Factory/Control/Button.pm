package Form::Factory::Control::Button;
$Form::Factory::Control::Button::VERSION = '0.022';
use Moose;

with qw(
    Form::Factory::Control
    Form::Factory::Control::Role::BooleanValue
    Form::Factory::Control::Role::Labeled
);

# ABSTRACT: The button control


has '+value' => (
    isa       => 'Str',
);

has '+default_value' => (
    isa       => 'Str',
    lazy      => 1,
    default   => sub { shift->label },
);


has '+true_value' => (
    lazy      => 1,
    default   => sub { shift->label },
);


use constant default_isa => 'Str';

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Control::Button - The button control

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  has_control a_button => (
      control => 'button',
      options => {
          label => 'My Button',
      },
  );

=head1 DESCRIPTION

A control representing a submit button. This control implements L<Form::Factory::Control>, L<Form::Factory::Control::Role::BooleanValue>, L<Form::Factory::Control::Role::Labeled>, L<Form::Factory::Control::Role::ScalarValue>.

=head1 ATTRIBUTES

=head2 true_value

See L<Form::Factory::Control::Role::BooleanValue>. By default, this value is set
to the label. If you change this to something else, the button might not work
correctly anymore.

=head1 METHODS

=head2 default_isa

Boolean values default to C<Bool>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
