package Form::Factory::Feature::Role::CustomMessage;
$Form::Factory::Feature::Role::CustomMessage::VERSION = '0.022';
use Moose::Role;

# ABSTRACT: features with custom messages


has message => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_message',
);


sub feature_info {
    my $self    = shift;
    my $message = $self->message || shift;
    $self->result->info($message);
}


sub feature_warning {
    my $self    = shift;
    my $message = $self->message || shift;
    $self->result->warning($message);
}


sub feature_error {
    my $self    = shift;
    my $message = $self->message || shift;
    $self->result->error($message);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Role::CustomMessage - features with custom messages

=head1 VERSION

version 0.022

=head1 DESCRIPTION

A feature may consume this role in order to allow the user to specify a custom message on failure.

=head1 ATTRIBUTES

=head2 message

This is a custom error message for failures. This message is used instead of the one the feature specifies when L</feature_info>, L</feature_warning>, and L</feature_error> are called.

This is inadequate. It should be fixed in the future.

=head1 METHODS

=head2 feature_info

  $feature->feature_info($message);

Record an info feature message.

=head2 feature_warning

  $feature->feature_warning($message);

Record a warning feature message.

=head2 feature_error

  $feature->feature_error($message);

Record an error feature message.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
