package IPC::Simple::Message;
# ABSTRACT: a message received from an IPC::Simple process
$IPC::Simple::Message::VERSION = '0.09';

use strict;
use warnings;

use overload fallback => 1,
  '""' => \&message;

use constant IPC_STDIN  => 'stdin';
use constant IPC_STDOUT => 'stdout';
use constant IPC_STDERR => 'stderr';
use constant IPC_ERROR  => 'errors';

BEGIN{
  use base 'Exporter';

  our @EXPORT = qw(
    IPC_STDIN
    IPC_STDOUT
    IPC_STDERR
    IPC_ERROR
  );
}

sub new {
  my ($class, %param) = @_;

  bless{
    source  => $param{source},
    type    => $param{type},
    message => $param{message},
  }, $class;
}

sub type    { $_[0]->{type} }
sub source  { $_[0]->{source} }
sub message { $_[0]->{message} }
sub stdout  { $_[0]->type eq IPC_STDOUT }
sub stderr  { $_[0]->type eq IPC_STDERR }
sub error   { $_[0]->type eq IPC_ERROR }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Simple::Message - a message received from an IPC::Simple process

=head1 VERSION

version 0.09

=head1 METHODS

=head2 source

Returns the L<IPC::Simple> process from which this message was received.

=head2 message

Returns the string content of the message.

=head2 stdout

Returns true if this message was received from the child process' C<STDOUT>.

=head2 stderr

Returns true if this message was received from the child process' C<STDERR>.

=head2 error

Returns true if this message was generated as a result of a process
communication error (e.g. C<SIGPIPE>).

=head1 OVERLOADED

=head2 stringification ("")

Returns the L</message> string.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
