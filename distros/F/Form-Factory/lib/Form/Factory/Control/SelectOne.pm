package Form::Factory::Control::SelectOne;
$Form::Factory::Control::SelectOne::VERSION = '0.022';
use Moose;

with qw(
    Form::Factory::Control
    Form::Factory::Control::Role::AvailableChoices
    Form::Factory::Control::Role::Labeled
    Form::Factory::Control::Role::ScalarValue
);

# ABSTRACT: A control for selecting a single item


has '+value' => (
    isa       => 'Str',
);

has '+default_value' => (
    isa       => 'Str',
);

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Control::SelectOne - A control for selecting a single item

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  has_control popup_menu => (
      control => 'select_one',
      options => {
          available_choices => [
              Form::Factory::Control::Choice->new('one'),
              Form::Factory::Control::Choice->new('two'),
              Form::Factory::Control::Choice->new('three'),
          ],
          default_value => 'two',
      },
  );

=head1 DESCRIPTION

A select control that allows a single selection. A list of radio buttons or a drop-down box would be appropriate.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
