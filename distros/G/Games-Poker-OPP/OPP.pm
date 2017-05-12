package Games::Poker::OPP;
use IO::Socket::INET;
use Games::Poker::TexasHold'em; #'
use Carp;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.0';

use constant FOLD => 0;
use constant CALL => 1;
#use constant CHECK => 1; # Synonym (but sadly also a Perl keyword)
use constant RAISE => 2;
use constant BLIND => 3;
use constant GOODBYE => 11; # Undocumented.
use constant JOIN_GAME => 20;
use constant GOODPASS => 21;
use constant BADPASS => 22;
use constant BADNICK => 24;
use constant ACTION => 30;
use constant CHAT => 32;
use constant QUIT_GAME => 33;
use constant GET_GRAPH => 42;
use constant INFORMATION => 43;
use constant SET_FACE => 45;
use constant GET_FACE => 46;
use constant CHANGE_FACE => 47;
use constant START_NEW_GAME => 50;
use constant HOLE_CARDS => 51;
use constant NEW_STAGE => 52;
use constant WINNERS => 53;
use constant CHATTER => 54;
use constant NEXT_TO_ACT => 57;
use constant PING => 60;
use constant PONG => 61;

use Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'actions' => [ qw( RAISE FOLD CHECK CALL ) ], 
                     'server_notices' => [ qw( 
                        START_NEW_GAME HOLE_CARDS NEW_STAGE NEXT_TO_ACT
                        FOLD CALL RAISE BLIND WINNERS CHATTER INFORMATION
                     ) ]
                   );

our @EXPORT = (@{$EXPORT_TAGS{actions}}, @{$EXPORT_TAGS{server_notices}});
our @protocol;
my @handlers;
map {$protocol[$_->[0]] = $_->[1];
     $handlers[$_->[0]] = $_->[2] if $_->[2];
    } (
    [ START_NEW_GAME , "N5(Z*NN)*", \&new_game_handler ],
    [ HOLE_CARDS , "NZ*", \&hole_card_handler ],
    [ NEW_STAGE , "NZ*", \&next_stage_handler ],
    [ NEXT_TO_ACT , "N4", \&next_turn_handler ],
    [ FOLD , "NN", \&fold_handler ],
    [ CALL , "NN", \&call_handler ],
    [ RAISE , "NN", \&raise_handler ],
    [ BLIND , "NN", \&blinds_handler ],
    [ WINNERS , "N(NN)*" ],

    # Stuff we send
    [ JOIN_GAME , "Z*Z*NZ*" ],
    [ ACTION , "N" ],
    [ GET_GRAPH , "Z*" ],
    [ SET_FACE , "Z*" ],
    [ GET_FACE , "Z*" ],
    [ CHANGE_FACE , "N" ],
    [ CHAT , "Z*" ],
    [ QUIT_GAME , "" ],

    # Status messages
    [ GOODPASS , "" ],
    [ BADPASS , "" ],
    [ BADNICK , "" ],

    # Handled internally by playgame
    [ PING , "" ],
    [ PONG , "" ],
    [ CHATTER , "Z*" ],
    [ INFORMATION , "Z*" ],
);

sub send_packet {
    my ($self, $message_id, @data) = @_;
    croak sprintf "Protocol error: command %d not recognised", $message_id
        unless exists $protocol[$message_id];
    my $packed_data = "";
    if ($protocol[$message_id]) {
        eval { $packed_data = pack($protocol[$message_id], @data); };
        croak sprintf "Problem packing data for %d command", $message_id if $@;
    }
    my $packet = pack "NN", $message_id, length $packed_data;
    $packet .= $packed_data;
    $self->put($packet);
    return $packet;
}

sub get_packet {
    my $self = shift;
    # You got the message?
    return unless my $data = $self->get(8);
    # I just got it!
    my ($code, $length) = unpack("NN", $data);
    # And give?
    croak sprintf "Protocol error: command %d not recognised", $code 
        unless exists $protocol[$code];
    # You've never been with it - I mean, with us.
    if (!$length) {
        # I'm gone, gone away.
        return $code 
        # But you were here, then you went and gone.
    }
    # Got the word?
    $data = $self->get($length);
    my @args;
    # The message.
    eval { @args = unpack($protocol[$code], $data) };
    croak sprintf "Didn't get the arguments to the 0x%x command we expected",
        $code if $@;
    # Give, all you want's give, that's it!
    return ($code, @args);
    # Give it to me baby!
    confess;
}

=head1 NAME

Games::Poker::OPP - Implements the Online Poker Protocol

=head1 SYNOPSIS

  use Games::Poker::OPP;
  my $poker = Games::Poker::OPP->new(
                username => "Perlkibot",
                password => "sekrit",
                server   => "chinook6.cs.ualberta.ca",
                port     => 55006
              );
  $poker->connect or die $@;

=head1 DESCRIPTION

This class implements the Online Poker Protocol as specified at
L<http://games.cs.ualberta.ca/webgames/poker/bots.html>. This
implementation uses C<IO::Socket::INET> to do all the communication, but
is designed to be subclassable for, e.g. POE.

=head1 METHODS

=head2 new

  my $poker = Games::Poker::OPP->new(
                username => "Perlkibot",
                password => "sekrit",
                server   => "chinook6.cs.ualberta.ca",
                port     => 55006,
                status   => \&handle_update,
                callback => \&decide_strategy
              );

Prepares a new connection to a poker server. This doesn't actually make
the connection yet; use C<connect> to do that.

You B<must> supply a C<callback> which will be called when it is your
turn to act; you may supply a C<status> callback which will be called
during a game when something happens.

=cut

sub new {
    my $class = shift;
    my %args = (
       server   => "chinook6.cs.ualberta.ca",
       port     => 55006,
       status   => sub {},
       @_
    );
    defined $args{$_} or croak "No $_ specified" 
        for qw(username password callback);
    return bless \%args, $class;
}

=head2 connect

Initiates a connection to the specified server. This is something you'll
want to override if you're subclassing this module.

=cut

sub connect {
    my $self = shift;
    $self->{socket} = IO::Socket::INET->new(
        PeerHost => $self->{server},
        PeerPort => $self->{port},
    );
}

=head2 put ($data)

Sends C<$data> to the server.

=head2 get ($len)

Tries to retrieve C<$len> bytes of data from the server.

Again, things you'll override when inheriting.

=cut

sub put { my ($self, $what) = @_; $self->{socket}->write($what, length $what); }
sub get { 
    my ($self, $len) = @_; 
    my $buf = " "x$len; 
    my $newlen = $self->{socket}->read($buf, $len);
    return substr($buf,0,$newlen);
}

=head2 joingame

Sends username/password credentials and joins the game. Returns 0 if
the username/password was not accepted.

=cut

sub joingame {
    my $self = shift;
    $self->send_packet(JOIN_GAME,
        $self->{username},
        $self->{password},
        1, # Protocol version
        ref $self # Class. ;)
    );
    my ($status) = $self->get_packet();
    if ($status == GOODPASS) { 
        return 1;
    } elsif ($status == BADPASS) {
        return 0;
    } else {
        croak sprintf "Protocol error: got %i from server", $status;
    }
}

=head2 playgame

    $self->playgame( )

Once you've signed into the server, the C<playgame> loop will receive
status events from the server, update the internal game status object
and call your callbacks.

=cut

sub playgame {
    my $self = shift;
    $self->{game} = undef;

    while (my ($cmd, @data) = $self->get_packet()) {
        if ($cmd == PING) { $self->send_packet(PONG); next; }
        if ($cmd == GOODBYE) { last }
        if ($cmd == CHATTER ||
            $cmd == INFORMATION) { 
                $self->{status}->($self, $cmd, @data); next; 
            }
    
        # Discard things which don't concern us. 
        next unless $self->{game} or $cmd == START_NEW_GAME; 

        if (exists $handlers[$cmd]) {
            $handlers[$cmd]->($self, $cmd, @data);
        }
        $self->{status}->($self, $cmd, @data);

    }
}

=head2 state

Returns a C<Games::Poker::TexasHold'em> object representing the current
state of play - the players involved, the pot, and so on. See
L<Games::Poker::TexasHold'em> for more information about how to use this.

=cut

sub state { $_[0]->{game} }

sub new_game_handler { my ($self, $cmd, @data) = @_;
    my ($bet, $nplayers, $button, $position, $gid) = splice @data,0,5;
    return unless $position > -1;
    my @players;
    for (1..$nplayers) {
        croak "Protocol error: Expected $nplayers, only saw ".@players
            unless @data;
        my ($name, $bankroll, $icon) = splice @data,0,3;
        push @players, { name => $name, bankroll => $bankroll };
    }
    $self->{game} = Games::Poker::TexasHold'em->new( #'
        players => \@players,
        bet => $bet,
        button => $players[$button]->{name},
    );

    # Sadly, different people have different ideas about how the
    # button works.
    $self->{game}->_advance;
    $self->{game}->_advance;
    $self->{game}->_advance;
}

sub hole_card_handler {
    my ($self, $msg, $who, $cards) = @_;
    if ($who == $self->{game}->{seats}->{$self->{username}}) {
        $self->{game}->hole($cards)
    } 
}

sub blinds_handler {
    my $self = shift;
    return if !$self->{game} || $self->{game}{blinded}++;
    $self->{game}->blinds;
}

sub fold_handler { shift->{game}->fold() }
sub call_handler { shift->{game}->check_call(); }
sub raise_handler { my ($self, $amount) = @_[0,2]; 
                    $self->{game}->raise($amount); }
sub next_turn_handler {
    my ($self, $cmd, $who, $to_call, $min_bet, $max_bet) = @_;
    my $game = $self->{game};

    # If it's me, make the callback
    if ($who == $game->{seats}->{$self->{username}}) {
        my $action = $self->{callback}->($self, $to_call, $min_bet, $max_bet);
        return $self->send_packet(ACTION, $action);
    }
    # If it's not me, see if it's who we think it is.
    return if $who == $game->{next};
    # If it's not who we think it is, we need to advance until it is;
    # this may happen when we hit the next stage.
    return unless $game->{blinded};
    $game->{next} = $who;
}

sub next_stage_handler {
    my ($self, $msg, $stage, $cards) = @_;
    $self->{game}->next_stage() if $self->{game}->{blinded};
    if ($cards) { $self->{game}->{board} = [$cards]; }
}

=head1 EXAMPLES

See the included F<poker-client.pl> as an example of how to use this
module.

=head1 AUTHOR

Simon Cozens, E<lt>simon@dsl.easynet.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
