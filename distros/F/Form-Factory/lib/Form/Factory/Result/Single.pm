package Form::Factory::Result::Single;
$Form::Factory::Result::Single::VERSION = '0.022';
use Moose;

with qw( Form::Factory::Result );

# ABSTRACT: Form result class representing a single result


has is_valid => (
    is        => 'rw',
    isa       => 'Bool',
    predicate => 'is_validated',
    clearer   => 'clear_validation',
);


has is_success => (
    is        => 'rw',
    isa       => 'Bool',
    predicate => 'is_outcome_known',
    clearer   => 'clear_outcome',
);


has messages => (
    is       => 'ro',
    isa      => 'ArrayRef[Form::Factory::Message]',
    required => 1,
    default  => sub { [] },
);


has content => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
    default  => sub { {} },
);


sub add_message {
    my ($self, %params) = @_;
    push @{ $self->messages }, Form::Factory::Message->new( %params );
}


sub clear_state {
    my $self = shift;
    $self->clear_validation;
    $self->clear_outcome;
    $self->content({});
}


sub clear_messages {
    my $self = shift;
    @{ $self->messages } = ();
}


sub clear_messages_for_field {
    my ($self, $field) = @_;

    my @messages = grep { $_->is_tied_to_field and $_->field eq $field } 
                       @{ $self->messages };

    @{ $self->messages } = @messages;
}


sub info {
    my ($self, $message) = @_;
    $self->add_message( message => $message );
}


sub field_info {
    my ($self, $field, $message) = @_;
    $self->add_message( field => $field, message => $message );
}


sub warning {
    my ($self, $message) = @_;
    $self->add_message( type => 'warning', message => $message );
}


sub field_warning {
    my ($self, $field, $message) = @_;
    $self->add_message( type => 'warning', field => $field, message => $message );
}


sub error {
    my ($self, $message) = @_;
    $self->add_message( type => 'error', message => $message );
}


sub field_error {
    my ($self, $field, $message) = @_;
    $self->add_message( type => 'error', field => $field, message => $message );
}


sub success {
    my ($self, $message) = @_;
    $self->is_success(1);
    $self->add_message( type => 'info', message => $message);
}


sub failure {
    my ($self, $message) = @_;
    $self->is_success(0);
    $self->add_message( type => 'error', message => $message);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Result::Single - Form result class representing a single result

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  my $result = Form::Factory::Result::Single->new;

  $result->is_valid(1);
  $result->is_success(1);
  $result->success('success! Hurray! Yippee! Woohoo!');
  $result->failure('failure! Shucks! Bummer! Glurgh!');

  $result->info('something happened');
  $result->warning('something happened, beware!');
  $result->error('nothing happened. Ohnoes!');

  $result->field_info(foo => 'consider this info about foo');
  $result->field_warning(bar => 'bar worked, but you should check it again');
  $result->field_error(baz => 'baz is wrong');

  $result->clear_messages_for_field('foo');
  $result->clear_messages;

=head1 DESCRIPTION

This class provides an individual L<Form::Factory::Result>.

=head1 ATTRIBUTES

=head2 is_valid

A boolean value indicating whether the action checked out okay. When set, the C<is_validated> predicate is set to true.

=head2 is_success

A boolean value indicating whether the action ran okay. When set, the C<is_outcome_known> predicate is set to true.

=head2 messages

This is the array of L<Form::Factory::Message> objects attached to this result.

=head2 content

This is a hash of other information to attach to the result. This can be anything the action needs to output to the caller. This can be useful for returning references to newly created objects, automatically assigned IDs, etc.

=head1 METHODS

=head2 add_message

  $result->add_message(%options);

The C<%options> are passed to the constructor of L<Form::Factory::Message>. The new message object is added to the end of L</messages>.

=head2 clear_state

Clears the C<is_valid> and C<is_success> flags (which also clears C<is_failure>, C<is_validated>, and C<is_outcome_known>). This also resets C<content> to an empty hash.

=head2 clear_messages

Empties the list of messages in L</messages>.

=head2 clear_messages_for_field

  $result->clear_messages_for_field($field);

Clears all messages that are tied to the named field.

=head2 info

  $result->info($message);

Adds a new regular info message.

=head2 field_info

  $result->field_info($field, $message);

Adds a new info message tied to the named field.

=head2 warning

  $result->warning($message);

Adds a new regular warning messages.

=head2 field_warning

  $result->field_warning($field, $message);

Adds a new warning message tied to the named field.

=head2 error

  $result->error($message);

Adds a new regular error message.

=head2 field_error

  $result->field_error($field, $message);

Adds a new error message tied to the named field.

=head2 success

  $result->success($message);

This is shorthand for:

  $result->is_success(1);
  $result->info($message);

=head2 failure

  $result->failure($message);

This is shorthand for:

  $result->is_success(0);
  $result->error($message);

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
