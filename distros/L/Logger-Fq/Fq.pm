package Logger::Fq;

# Copyright (c) 2015, Circonus, Inc.
# All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

require DynaLoader;

use strict;
use vars qw($VERSION @ISA);
$VERSION = "0.2.12";
@ISA = qw/DynaLoader/;

bootstrap Logger::Fq $VERSION ;

=head1 NAME

Logger::Fq - Log asynchronously to an Fq instance.

=head1 SYNOPSIS

  use Logger::Fq;
  Logger::Fq::enable_drain_on_exit(1);

  my $logger = Logger::Fq->new({ host => '127.0.0.1', port => 8765,
                                exchange => 'logging });
  $logger->log("protocol.category", "Message");

=head1 DESCRIPTION

C<Logger::Fq> provides an asynchronous method of logging information via Fq.
Asynchronous in that the creation of the logging and publishing to it will
never block perl (assuming an IP address is used).

=head2 Methods

=over 4

=item new($options)

Creates a new Logger::Fq object.

     {
       user => $user,           #default 'guest'
       password => $password,   #default 'guest'
       port => $port,           #default 8765
       host => $vhost,          #default '127.0.0.1'
       exchange => $exchange,   #default 'logging'
       heartbeat => $hearbeat,  #default 1000 (ms)
     }

=item log( $channel, $message )

C<$channel> is the routing key used for the Fq message.

C<$message> is the message payload (binary is allowed).

=back

=head2 Static Functions

=over 4

=item Logger::Fq::backlog()

Return the number of messages backlogged.

=item Logger::Fq::drain($s)

Wait up to $us seconds (microsecond resolution) waiting for messages to drain
to 0.  Returns then number of messages drained.  If no messages are backlogged,
this method does not wait.

=item Logger::Fq::enable_drain_on_exit($s, $verbose)

This will cause Logger::Fq to register an END {} function that will wait up to
$s seconds (microsecond resolution) to drain backlogged messages. If $verbose
is specified, print to STDERR the number of messages drain and the time waited.

=item Logger::Fq::debug($flags)

Sets the fileno=2 debugging bits for libfq.

=back

=cut

our ($should_wait_on_exit, $should_be_verbose_on_exit);
$should_wait_on_exit = 0;
$should_be_verbose_on_exit = 0;

sub enable_drain_on_exit {
  $should_wait_on_exit = shift;
  $should_be_verbose_on_exit = shift;
}

use Time::HiRes qw/gettimeofday tv_interval/;
END {
  if($should_wait_on_exit) {
    my $start = [gettimeofday];
    my $drained = Logger::Fq::drain(int($should_wait_on_exit * 1000000));
    my $elapsed = tv_interval ( $start, [gettimeofday] );
    print STDERR "Drained $drained messages in $elapsed s.\n"
      if ($should_be_verbose_on_exit);
  }
}
1;
