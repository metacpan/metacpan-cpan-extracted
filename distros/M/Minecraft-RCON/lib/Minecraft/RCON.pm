#  Minecraft::RCON
#
# Written by Fredrik Vold, no copyrights, no rights reserved.
# This is absolutely free software, and you can do with it as you please.
# If you do derive your own work from it, however, it'd be nice with some
# credits to me somewhere in the comments of that work.


package Minecraft::RCON;

require 5.006;  # To be honest, I don't know this to be true, but AT LEAST this version!
                # If you're still at 5.006 and this won't run, the solution is TO UPGRADE PERL.

use strict;
use warnings;
use IO::Socket 1.18; # Autoflush default on PLX
use Data::Dumper;
use Carp;
use Term::ANSIColor 3.02;

our $VERSION = '0.1.4';

use constant {
    PASSWORD => 3,
    COMMAND => 2,
};

my %COLOR = (
    0 => color('black'),
    1 => color('blue'),
    2 => color('green'),
    3 => color('cyan'),
    4 => color('red'),
    5 => color('magenta'),
    6 => color('yellow'),
    7 => color('white'),
    8 => color('bright_black'),
    9 => color('bright_blue'),
    a => color('bright_green'),
    b => color('bright_cyan'),
    c => color('bright_red'),
    d => color('bright_magenta'),
    e => color('yellow'),
    f => color('bright_white'),

    l => color('bold'),
    m => color('concealed'),
    n => color('underline'),
    o => color('reverse'),

    r => color('reset'),
);

return 509; # For Kevin

sub new {
    my ($class,$conf) = @_;
    my $self = $conf;
    $self->{'request_count'} = 0;
    bless $self,$class;
    return $self;
}

sub strip_color {
    my ($self,$strip) = @_;
    if (defined $strip){
        $self->{'strip_color'} = $strip;
    }
    if (!defined $self->{'strip_color'}){
        return 1;
    }
    else {
        return $self->{'strip_color'};
    }
}
sub convert_color {
    my ($self,$convert) = @_;
    if (defined $convert){
        $self->{'convert_color'} = $convert;
    }
    if (!defined $self->{'convert_color'}){
        return 1;
    }
    else {
        return $self->{'convert_color'};
    }
}
sub address {
    my ($self,$address) = @_;
    if (defined $address){
        $self->{'address'} = $address;
    }
    return $self->{'address'} || '127.0.0.1';
}
sub port {
    my ($self,$port) = @_;
    if (defined $port){
        $self->{'port'} = $port;
    }
    return $self->{'port'} || 25575;
}
sub password {
    my ($self,$password) = @_;
    if (defined $password){
        if ($password eq ''){
            carp "Attempt to set empty password";
        }
        else {
            $self->{'password'} = $password;
        }
    }
    return $self->{'password'} || '';
}

sub command {
    my ($self,$payload) = @_;
    my $socket = $self->{'socket'};
    if (!defined $socket){
        carp "Sending commands to a closed socket";
        return undef;
    }
    else {
        print $socket $self->_encode_packet(COMMAND,$payload);
        my ($size,$id,$type,$payload) = $self->_get_packet;
        return $payload;
    }
}
sub disconnect {
    my ($self) = @_;
    if (my $socket = $self->{'socket'}){
        close $socket;
        $self->{'socket'} = undef;
    }
}
sub connect {
    my ($self) = @_;
    if ($self->{'socket'}){
        carp "Trying to connect while already connected";
        return 0;
    }
    if ($self->password eq ''){
        carp "Attempt to connect without specifying password";
        return 0;
    }
    my $socket = IO::Socket::INET->new (
        PeerAddr => $self->address,
        PeerPort => $self->port,
        Proto    => 'tcp',
    );

    if (!$socket){
        carp 'Connection to '.$self->address.':'.$self->port.' failed.';
        return 0;
    }

    print $socket $self->_packet_password;
    my ($size,$id,$type,$payload) = $self->_get_packet($socket);
    my $expected = $self->_expected_request_id;
    if ($type != 2){
        carp "Unknown RCON auth failure, wrong packet type ($type, expected 2) returned.";
        close($socket);
        return 0;
    }
    elsif (!defined $id || $id != $expected){
        carp "RCON password is WRONG!";
        close($socket);
        return 0;
    }
    else {
        $self->{'socket'} = $socket;
        return 1;
    }
}

sub _encode_packet {
    my ($self,$type,$payload) = @_;
    $payload = "" unless defined $payload;
    my $id = ++$self->{'request_count'};
    my $data = pack("II",$id,$type);
    $data   .= $payload."\0\0";
    $data    = pack("I",length($data)).$data;
    return $data;
}
sub _decode_packet {
    my ($self,$raw_packet) = @_;
    if (length($raw_packet) >= 12){ # Check if the packet is viable before trying to decode it.
        my $size = unpack("I",substr $raw_packet,0,4);
        my $id   = unpack("I",substr $raw_packet,4,4);
        my $type = unpack("I",substr $raw_packet,8,4);
        my $payload = substr $raw_packet,12,$size;

        if ($payload !~ s/\0\0$//){ # A proper Minecraft packet ends in two null characters.
            carp('Recieved packet might be incomplete');
        }

        # strip and convert are mutually exclusive, strip takes presidence
        if ($self->strip_color){
            $payload =~ s/\x{00A7}.//g;
        }
        elsif ($self->convert_color){
            $payload =~ s/\x{00A7}(.)/$COLOR{$1}/g;
            $payload .= $COLOR{'r'};
        }
        return ($size,$id,$type,$payload);
    }
    else {
        carp('Non-viable packet recieved.  Packet is length '.length($raw_packet));
        return (undef,undef,undef);
    }
}
sub _packet_password {
    my ($self) = @_;
    return $self->_encode_packet(PASSWORD,$self->{'password'});
}
sub _get_packet {
    my ($self,$socket) = @_;
    if (!defined $socket){
        $socket = $self->{'socket'};
    }

    my $data;
    if ($socket){
        recv($socket,$data,32767,0); # Assuming Java max signed short integer, since we're talking to Minecraft
        return ($self->_decode_packet($data));
    }
    else {
        carp "Attempt at getting a packet from a closed socket";
        return (undef,undef,undef);
    }
}
sub _expected_request_id {
    my ($self) = @_;
    return $self->{'request_count'};
}

sub DESTROY {
    my ($self) = @_;
    if (my $socket = $self->{'socket'}){
        close $socket;
    }
}

1;


__END__

=head1 NAME

Minecraft::RCON - Handles talking to the Minecraft remote console

=head1 SYNOPSIS


    use Minecraft::RCON;

    my $rcon = Minecraft::RCON->new( { password => 'f4ble' } );
    if ($rcon->connect){
        print $rcon->command('help');
    }
    else {
        print "Oh dang, connection failed!\n";
        # Error capturing and fetching is in the works...
    }
    $rcon->disconnect;

=head1 DESCRIPTION


C<Minecraft::RCON> provides a nice object interface for talking to 
Mojang AB's game Minecraft.  Intended for use with their multiplayer
servers, specifically I<your> multiplayer server, as you will need
the correct rcon.password, and rcon must be enabled on said server.

=head1 CONSTRUCTOR


=over 4

=item new ( [HASHREF] )

A hashref containing all used keys with their default value:

    my $rcon = Minecraft::RCON->new({
        address         => '127.0.0.1',
        port            => 25575,
        password        => ''
        strip_color     => 1,
        convert_color   => 1,
    });

=over 2

=item 
    I<address> and I<port> should explain themselves.  Defaults to localhost and the default Minecraft RCON port.  

=item 
    I<password> defaults to blank, which is never valid.  

=item
    I<strip_color> makes the response to ->command have its Minecraft color codes stripped out.  

=item 
    I<convert_color> tries to convert the Minecraft colors to terminal colors using L<Term::ANSIColor>.  

=back 

Note that no conversion attempt is made while stripping is enabled.  
In addition to the constructor, the different options can be set or changed using the methods below.

=back

=head1 METHODS


These are the public methods.  There are others, but any method not listed here is subject to change without any kind of notice.

=over 4


=item address([STRING])

The string is the new setting, and can be omitted if you don't want to change it.
Returns the address used to connect.

Note that changing this during an ongoing connection does nothing until you ->disconnect and ->connect again.


=item port([INTEGER])

The integer is the new setting, and can be omitted if you don't want to change it.
Returns the port used to connect.

Note that changing this during an ongoing connection does nothing until you ->disconnect and ->connect again.


=item password([STRING])

The string is the new setting, and can be omitted if you don't want to change it.
Returns the password used to connect.

Note that changing this during an ongoing connection does nothing until you disconnect and connect again.

If the password is wrong, it will be carped about when you attempt to connect.

=item connect

Attempt to connect to the configured address and port, and issue the configured password for authentication.
Returns 1 on success, 0 otherwise.

If the password is wrong, it will also carp that fact.

=item command([STRING])

Issues the string as a command to the Minecraft server.

Returns the server's response, with the color codes optionally stripped or converted.

=item disconnect

Disconnects from the server by closing the socket.

=item convert_color([BOOLEAN])

The boolean is the new setting, and can be omitted if you don't want to change it.
Returns the current color conversion setting.

As per usual in perl, blank strings, 0 and undef are considered FALSE, while pretty much anything else is TRUE.
  
This takes effect immediately, and does not require a reconnect.

Color conversion does I<not> happen unless stripping is disabled.  I mean... what colors would it convert?  Turn both off if you want to do the conversion yourself, or have other uses for the data.

=item strip_color([BOOLEAN])

The boolean is the new setting, and can be omitted if you don't want to change it.
Returns the current color stripping setting.

As per usual in perl, blank strings, 0 and undef are considered FALSE, while pretty much anything else is TRUE.
    
This takes effect immediately, and does not require a reconnect.

Note that unless you've turned on color conversions this might cause command returns to contain color codes, which is pretty much just junk data unless you intend to do the conversion yourself.

=back

=head1 SEE ALSO

L<Terminal::ANSIColor>, L<IO::Socket::INET>, L<Carp>

=head1 AFFILIATION WITH MOJANG


I am in no way affiliated with Mojang or the development of Minecraft.
I'm simply a fan of their work, and a server admin myself.  I needed
some RCON magic for my servers website, and there was no perl module.

It is important that everyone using this module understands that if
Mojang changes the way RCON works, I won't be notified any sooner than
anyone else, and I have no special avenue of connection with them.

=head1 AUTHOR

Fredrik Vold <fredrik@webkonsept.com>

=head1 THANKS

Thanks to Mojang for such a great game.

Thanks to #perl on Freenode for being great and assisting me in so many ways.

Of course, thanks to Larry for Perl!

=head1 COPYRIGHT

Minecraft is a trademark of Mojang AB.
Name used in accordance with my interpretation of L<http://www.minecraft.net/terms>, but someone correct me if I'm wrong.  I have no affiliation with Mojang (other than being a customer and fan).

No copyright claimed, no rights reserved.

You are absolutely free to do as you wish with this code, but mentioning me in your comments or whatever would be nice.

=cut
