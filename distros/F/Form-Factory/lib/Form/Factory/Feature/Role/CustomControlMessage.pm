package Form::Factory::Feature::Role::CustomControlMessage;
$Form::Factory::Feature::Role::CustomControlMessage::VERSION = '0.022';
use Moose::Role;

with qw( Form::Factory::Feature::Role::CustomMessage );

# ABSTRACT: control features with custom messages


sub format_message {
    my $self    = shift;
    my $message = $self->message || shift;
    my $control = $self->control;

    my $control_label 
        = $control->does('Form::Factory::Control::Role::Labeled') ? $control->label
        :                                                           $control->name
        ;

    sprintf $message, $control_label;
}


sub control_info {
    my $self    = shift;
    my $message = $self->format_message(shift);
    $self->result->field_info($self->control->name, $message);
}


sub control_warning {
    my $self = shift;
    my $message = $self->format_message(shift);
    $self->result->field_warning($self->control->name, $message);
}


sub control_error {
    my $self = shift;
    my $message = $self->format_message(shift);
    $self->result->field_error($self->control->name, $message);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Role::CustomControlMessage - control features with custom messages

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  has_control foo => (
      control   => 'text',
      features  => {
          match_code => {
              message => 'Foo values must be even',
              code    => sub { $_[0] % 2 == 0 },
          },
      },
  );

=head1 DESCRIPTION

A control feature may consume this role in order to allow the user to specify a custom message on failure. This message may include a single "%s" placeholder, which will be filled in with the label or name of the control.

=head1 METHODS

=head2 format_message

  my $formatted_message = $feature->format_message($unformatted_message);

Given a message containing a single C<%s> placeholder, it fills that placeholder with the control's label. If the control does not implement L<Form::Factory::Control::Role::Labeled>, the control's name is used instead.

=head2 control_info

Reports an informational message automatically filtered through L</format_message>.

=head2 control_warning

Reports a warning automatically filtered through L</format_message>.

=head2 control_error

Reports an error automatically filtered through L</format_error>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
