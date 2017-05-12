package Form::Factory::Message;
$Form::Factory::Message::VERSION = '0.022';
use Moose;

use Moose::Util::TypeConstraints;
enum 'Form::Factory::Message::Type' => [qw( info warning error )];
no Moose::Util::TypeConstraints;

# ABSTRACT: Handy class for encapsulating messages


has field => (
    is       => 'rw',
    isa      => 'Str',
    predicate => 'is_tied_to_field',
);


has message => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);


has type => (
    is       => 'rw',
    isa      => 'Form::Factory::Message::Type',
    required => 1,
    default  => 'info',
);


sub english_message {
    my $self = shift;
    my $message = ucfirst $self->message;
    $message .= '.' if $message =~ /(?:[\w\s])$/;
    return $message;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Message - Handy class for encapsulating messages

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  my $message = Form::Factory::Message->new(
      field   => 'foo',
      type    => 'warning',
      message => 'Blah blah blah',
  );

  if ($message->type eq 'warning' or $message->type eq 'error') {
      print uc($message->type);
  }

  if ($message->is_tied_to_field) {
      print $message->field, ": ", $message->message, "\n";
  }

=head1 DESCRIPTION

This is used to store messages that describe the outcome of the various parts of the action workflow.

=head1 ATTRIBUTES

=head2 field

This is the name of the field the message belongs with. If set the C<is_tied_to_field> predicate will return true.

=head2 message

This is the message itself. By convention, the message is expected to be formatted with the initial caps left off and no ending punctuation. This allows it to be more easily formatted or embedded into larger error messages, if necessary.

=head2 type

This is the type of message. Must be one of: info, warning, or error.

=head1 METHODS

=head2 english_message

This capitalizes the first character of the message and adds a period at the end of the last character is a word or space character.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
