package Form::Factory::Control::Text;
$Form::Factory::Control::Text::VERSION = '0.022';
use Moose;

with qw( 
    Form::Factory::Control 
    Form::Factory::Control::Role::Labeled
    Form::Factory::Control::Role::ScalarValue
);

# ABSTRACT: A single line text field


has '+value' => (
    isa       => 'Str',
);

has '+default_value' => (
    isa       => 'Str',
    default   => '',
);


around has_current_value => sub {
    my $next = shift;
    my $self = shift;

    return ($self->has_value || $self->has_default_value)
        && length($self->current_value) > 0;
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Control::Text - A single line text field

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  has_control your_name => (
      control => 'text',
      options => {
          label         => 'Your Real Name',
          default_value => 'Thomas Anderson',
      },
  );

=head1 DESCRIPTION

A regular text box.

This control implements L<Form::Factory::Control>, L<Form::Factory::Control::Role::Labeled>, and L<Form::Factory::Control::Role::ScalarValue>.

=head1 METHODS

=head2 has_current_value

We have a current value if it is defined and has a non-zero string length.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
