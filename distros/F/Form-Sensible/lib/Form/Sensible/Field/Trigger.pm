package Form::Sensible::Field::Trigger;

use Moose;
use namespace::autoclean;
extends 'Form::Sensible::Field';

## provides an action trigger

## always has an activation trigger, even if it does nothing.

has 'event_to_trigger' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    builder     => '_default_event_name',
    lazy        => 1,
);

sub _default_event_name {
    my ($self) = @_;

    return $self->name . "_triggered";
}


sub get_additional_configuration {
    my $self = shift;

    return {
                'event_to_trigger' => $self->event_to_trigger,
           };

}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible::Field::Trigger - A Trigger for user activity

=head1 SYNOPSIS

    use Form::Sensible::Field::Trigger;
    
    my $textfield = Form::Sensible::Field::Trigger->new(
                                                    name => 'submit',
                                                  );

=head1 DESCRIPTION

Triggers cause something to happen, most often form validation and processing.
Trigger fields are most often rendered as buttons in graphical interfaces,
such as Submit and Reset buttons in HTML.

B<NOTE> We are still investigating ways to handle Triggers in a flexible and
render-independant way.  That means aside from simple usage, Trigger fields are
likely to change.

=head2 HTML-Based Rendering of Triggers

As with all fields, trigger rendering is primarily controlled by
C<render_hints>.  By default a trigger is rendered as a 'submit' button.  If
you provide a C<render_as> element in the C<render_hints>, you can control how
a trigger is rendered.  The options are:  C<reset>, C<button> and C<link>.
C<reset> renders the trigger as a reset button.  C<button> renders the trigger
as a button input element.  C<link> renders it as a regular HTML link.  If
C<render_as => 'link'> is specified you must also provide a C<link> element in
the C<render_hints> to set the destination of the link.

=head1 ATTRIBUTES

=over 8

=item C<event_to_trigger>

The event name to trigger.

=back

=head1 METHODS

=over 8

=item C<_default_event_name>

Use internally to set the default event name to this class's name appended
with '_triggered'.

=item C<get_additional_configuration>

Returns the attributes' names and values as a hash ref.

=back

=head1 AUTHOR

Jay Kuri - E<lt>jayk@cpan.orgE<gt>

=head1 SPONSORED BY

Ionzero LLC. L<http://ionzero.com/>

=head1 SEE ALSO

L<Form::Sensible>

=head1 LICENSE

Copyright 2009 by Jay Kuri E<lt>jayk@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
