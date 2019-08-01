package MikroTik::API;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

MikroTik::API - Client to MikroTik RouterOS API

=head1 VERSION

Version 1.1.0

=cut

our $VERSION = '1.1.0';


=head1 SYNOPSIS

    use MikroTik::API;

    my $api = MikroTik::API->new({
        host => 'mikrotik.example.org',
        username => 'whoami',
        password => 'SECRET',
        use_ssl => 1,
    });

    my ( $ret_get_identity, @aoh_identity ) = $api->query( '/system/identity/print', {}, {} );
    print "Name of router: $aoh_identity[0]->{name}\n";

    $api->logout();

=head1 DESCRIPTION

=cut

use Moose;
use namespace::autoclean;

use Digest::MD5;
use IO::Socket::INET;
use IO::Socket::SSL;
use Time::Out qw{ timeout };

=head1 PUBLIC METHODS

=head2 new( \%config )

    my $api = MikroTik::API->new({
        host => 'mikrotik.example.org',
        username => 'whoami',
        password => 'SECRET',
        autoconnect => 1, # optional (set to 0 if you do not want to connect during construction, default: 1)
        use_ssl => 1, # optional (0 for non ssl / 1 for ssl)
        port => 8729, # optonal (needed if you use another port then 8728 for non-ssl or 8729 for ssl)
        debug => 0, # optional (set beween 0 (none) and 5 (most) for debug messages)
        timeout => 3, # optional (timeout after 3 seconds during connect)
        probe_before_talk => 3, # optional (probe connection before each actual command)
        reconnect_after_failed_probe => 1, # optional (reconnect if probe failed)

    });

=cut

sub BUILD {
    my ($self) = @_;
    if ( $self->get_autoconnect() && $self->get_host() ) {
        $self->connect();
        if ( $self->get_username() && defined( $self->get_password() ) ) {
            $self->login();
        }
    }
    return $self;
}

=head2 $api->connect()

Connect happens on construction if you provide host address

    my $api = MikroTik::API->new();

    $api->set_host('mikrotik.example.org');
    $api->set_port(1234);
    $api->set_use_ssl(1);

    $api->connect();

=cut

sub connect {
    my ( $self ) = @_;

    if ( ! $self->get_host() ) {
        die 'host must be set before connect()'
    }

    if ( $self->get_use_ssl() ) {
        $self->set_socket(
            IO::Socket::SSL->new(
                PeerAddr => $self->get_host(),
                PeerPort => $self->get_port(),
                Proto => 'tcp',
                SSL_cipher_list => 'HIGH',
                SSL_verify_mode => $self->get_ssl_verify(),
                Timeout => $self->get_timeout(),
            ) or die "failed connect or ssl handshake ($!: ". IO::Socket::SSL::errstr() .')'
        );
    }
    else {
        $self->set_socket(
            IO::Socket::INET->new(
                PeerAddr => $self->get_host(),
                PeerPort => $self->get_port(),
                Proto   => 'tcp',
                Timeout => $self->get_timeout(),
            ) or die "failed connect ($!)"
        );
    }
    if ( ! $self->get_socket() ) {
        die "socket creation failed ($!)";
    }
    $self->get_socket()->sockopt(SO_KEEPALIVE,1);
    $self->get_socket()->sockopt(SO_RCVTIMEO,$self->get_timeout());
    $self->get_socket()->sockopt(SO_SNDTIMEO,$self->get_timeout());
    return $self;
}

=head2 $api->login()

Connect happens on construction if you provide host address, username and password

    my $api = MikroTik::API->new({ host => 'mikrotik.example.org' });

    $api->set_username('whoami');
    $api->set_password('SECRET');

    $api->login();

=cut

sub login {
    my ( $self ) = @_;

    if ( ! $self->get_username() && defined( $self->get_password() ) ) {
        die 'username and password must be set before connect()';
    }
    if ( ! $self->get_socket() ) {
        $self->connect();
    }

    # RouterOS post v6.43 has new authentication method, thus pushing login/pass in the very first request.
    my @command = ('/login');
    push( @command, '=name=' . $self->get_username() );
    push( @command, '=password=' . $self->get_password() );
    my ( $retval, @results ) = $self->talk( \@command );
    die 'disconnected while logging in' if !defined $retval;
    if ( $retval > 1 ) {
        die 'error during establishing login: ' . $results[0]{'message'};
    }

    # if we got "=ret=" in response - then assuming this is old style AUTH
    if ( exists $results[0]{'ret'} ) {
        my $challenge = pack("H*",$results[0]{'ret'});
        my $md5 = Digest::MD5->new();
        $md5->add( chr(0) );
        $md5->add( $self->get_password() );
        $md5->add( $challenge );

        @command = ('/login');
        push( @command, '=name=' . $self->get_username() );
        push( @command, '=response=00' . $md5->hexdigest() );
        ( $retval, @results ) = $self->talk( \@command );
    }
    die 'disconnected while logging in' if !defined $retval;
    if ( $retval > 1 ) {
            die 'error during establishing login: ' . $results[0]{'message'};
    }

    if ( $self->get_debug() > 0 ) {
        print 'Logged in to '. $self->get_host() .' as '. $self->get_username() ."\n";
    }
    return $self;
}

=head2 $api->logout()

    $api->logout();

=cut

sub logout {
    my ($self) = @_;
    $self->get_socket()->close();
    $self->set_socket( undef );
}

=head2 $api->cmd( $command, \%attributes )

    # Set with no key required
    # /system identity set name=MyNewMikroTik
    my $returnvalue = $api->cmd( '/system/identity/set', { 'name' => 'MyNewMikroTik' } );
    print "Name set\n" if ($returnvalue < 2);

    # Set keyed on the name "local"
    # /interface bridge set local fast-forward=no
    my $returnvalue = $api->cmd( '/interface/bridge/set', { '.id' => 'local', 'fast-forward' => 'no' } );
    print "Bridge fast-forward turned off\n" if ($returnvalue < 2);

    # Set keyed on internal key
    # /interface bridge set *cc fast-forward=no
    my $returnvalue = $api->cmd( '/interface/bridge/set', { '.id' => '*cc', 'fast-forward' => 'no' } );
    print "Bridge fast-forward turned off\n" if ($returnvalue < 2);

    # Reset a value
    # /routing bgp peer set testpeer !keepalive-time
    my $returnvalue = $api->cmd( '/routing/bgp/peer/set', { '.id' => 'testpeer', 'keepalive-time' => undef } );
    print "Reset keepalive-time on testpeer\n" if ($returnvalue < 2);

=cut

sub cmd {
    my ( $self, $cmd, $attrs_href ) = @_;
    my @command = ($cmd);

    foreach my $attr ( keys %{$attrs_href} ) {
        if (defined($attrs_href->{$attr})) {
            push( @command, '='. $attr .'='. $attrs_href->{$attr} );
        } else {
            push( @command, '=!'. $attr );
        }
    }
    my ( $retval, @results ) = $self->talk( \@command );
    return ( $retval, @results );
}

=head2 $api->query( $command, \%attributes, \%conditions )

    # Get all interfaces of type ether
    my ( $ret_interface_print, @interfaces ) = $api->query('/interface/print', { '.proplist' => '.id,name' }, { type => 'ether' } );
    foreach my $interface ( @interfaces ) {
        print "$interface->{name}\n";
    }

    # get all default routes that don't have the dynamic attribute
    my ( $ret_route_print, @routes ) = $api->query('/ip/route', { '.proplist' => '.id,dst-address' }, { 'dst-address' => '0.0.0.0/0', 'dynamic'=>undef } );
    foreach my $route ( @routes ) {
        print "$route->{'dst-address'}\n";
    }

    # get all default routes that don't have the dynamic attribute (alternate using array ref)
    my ( $ret_route_print, @routes ) = $api->query('/ip/route', { '.proplist' => '.id,dst-address' }, [ 'dst-address=0.0.0.0/0', '-dynamic' ] );
    foreach my $route ( @routes ) {
        print "$route->{'dst-address'}\n";
    }

    # get all default routes along with those with the dynamic attribute (note 'or' operator as last arg)
    my ( $ret_route_print, @routes ) = $api->query('/ip/route', { '.proplist' => '.id,dst-address' }, [ 'dst-address=0.0.0.0/0', 'dynamic', '#|' ] );
    foreach my $route ( @routes ) {
        print "$route->{'dst-address'}\n";
    }

=cut

sub query {
    my ( $self, $cmd, $attrs_href, $queries_ref ) = @_;

    my @command = ($cmd);
    foreach my $attr ( keys %{$attrs_href} ) {
        push( @command, '='. $attr .'='. (defined($attrs_href->{$attr}) ? $attrs_href->{$attr} : ''));
    }
    if (defined($queries_ref)) {
        if (ref($queries_ref) eq 'HASH') {
            foreach my $query (keys %{$queries_ref} ) {
                if (defined($queries_ref->{$query})) {
                    push( @command, '?'. $query .'='. $queries_ref->{$query} );
                } else {
                    push( @command, '?-'. $query);
                }
            }
        } elsif (ref($queries_ref) eq 'ARRAY') {
            foreach my $query (@{$queries_ref} ) {
                push( @command, '?'. $query);
            }
        }
    }
    my ( $retval, @results ) = $self->talk( \@command );
    return ( $retval, @results );
}

=head2 $api->get_by_key( $command, $keycolumn )

    my %interface = $api->get_by_key('/interface/ethernet/print', 'name' );
    print "$interface{'ether1'}->{running}\n";

=cut

sub get_by_key {
    my ( $self, $cmd, $id ) = @_;
    $id ||= '.id';
    my @command = ($cmd);
    my %ids;
    my ( $retval, @results ) = $self->talk( \@command );
    die 'disconnected' if !defined $retval;
    if ($retval > 1) {
        die $results[0]{'message'};
    }
    foreach my $attrs ( @results ) {
        my $key = '';
        foreach my $attr ( keys %{ $attrs } ) {
            my $val = $attrs->{$attr};
            if ($attr eq $id) {
                $key = $val;
            }
        }
        if ( $key ) {
            $ids{$key} = $attrs;
        }
    }
    return %ids;
}

=head1 ACCESSORS

=head2 $api->get_host(), $api->set_host( $hostname )

=cut

has 'host' => ( is => 'rw', reader => 'get_host', writer => 'set_host', isa => 'Str' );

=head2 $api->get_port(), $api->set_port( $portnumber )

=cut

has 'port' => ( is => 'ro', reader => '_get_port', writer => 'set_port', isa => 'Int' );

=head2 $api->get_username(), $api->set_username( $username )

=cut

has 'username' => ( is => 'rw', reader => 'get_username', writer => 'set_username', isa => 'Str' );

=head2 $api->get_password(), $api->set_password( $password )

=cut

has 'password' => ( is => 'rw', reader => 'get_password', writer => 'set_password', isa => 'Str' );

=head2 $api->get_use_ssl(), $api->set_use_ssl( $zero_or_one )

=cut

has 'use_ssl'    => ( is => 'rw', reader => 'get_use_ssl', writer => 'set_use_ssl', isa => 'Bool' );

=head2 $api->get_ssl_verify(), $api->set_ssl_verify( $zero_or_one )

=cut

has 'ssl_verify' => ( is => 'rw', reader => 'get_ssl_verify', writer => 'set_ssl_verify', isa => 'Int', default => 1 );

=head2 $api->get_new_auth_method(), $api->set_new_auth_method( $zero_or_one )

DEPRECATED: does not have any effect any longer. Login looks up wether new method is possible and falls back to old method. This parameter will be removed in future.
Auth method changed in RouterOS v6.43+ (https://wiki.mikrotik.com/wiki/Manual:API#Initial_login) and reduces login by one call but sends password in plaintext.

=cut

has 'new_auth_method' => ( is => 'rw', reader => 'get_new_auth_method', writer => 'set_new_auth_method', isa => 'Bool', default => 0 );

=head2 $api->get_autoconnect(), $api->set_autoconnect( $zero_or_one )

=cut

has 'autoconnect' => ( is => 'rw', reader => 'get_autoconnect', writer => 'set_autoconnect', isa => 'Bool', default => 1 );

=head2 $api->get_socket(), $api->set_socket( $io_socket )

If you need to use an existing socket for the API connection.

    my $socket = IO::Socket::INET->new();
    $api->set_socket( $socket );

=cut

has 'socket' => ( is => 'rw', reader => 'get_socket', writer => 'set_socket', isa => 'Maybe[IO::Socket]' );

=head2 $api->get_debug(), $api->set_debug( $int )

    $api->set_debug(0); # no debug
    $api->set_debug(5); # verbose debug to STDOUT

=cut

has 'debug' => ( is => 'rw', reader => 'get_debug', writer => 'set_debug', isa => 'Int', default => 0 );

=head2 $api->get_timeout(), $api->set_timeout( $seconds )

Abort connect after $seconds of no reply from MikroTik. This _will not_ affect lost connections. Use probe_before_talk for this.

=cut

has 'timeout' => ( is => 'rw', reader => 'get_timeout', writer => 'set_timeout', isa => 'Int', default => 5 );

=head2 $api->get_probe_before_talk(), $api->set_probe_before_talk( $seconds )

Use this attribute to enable a test command with timeout to ensure that the connection is still alive before sending the actual command.
This is very useful for long lasting connections that may get disconnected while idling. A broken connection will not be recognized otherwise,
because the socket still exists and the command will last forever. The advantage over a common timeout for all commands is that long lasting
commands are still possible. Set this to 0 if you use many consequent commands and reenable it after completion.

    $api->set_probe_before_talk(0); # no probing of connection before sending command and read reply
    $api->set_probe_before_talk(5); # a simple command will be sent and after 5 seconds of no reply, the connection is assumed as broken

=cut

has 'probe_before_talk' => ( is => 'rw', reader => 'get_probe_before_talk', writer => 'set_probe_before_talk', isa => 'Int', default => 0 );

=head2 $api->get_reconnect_after_failed_probe(), $api->set_reconnect_after_failed_probe( $zero_or_one )

If connection is recognized as broken then either reconnect or die otherwise.

=cut

has 'reconnect_after_failed_probe' => ( is => 'rw', reader => 'get_reconnect_after_failed_probe', writer => 'set_reconnect_after_failed_probe', isa => 'Bool', default => 1 );

=head1 SEMI-PUBLIC METHODS

can be useful for advanced users, but too complex for daily use

=head2 $api->talk( \@sentence )

=cut

# Send a sentence (command) and then read sentences back until we
# get a '!done' sentence
# returns 1 on success or 2 on trap, 3 on fatal
#       along with an array of hashref for the results
sub talk {
    my ( $self, $sentence_aref ) = @_;

    if( $self->get_probe_before_talk() ) {
        my $seconds = $self->get_probe_before_talk();
        $self->set_probe_before_talk(0);
        timeout $seconds => sub {
            $self->talk( ['/login'] );
        };
        $self->set_probe_before_talk($seconds);
        if( $@ ) {
            if( $self->get_reconnect_after_failed_probe() ) {
                $self->connect();
                $self->login();
            }
            else {
                return( 3, {message => 'could not talk to MikroTik'});
            }
        }
    }

    $self->_write_sentence( $sentence_aref );
    my ( @reply, @attrs );
    my $retval;

    # Keep reading sentences until we get one that begins with '!done'
    # Put each sentence into a hashref
    while ( @reply = $self->_read_sentence()) {
        if ($reply[0] eq '!done') {
            $retval //= 1; # Set this if it has not already been set
        } elsif ($reply[0] eq '!re') {
            $retval = 1;
        } elsif ($reply[0] eq '!trap') {
            $retval = 2;
        } elsif ($reply[0] eq '!fatal') {
            $retval = 3;
        }
       my %dataset;
        foreach my $line ( @reply ) {
            # Only consider words of the form "=var=value"
            if ( my ($key, $value) = ( $line =~ /^=([^=]+)=(.*)/s ) ) {
                $dataset{$key} = $value;
            }
        }
        push( @attrs, \%dataset ) if (keys %dataset);
        last if ($reply[0] eq '!done');
    }
    if (!@reply) {
        # network error
        return( 3, {message => 'disconnected'});
    }
    return ( $retval, @attrs );
}

=head2 $api->raw_talk( \@sentence )

=cut

sub raw_talk {
    my ( $self, $sentence_aref ) = @_;

    $self->_write_sentence( $sentence_aref );
    my ( @reply, @response );
    my $retval;

    while ( @reply = $self->_read_sentence() ) {
        if ($reply[0] eq '!done') {
            $retval //= 0;
        } elsif ($reply[0] eq '!re') {
            $retval = 1;
        } elsif ($reply[0] eq '!trap') {
            $retval = 2;
        } elsif ($reply[0] eq '!fatal') {
            $retval = 3;
        }
        foreach my $line ( @reply ) {
            push ( @response, $line );
        }
        last if ($reply[0] eq '!done');
    }
    return ( $retval, @response );
}

### ACCESSORS (overrridden extended functionality)

sub get_port {
    my ( $self ) = @_;
    $self->_get_port()
        ? $self->_get_port()
        : $self->get_use_ssl()
            ? 8729
            : 8728
    ;
}

### INTERNAL METHODS

sub _write_sentence {
    my ( $self, $sentence_aref ) = @_;

    foreach my $word ( @{$sentence_aref} ) {
        $self->_write_word( $word );
        if ( $self->get_debug() > 2 ) {
            print ">>> $word\n";
        }
    }
    $self->_write_word('');
}

sub _write_word {
    my ( $self, $word ) = @_;
    $self->_write_len( length $word );
    my $socket = $self->get_socket();
    print $socket $word;
}

sub _write_len {
    my ( $self, $len ) = @_;

    my $socket = $self->get_socket();
    if ( $len < 0x80 ) {
        print $socket chr($len);
    }
    elsif ($len < 0x4000) {
        $len |= 0x8000;
        print $socket chr(($len >> 8) & 0xFF);
        print $socket chr($len & 0xFF);
    }
    elsif ($len < 0x200000) {
        $len |= 0xC00000;
        print $socket chr(($len >> 16) & 0xFF);
        print $socket chr(($len >> 8) & 0xFF);
        print $socket chr($len & 0xFF);
    }
    elsif ($len < 0x10000000) {
        $len |= 0xE0000000;
        print $socket chr(($len >> 24) & 0xFF);
        print $socket chr(($len >> 16) & 0xFF);
        print $socket chr(($len >> 8) & 0xFF);
        print $socket chr($len & 0xFF);
    }
    else {
        print $socket chr(0xF0);
        print $socket chr(($len >> 24) & 0xFF);
        print $socket chr(($len >> 16) & 0xFF);
        print $socket chr(($len >> 8) & 0xFF);
        print $socket chr($len & 0xFF);
    }
}

# Read words until we get a word with zero length. All sentences
# begin with a word that begins with '!'
# Returns an array of words
sub _read_sentence {
    my ( $self ) = @_;

    my ( @reply );

    my $word = $self->_read_word();
    return if (!$word);

    die "Protocol error (sentence word does being with \"!\"\n" if ($word !~ /^!/);

    do {
        push( @reply, $word );
        if ( $self->get_debug() > 2 ) {
            print "<<< $word\n"
        }
    } while ( $word = $self->_read_word() );
    return (@reply );
}

# Read a word from the Mikrotik
# Return the word read (maybe zero length string), or undef on EOF or error
sub _read_word {
    my ( $self ) = @_;

    my $ret_line = '';
    my $len = eval { $self->_read_len(); }; # catch EOF
    return if !defined($len);
    if ( $len > 0 ) {
        if ( $self->get_debug() > 3 ) {
            print "recv $len\n";
        }
        my $length_received = 0;
        while ( $length_received < $len ) {
            my $line = '';
            $self->get_socket()->read( $line, $len );
            last if !defined($line) || $line eq ''; # EOF
            $ret_line .= $line; # append to $ret_line, in case we didn't get the whole word and are going round again
            $length_received += length $line;
        }
        return if length($ret_line) != $len; # EOF or a protocol error
    }
    return $ret_line;
}

# Read the length of the next word
sub _read_len {
    my ( $self ) = @_;

    if ( $self->get_debug() > 4 ) {
        print "start read_len\n";
    }

    my $len = $self->_read_byte();

    if ( ($len & 0x80) == 0x00 ) {
        if ( $self->get_debug() > 4 ) {
            print "read_len got $len\n";
        }
        return $len
    }
    elsif ( ($len & 0xC0) == 0x80 ) {
        $len &= ~0x80;
        $len <<= 8;
        $len += $self->_read_byte();
    }
    elsif ( ($len & 0xE0) == 0xC0 ) {
        $len &= ~0xC0;
        $len <<= 8;
        $len += $self->_read_byte();
        $len <<= 8;
        $len += $self->_read_byte();
    }
    elsif ( ($len & 0xF0) == 0xE0 ) {
        $len &= ~0xE0;
        $len <<= 8;
        $len += $self->_read_byte();
        $len <<= 8;
        $len += $self->_read_byte();
        $len <<= 8;
        $len += $self->_read_byte();
    }
    elsif ( ($len & 0xF8) == 0xF0 ) {
        $len = $self->_read_byte();
        $len <<= 8;
        $len += $self->_read_byte();
        $len <<= 8;
        $len += $self->_read_byte();
        $len <<= 8;
        $len += $self->_read_byte();
    }

    if ( $self->get_debug() > 4 ) {
        print "read_len got $len\n";
    }

    return $len;
}

sub _read_byte{
    my ( $self ) = @_;
    my $line = '';
    $self->get_socket()->read( $line, 1 );
    die 'EOF' if !defined($line) || length($line) != 1;
    return ord($line);
}

=head1 ABOUT

=head2 Contributors

Object-Orientated Rebuild of prior contributions, based on:

=over 4

=item *

initial release from cheesegrits in MikroTik forum: http://forum.mikrotik.com/viewtopic.php?p=108530#p108530

=item *

added C<timeout parameter> and fixes by elcamlost: https://github.com/elcamlost/mikrotik-perl-api/commit/10e5da1fd0ccb4a249ed3047c1d22c97251f666e

=item *

SSL support by akschu: https://github.com/akschu/MikroTikPerl/commit/9b689a7d7511a1639ffa2118c8e549b5cec1290d

=back

=head2 Design decisions

=over 4

=item *

Use of Moose for OO

=item *

higher compilation time of Moose based lib negligible because of slow I/O operations

=item *

Moose is more common than Moo or similar

=back

=head1 AUTHOR

Martin Gojowsky, C<martin at gojowsky.de>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mikrotik-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MikroTik-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head2 Known issues

=over 4

=item *

Quite high compile time because of using Moose. Use of a persistent running framework recommended.

=item *

Login to RouterOS v6.43rc* not possible because of a changed auth method using plaintext passwords

=back

=head1 TODO

=over 4

=item *

Add a parameter talk_timeout as an alternative for probe_before_talk that enables an actual timeout for each command.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MikroTik::API

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MikroTik-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MikroTik-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MikroTik-API>

=item * Search CPAN

L<http://search.cpan.org/dist/MikroTik-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Martin Gojowsky.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of MikroTik::API
