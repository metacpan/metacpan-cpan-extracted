package Log::Dispatch::Message::Passing;
use base qw(Log::Dispatch::Output);

use warnings;
use strict;
use Scalar::Util qw/ blessed /;
use Carp qw/ confess /;

our $VERSION = '0.009';

sub new {
  my ($class, %arg) = @_;
  confess("Need an 'output' argument") unless $arg{output};
  my $output = $arg{output};
  confess("output => $output must be an object which can ->consume")
    unless blessed($output) && $output->can('consume');

  my $self = { output => $output };

  bless $self => $class;

  # this is our duty as a well-behaved Log::Dispatch plugin
  $self->_basic_init(%arg);

  return $self;
}

sub log_message {
  my ($self, %p) = @_;
  $self->{output}->consume({%p});
}

=head1 NAME

Log::Dispatch::Message::Passing - log events to Message::Passing

=head1 SYNOPSIS

In your application code:

  use Log::Dispatch;
  use Log::Dispatch::Message::Passing;
  use Message::Passing::Filter::Encoder::JSON;
  use Message::Passing::Output::ZeroMQ;

  my $log = Log::Dispatch->new;

  $log->add(Log::Dispatch::Message::Passing->new(
        name      => 'myapp_aggregate_log',
        min_level => 'debug',
        output    => Message::Passing::Filter::Encoder::JSON->new(
            output_to => Message::Passing::Output::ZeroMQ->new(
                connect => 'tcp://192.168.0.1:5558',
            ),
        ),
  ));

  $log->warn($_) for qw/ foo bar baz /;

On your central log server:

  message-pass --input ZeroMQ --input_options '{"socket_bind":"tcp://*:5558"}' \
    --output File --output_options '{"filename":"myapp_aggregate.log"}'

=head1 DESCRIPTION

This provides a L<Log::Dispatch> log output system that sends logged events to
L<Message::Passing>.

This allows you to use any of the Message::Passing outputs or filters
to process log events and send them across the network, and you can use
the toolkit to trivially construct a log aggregator.

=head1 METHODS

=head2 C<< new >>

 my $table_log = Log::Dispatch::Message::Passing->new(\%arg);

This method constructs a new Log::Dispatch::Message::Passing output object.

Required arguments are:

  output - a L<Message::Passing> L<Output|Message::Passing::Role::Output> class.

=head2 log_message

This is the method which performs the actual logging, as detailed by
Log::Dispatch::Output.

=cut

=head1 SEE ALSO

=over

=item L<Message::Passing>

The logging framework itself, allowing you to very simply build log
aggregation and processing servers.

=item L<Message::Passing::Output::ZeroMQ>

The recommended network protocol for aggregating or transporting messages
across the network.

Note that whilst this transport is recommended, it is B<NOT> required by
this module, so you need to require (and depend on) L<Message::Passing::ZeroMQ>
separately.

=item example/ directory

Instantly runnable SYNOPSIS - plug into your application for easy log
aggregation.

=back

=head1 AUTHOR

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored it's development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 COPYRIGHT

Copyright Suretec Systems Ltd. 2012.

=head1 LICENSE

GNU Affero General Public License, Version 3

If you feel this is too restrictive to be able to use this software,
please talk to us as we'd be willing to consider re-licensing under
less restrictive terms.

=cut

1;

