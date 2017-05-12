=head1 NAME

Log::Dispatch::Jabber - Log messages via Jabber

=head1 SYNOPSIS

 use Log::Dispatch;
 use Log::Dispatch::Jabber;

 my $dispatcher = Log::Dispatch->new();
 my $jabber     = Log::Dispatch::Jabber->new(
                                             name=>"jabber",
                                             min_level=>"debug",
                                             login=>{
                                                     hostname => "some.jabber.server",
                                                     port     => 5222,
                                                     username => "logger",
                                                     password => "*****",
                                                     resource => "logger",
                                                    },

	                                     to=>["webmaster\@a.jabber.server",chief_honco\@a.jabber.server"],

                                             check_presence=>1,

                                             # Send a message to this address even if their
                                             # presence indicates they are not available.
                                             force=>"webmaster\@a.jabber.server",

                                             # Buffer 5 messages before sending.
                                             buffer => "5",
                                            );

 $dispatcher->add($jabber);

 $dispatcher->log(
		  level   => 'debug',
		  message => 'Hello. Programmer. This is '.ref($jabber)
		 );

=head1 DESCRIPTION

Log messages via Jabber.

=head1 ERRORS

All internal errors that the package encounters connecting to or authenticating with the Jabber server are logged to STDERR via I<Log::Dispatch::Screen>.

=cut

use strict;

package Log::Dispatch::Jabber;
use base qw (Log::Dispatch::Output);

$Log::Dispatcher::Jabber::VERSION = '0.3';

use Net::Jabber qw (Client Presence);

my %presence;

=head1 PACKAGE METHODS

=head2 __PACKAGE__->new(%args)

Valid arguments are

=over 4

=item *

B<name>

String. 

The name of the object.

required

=item *

B<min_level>

String or Int.

The minimum logging level this object will accept. See the Log::Dispatch documentation for more information.

required

=item *

B<login>

A hash reference containting the following keys

=over 4

=item *

I<hostname>

String.

The name of the Jabber server that your object will connect to.

Required

=item *

I<port>

Int.

The port of the Jabber server that your object will connect to.

Required

=item *

I<username>

String.

The username that your object will use to log in to the Jabber server.

Required

=item *

I<password>

String.

The password that your object will use to log in to the Jabber server.

Required

=item *

I<resource>

String.

The name of the resource that you object will pass to the Jabber server.

Required

=back

=item *

B<to>

A string or an array reference.

A list of Jabber addresses that messages should be sent to.

Required

=item *

B<check_presence>

Boolean.

If this flag is true then a message will only be sent if a recipient's
presence is I<normal> or I<chat>

=item *

B<force>

A string or an array reference.

A list of Jabber addresses that messages should be sent to regardless of
their current presence status.

This attribute is ignored unless the I<check_presence> attribute is true.

=item *

B<buffer>

String. The number of messages to buffer before sending.

If the argument passed is "-" messages will be buffered until the object's destructor is called.

=item *

B<debuglevel>

Int. Net::Jabber debugging level; consult docs for details.

=item *

B<debugfile>

String. Where to write Net::Jabber debugging; default is STDOUT.

=back

Returns an object.

=cut

sub new  {
  my $pkg   = shift;
  my $class = ref $pkg || $pkg;
  my %args  = @_;

  my $self = {};
  bless $self, $class;

  $self->_basic_init(%args);

  $self->{'__client'} = Net::Jabber::Client->new(
						 debuglevel=>$args{debuglevel},
						 debugfile=>($args{debugfile} || "stdout"),
						 );

  if (! $self->{'__client'}) {
    $self->_error($!);
    return undef;
  }

  $self->{'__login'}    = $args{login};
  $self->{'__to'}       = (ref($args{to})    eq "ARRAY") ? $args{to}    : [ $args{to}];
  $self->{'__force'}    = (ref($args{force}) eq "ARRAY") ? $args{force} : [ $args{force}];
  $self->{'__bufto'}    = $args{buffer};
  $self->{'__presence'} = $args{'check_presence'};
  $self->{'__buffer'}   = [];

  return $self;
}

=head1 OBJECT METHODS

This package inherits from I<Log::Dispatch::Output>. 

Please consult the docs for details.

=cut

sub log_message {
  my $self = shift;
  my $log  = { @_ };

  push @{$self->{'__buffer'}},$log->{message};

  if ((! $self->{'__bufto'}) ||
      (($self->{'__bufto'}) && (scalar(@{$self->{'__buffer'}}) == $self->{'__bufto'}))) {
    $self->_send();
  }

  return 1;
}

sub _send {
  my $self = shift;

  #

  my $im = Net::Jabber::Message->new();
  $im->SetMessage(body=>join("",@{$self->{'__buffer'}}),type=>"chat");

  foreach my $addr (@{$self->{'__to'}}) {
    $im->SetTo($addr);

    #

    my $ok = $self->{'__client'}->Connect(
					  hostname => $self->{'__login'}->{'hostname'},
					  port     => $self->{'__login'}->{'port'},
					 );

    if (! $ok) {
      $self->_error("Failed to connect to Jabber server:$!\n");
      return 0;
    }

    my @auth = $self->{'__client'}->AuthSend(
					     username => $self->{'__login'}->{'username'},
					     password => $self->{'__login'}->{'password'},
					     resource => $self->{'__login'}->{'resource'},
					    );

    if ($auth[0] ne "ok") {
      $self->_error("Failed to ident/auth with Jabber server:($auth[0]) $auth[1]. Message not sent.\n");
      return 0;
    }

    #

    if (($self->{'__presence'}) && (! grep /^($addr)$/,@{$self->{'__force'}})) {

      $self->{'__client'}->SetCallBacks("presence"=>\&_presence);
      $self->{'__client'}->PresenceSend();

      unless(defined($self->{'__client'}->Process(2))) {
	$self->_error("There was a problem with the client's connection, $!\n");
	return 0;
      }

      unless ($presence{$addr} =~ /^(normal|chat)$/) {
	$self->_error("Did not notify $addr : $presence{$addr}\n");
	next;
      }
    }

    #

    $self->{'__client'}->Send($im);
    $self->{'__client'}->Disconnect();
  }


  $self->{'__buffer'} = [];
  return 1;
}

# Shamelessly pilfered from the mighty mighty D.J. Adams
# http://www.pipetree.com/jabber/extended_notify.html#Presence

sub _presence {
  my $id       = shift;
  my $presence = shift;

  if (ref($presence) ne "Net::Jabber::Presence") {
    return undef;
  }

  # remove any resource suffix from JID
  (my $jid = $presence->GetFrom()) =~ s!\/.*$!!;

  $presence{$jid} = $presence->GetShow() || 'normal';
}

sub _error {
  my $self = shift;

  if (! $self->{'__logger'}) {
    require Log::Dispatch::Screen;
    $self->{'__logger'} = Log::Dispatch->new();
    $self->{'__logger'}->add(Log::Dispatch::Screen->new(name=>__PACKAGE__,
							stderr=>1,
							min_level=>"error"));
  }

  $self->{'__logger'}->error(@_);
}

sub DESTROY {
  my $self = shift;

  if (scalar(@{$self->{'__buffer'}})) {
    $self->_send();
  }

  if ($self->{'__client'}->Connected()) {
    $self->{'__client'}->Disconnect();
  }

  return 1;
}

=head1 VERSION

0.3

=head1 DATE

November 25, 2002

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

L<Log::Dispatch>

L<Net::Jabber>

=head1 TO DO

=over 4

=item *

Figure out if it is possible to maintain a connection to the Jabber server between calls to I<log_message>. 

If the package does not disconnect between messages but also doesn't do the AuthSend thing, anything after the first message is not sent. (Where does it go?)

If the package does not disconnect and does the AuthSend thing, the Jabber server returns a '503' error which is a flag that something is wrong. Except, you can still send the message if you ignore the fact that everything is not 'ok'.

Go figure.

=back

=head1 BUGS

=over 4

=item *

Sending messages to multiple recipients:

I've made some progress, in a two-steps forward, one-step back kind of
way.

Specifically, I can get the package to send messages to multiple
addresses by connecting/disconnecting for every single address sent
instead of logging in just once for every message.

Then the problem becomes that if too many notices are sent in rapid
succession (unlikely but who I am to say) the jabberd for the sender
will likely start to limit the connection rate and all the subsequent
connections will fail.

I've tried this with both Net::Jabber and Jabber::Connection and the
results were the same.

Ideally, I'd like to simply create one connection and send a bunch of
messages to different addresses. I can go through the motions without
generating any errors but the messages themselves are only ever received
by the first address...

B<As of this writing : the package may fail if you send enough messages
in a short enough period time to freak out your jabberd.>

It is recommended that you set the I<buffer> attribute in the object
constructor.

In the meantime, I'm workin' on it.

 sub _send {
    my $self = shift;

    my $im = Jabber::NodeFactory->newNode("message");
    $im->insertTag('body')->data(...);

    # Where &_connect() and &_disconnect()
    # are simply wrapper methods that DWIM 

    # $self->_connect();
    # The above works great except that only
    # the first address in $self->{'__to'}
    # ever receives any messages

    # This would be my preferred way of doing
    # things since there's no point in creating
    # a gazillion connetions - unless I've spaced
    # on some important Jabber fundamentals....

    foreach my $addr (@{$self->{'__to'}}) {
       $im->attr("to",$addr);

       $self->_connect();
       # The above works so long as not too many
       # messages are sent in rapid succession

       # Log::Dispatch::Jabber has hooks to
       # buffer messages but if I send (4)
       # successive notices with nothing in
       # between, the server I'm testing against
       # (and out-of-the-box FreeBSD port) starts
       # to carp with 'is being connection rate limited'
       # errors after the third notice.

       # I suppose I could sleep(n) but that seems
       # like sort of rude behaviour for a log thingy.

       # Happy happy
       $self->{'__client'}->send($im);
       $self->_disconnect();
    }

    # $self->_disconnect()
 }

=back

Please report all bugs to http://rt.cpan.org/NoAuth/Dists.html?Queue=Log::Dispatch::Jabber

=head1 LICENSE

Copyright (c) 2002, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;
