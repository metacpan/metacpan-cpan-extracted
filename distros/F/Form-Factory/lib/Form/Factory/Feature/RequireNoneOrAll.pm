package Form::Factory::Feature::RequireNoneOrAll;
$Form::Factory::Feature::RequireNoneOrAll::VERSION = '0.022';
use Moose;

use Moose::Util qw( english_list );

with qw(
    Form::Factory::Feature
    Form::Factory::Feature::Role::Check
);

use Carp ();

# ABSTRACT: if one control has a value, all should


has groups => (
    is        => 'ro',
    isa       => 'HashRef[ArrayRef[Str]]',
    required  => 1,
);


sub check {
    my $self   = shift;
    my $action = $self->action;

    GROUP: for my $control_names (values %{ $self->groups }) {
        my $has_a_value    = 0;
        my $has_all_values = 1;
        my $valued_control;

        CONTROL: for my $name (@$control_names) {
            my $control = $action->controls->{$name};

            my $has_current_value = $control->has_current_value;
            $has_a_value        ||= $has_current_value;
            $has_all_values     &&= $has_current_value;

            $valued_control = $name if $has_current_value;

            if ($has_a_value and not $has_all_values) {
                $self->result->is_valid(0);
                $self->result->error(
                    sprintf('if you enter a value in %s you must enter a value for %s',
                       $self->_control_label($valued_control), 
                       english_list(map { $self->_control_label($_) } @$control_names),
                    )
                );
                next GROUP;
            }
        }
    }

    $self->result->is_valid(1) unless $self->result->is_validated;
}

sub _control_label {
    my ($self, $name) = @_;
    my $control = $self->action->controls->{$name};

    my $control_label 
        = $control->does('Form::Factory::Control::Role::Labeled') ? $control->label
        :                                                           $control->name
        ;

    return $control_label;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::RequireNoneOrAll - if one control has a value, all should

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Action::Foo;
  use Form::Factory::Processor;

  use_feature require_none_or_all => {
      groups => { 
          password => [ qw( 
              old_password 
              new_password 
              confirm_password 
          ) ],
      },
  };

  has_control old_password => (
      control  => 'password',
      prediate => 'has_old_password',
  );

  has_control new_password => (
      control => 'password',
  );

  has_control confirm_password => (
      control => 'password',
  );

  sub run {
      my $self = shift;

      if ($self->has_old_password) {
          # change password, we know new_password and confirm_password are set
      }
  }

=head1 DESCRIPTION

This feature allows you to make groups of controls work together. If any one of the named controls have a value when checked, then all of them must or the form will be invalid and an error will be displayed.

=head1 ATTRIBUTES

=head2 groups

This is how the control groups are configured. Each key is used to name a control group and the values are arrays of controls that are grouped together. This way more than one none-or-all requirement can be set on a given form.

At this time, the control group names are ignored, but might be used in the future for linking additional settings together.

=head1 METHODS

=head2 check

This runs the checks to make sure that for each group of controls, either all have a value or none do.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
