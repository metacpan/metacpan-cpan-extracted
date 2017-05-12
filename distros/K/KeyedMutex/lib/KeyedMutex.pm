package KeyedMutex;

use strict;
use warnings;

use Digest::MD5 qw/md5/;
use IO::Socket::INET;
use IO::Socket::UNIX;
use POSIX qw/:errno_h/;
use Socket qw/IPPROTO_TCP TCP_NODELAY/;

use KeyedMutex::Lock;

package KeyedMutex;

our $VERSION = '0.06';

my $MSG_NOSIGNAL = 0;
eval {
    $MSG_NOSIGNAL = Socket::MSG_NOSIGNAL;
};

use constant DEFAULT_SOCKPATH => '/tmp/keyedmutexd.sock';
use constant KEY_SIZE         => 16;

sub new {
    my ($klass, $opts) = @_;
    $klass = ref($klass) || $klass;
    $opts ||= {};
    my $self = bless {
        sock           => undef,
        locked         => undef,
        auto_reconnect =>
            defined $opts->{auto_reconnect} ? $opts->{auto_reconnect} : 1,
        _peer          => $opts->{sock} || DEFAULT_SOCKPATH,
    }, $klass;
    $self->_connect();
    $self;
}

sub DESTROY {
    my $self = shift;
    $self->{sock}->close if $self->{sock};
}

sub locked {
    my $self = shift;
    $self->{locked};
}

sub auto_reconnect {
    my $self = shift;
    $self->{auto_reconnect} = shift if @_;
    $self->{auto_reconnect};
}

sub lock {
    my ($self, $key, $use_raii) = @_;
    
    # check state
    die "already holding a lock\n" if $self->{locked};
    
    # send key
    my $hashed_key = md5($key);
    $self->_connect(1) unless $self->{sock};
    unless ($self->_send($hashed_key, KEY_SIZE)) {
        $self->_connect(1);
        $self->_send($hashed_key, KEY_SIZE)
            or die 'communication error';
    }
    # wait for response
    my $res;
    while ($self->{sock}->sysread($res, 1) != 1) {
        if ($! != EINTR) {
            $self->{sock}->close;
            $self->{sock} = undef;
            $res = 'R';
            last;
        }
    }
    return unless $res eq 'O';
    $self->{locked} = 1;
    return $use_raii ? KeyedMutex::Lock->_new($self) : 1;
}

sub release {
    my ($self) = @_;
    
    # check state
    die "not holding a lock\n" unless $self->{locked};
    
    unless ($self->_send('R', 1)) {
        $self->{sock}->close;
        $self->{sock} = undef;
    }
    $self->{locked} = undef;
    1;
}

sub _connect {
    my ($self, $is_reconnect) = @_;
    
    if ($is_reconnect) {
        die 'communication error' unless $self->{auto_reconnect};
        if ($self->{sock}) {
            $self->{sock}->close;
            $self->{sock} = undef;
        }
    }
    
    if ($self->{_peer} =~ /^(?:|(.*):)(\d+)$/) {
        my ($host, $port) = ($1 || '127.0.0.1', $2);
        $self->{sock} = IO::Socket::INET->new(
            PeerHost => $host,
            PeerPort => $port,
            Proto    => 'tcp',
        ) or die 'failed to connect to keyedmutexd';
        setsockopt($self->{sock}, IPPROTO_TCP, TCP_NODELAY, 1)
            or die 'failed to set TCP_NODELAY';
    } else {
        $self->{sock} = IO::Socket::UNIX->new(
            Type => SOCK_STREAM,
            Peer => $self->{_peer},
        ) or die 'failed to connect to keyedmutexd';
    }
}

sub _send {
    my ($self, $data, $size) = @_;
    local $SIG{PIPE} = 'IGNORE' unless $MSG_NOSIGNAL;
    my $ret = undef;
    eval {
        no warnings;
        $ret = $self->{sock}->send($data, $MSG_NOSIGNAL) == $size;
    };
    $ret;
}

1;

__END__

=head1 NAME

KeyedMutex - An interprocess keyed mutex

=head1 SYNOPSIS

  # start server
  % keyedmutexd >/dev/null &
  
  use KeyedMutex;
  
  my $km = KeyedMutex->new;
  
  until ($value = $cache->get($key)) {
    if (my $lock = $km->lock($key, 1)) {
      #locked read from DB
      $value = get_from_db($key);
      $cache->set($key, $value);
      last;
    }
  }

=head1 DESCRIPTION

C<KeyedMutex> is an interprocess keyed mutex.  Its intended use is to prevent sending identical requests to database servers at the same time.  By using C<KeyedMutex>, only a single client would send a request to the database, and others can retrieve the result from a shared cache (namely memcached or Cache::Swifty) instead.

=head1 THE CONSTRUCTOR

Following parameters are recognized.

=head2 sock

Optional.  Path to a unix domain socket or a tcp port on which C<keyedmutexd> is running.  Defaults to /tmp/keyedmutexd.sock.

=head2 auto_reconnect

Optional.  Whether or not to automatically reconnect to server on communication failure.  Default is on.

=head1 METHODS

=head2 lock($key, [ use_raii ])

Tries to obtain a mutex lock for given key.
When the use_raii flag is not set (or omitted), the method would return 1 if successful, or undef if not.  If successful, the client should later on release the lock by calling C<release>.  A return value undef means some other client that held the lock has released it.
When the use_raii flag is being set, the method would return a C<KeyedMutex::Lock> object when successful.  The lock would be automatically released when the lock object is being destroyed.

=head2 release

Releases the lock acquired by a procedural-style lock (i.e. use_raii flag not being set).

=head2 locked

Returns if the object is currently holding a lock.

=head2 auto_reconnect

Sets or retrieves auto_reconnect flag.

=head1 SEE ALSO

http://labs.cybozu.co.jp/blog/kazuhoatwork/

=head1 AUTHOR

Copyright (c) 2007 Cybozu Labs, Inc.  All rights reserved.

written by Kazuho Oku E<lt>kazuhooku@gmail.comE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under th
e same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
