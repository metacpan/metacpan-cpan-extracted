package Form::Factory::Control::Checkbox;
$Form::Factory::Control::Checkbox::VERSION = '0.022';
use Moose;

with qw(
    Form::Factory::Control
    Form::Factory::Control::Role::BooleanValue
    Form::Factory::Control::Role::Labeled
);

# ABSTRACT: the checkbox control


has '+value' => (
    isa       => 'Str',
);

has '+default_value' => (
    isa       => 'Str',
    lazy      => 1,
    default   => sub { shift->false_value },
);


use constant default_isa => 'Str';

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Control::Checkbox - the checkbox control

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  has_control yes_no_box => (
      control => 'checkbox',
      options => {
          true_value  => 'Yes',
          false_value => 'No',
          is_true     => 1,
      },
  );

=head1 DESCRIPTION

This represents a toggle button, typically displayed as a checkbox. This control implements L<Form::Factory::Control>, L<Form::Factory::Control::Role::BooleanValue>, L<Form::Factory::Control::Role::Labeled>, L<Form::Factory::Control::Role::ScalarValue>.

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
