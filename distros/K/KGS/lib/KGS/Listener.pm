package KGS::Listener;

=head1 NAME

KGS::Listener - a generic base class to listen for kgs messages.

=head1 SYNOPSIS

  use base KGS::Listener;

  sub new {
     my $class = shift;
     my $self = $class->SUPER::new (@_);

     # for non-channel-related listeners:
     $self->listen ($self->{conn}, qw(ping req_pic));
     # for channel-type listener
     $self->listen ($self->{conn}, qw(join_room: part_room: msg_room:));
     
     $self;
  }

  sub inject_xxx {
     # handle msg xxx
  }

  # KGS::Listener::Room etc. als require this:
  sub event_xxx {
     # handle synthesized event xxx
  }

=head1 DESCRIPTION

Please supply a description )

The KGS::Listener family has currently these members:

  KGS::Listener              base class for everything
  KGS::Listener::Channel     base class for channels (games, rooms)
  KGS::Listener::Game        base class that handles games
  KGS::Listener::Room        base class for rooms and their game lists
  KGS::Listener::Roomlist    base class for the overall room listing
  KGS::Listener::User        base class for user info, chats etc.
  KGS::Listener::Debug       prints all messages that marc doesn't understand

=head2 METHODS

=over 4

=item new [channel => <id>]...

Create a new KGS::Listener project. The L<channel> parameter is optional.

=cut

sub new {
   my $class = shift;
   bless { @_ }, $class;
}

=cut

=item $listener->listen ($conn, [msgtype...])

Registers the object to receive callback messages of the named type(s).
If C<$conn> is C<undef>, returns immediately. It's safe to call this
function repeatedly.

A msgtype is either a packet name like C<login> or C<msg_room>, the
string C<any>, which will match any type, or a msgtype postdixed with
C<:> (e.g. C<msg_room:>), in which case it will only match the C<<
$listener->{channel} >> channel.

The connection will be stored in C<< $listener->{conn} >>.

In your own new method you should call C<< $self->listen >> once with the
connection and the msgtypes you want to listen for.

=item $listener->unlisten

Unregisters the object again.

=cut

sub listen {
   my ($self, $conn, @types) = @_;

   if ($conn) {
      $self->unlisten;
      $self->{conn} = $conn;
      $_ =~ s/:$/:$self->{channel}/ for @types;
      $self->{listen_types} = \@types;
      $self->{conn}->register ($self, "quit", @types);
   }
}

sub unlisten {
   my ($self) = @_;

   (delete $self->{conn})->unregister ($self, @{$self->{listen_types}})
      if $self->{conn};
}

=item $listener->inject ($msg)

The main injector callback.. all (listened for) messages end up in this
method, which will just dispatch a method with name inject_<msgtype>.

You do not normally have to overwrite this method, but you should provide
methods that are being called with names like C<inject_msg_room> etc.

=cut

sub inject {
   my ($self, $msg) = @_;

   if (my $cb = $self->can ("inject_$msg->{type}")) {
      $cb->($self, $msg);
   } elsif (my $cb = $self->can ("inject_any")) {
      $cb->($self, $msg);
   } else {
      warn "no handler found for message $msg->{type} in $self\n";
   }
}

=item $listener->send ($type, %args);

Calls the C<send> method of the connection when in listen state. It does
not (yet) supply a default channel id.

=cut

sub send {
   my ($self, $type, @arg) = @_;

   $self->{conn}->send ($type, @arg) if $self->{conn};
}

sub inject_quit {
   my ($self) = @_;

   $self->event_quit;
}

sub event_quit {
   my ($self) = @_;

   $self->unlisten;
}

sub DESTROY {
   my ($self) = @_;

   $self->unlisten;
}

=back

=cut

1;

