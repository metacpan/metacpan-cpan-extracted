package Form::Factory::Control::SelectMany;
$Form::Factory::Control::SelectMany::VERSION = '0.022';
use Moose;

with qw(
    Form::Factory::Control
    Form::Factory::Control::Role::AvailableChoices
    Form::Factory::Control::Role::Labeled
    Form::Factory::Control::Role::ListValue
);

use List::MoreUtils qw( any );

# ABSTRACT: the multi-select control


has '+value' => (
    isa       => 'ArrayRef[Str]',
);

has '+default_value' => (
    isa       => 'ArrayRef[Str]',
    default   => sub { [] },
);


sub current_values { shift->current_value(@_) }


sub selected_choices { shift->value(@_) }

sub has_selected_choices { shift->has_value(@_) }


sub default_selected_choices { shift->default_value(@_) }

sub has_default_selected_choices { shift->has_default_value(@_) }


sub is_choice_selected {
    my ($self, $choice) = @_;

    return any { $_ eq $choice->value } @{ $self->current_values };
}


around has_current_value => sub {
    my $next = shift;
    my $self = shift;
    return ($self->has_value || $self->has_default_value) 
        && scalar(@{ $self->current_value }) > 0;
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Control::SelectMany - the multi-select control

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  has_control pick_some => (
      control => 'select_many',
      options => {
          label => 'Just select some of these already...",
          available_choices => [
              Form::Factory::Control::Choice->new('one');
              Form::Factory::Control::Choice->new('two');
              Form::Factory::Control::Choice->new('three');
          ],
          default_selected_choices => [ qw( one three ) ],
      },
  );

=head1 DESCRIPTION

A select many can be displayed as a multi-select list box or a list of checkboxes.

This control implements L<Form::Factory::Control>, L<Form::Factory::Control::Role::AvailableChoices>, L<Form::Factory::Control::Role::Labeled>, L<Form::Factory::Control::Role::ListValue>.

=head1 METHODS

=head2 current_values

This is a synonym for C<current_value>.

=head2 selected_choices

This is a synonym for C<value>.

=head2 has_selected_choices

This is a synonyms for C<has_selected_choices>.

=head2 default_selected_choices

This is a synonym for C<default_value>.

=head2 has_default_selected_choices

This is a synonym for C<has_default_selected_choices>.

=head2 is_choice_selected

  for my $choice (@{ $self->available_choices }) {
      if ($control->is_choice_selected($choice)) {
          # ...
      }
  }

This is a helper that is useful while iterating over the available choices in deciding which have been selected.

=head2 has_current_value

It has a current value if one or more values are selected.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
