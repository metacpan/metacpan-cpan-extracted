package IO::Stream::EV;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.3';

use IO::Stream::const;

use Scalar::Util qw( weaken );
use Socket qw( inet_aton sockaddr_in );
use EV;
use AnyEvent::DNS;

# States:
use constant RESOLVING      => 1;
use constant CONNECTING     => 2;
use constant HANDLING       => 3;


sub new {
    my $self = bless {
        fh          => undef,
        _state      => 0,       # RESOLVING -> CONNECTING -> HANDLING
        _r          => undef,   # read watcher
        _w          => undef,   # write watcher
        _t          => undef,   # timer watcher
        _cb_r       => undef,   # read callback
        _cb_w       => undef,   # write callback
        _cb_t       => undef,   # timer callback
    }, __PACKAGE__;

    my $this = $self;
    weaken($this);
    $self->{_cb_t} = sub { $this->T() };
    $self->{_cb_r} = sub { $this->R() };
    $self->{_cb_w} = sub { $this->W() };

    return $self;
}

sub PREPARE {
    my ($self, $fh, $host, $port) = @_;
    $self->{fh} = $fh;
    if (!defined $host) {
        $self->{_state} = HANDLING;
        $self->{_r} = EV::io($fh, EV::READ, $self->{_cb_r});
    }
    else {
        $self->{_state} = RESOLVING;
        _resolve($host, $self, sub {
            my ($self, $ip) = @_;
            $self->{_state} = CONNECTING;
            # TODO try other ip on failed connect?
            connect $self->{fh}, sockaddr_in($port, inet_aton($ip));
            $self->{_r} = EV::io($fh, EV::READ, $self->{_cb_r});
            $self->{_w} = EV::io($fh, EV::WRITE, $self->{_cb_w});
            $self->{_t} = EV::timer(TOCONNECT, 0, $self->{_cb_t});
            $self->{_master}{ip} = $ip;
            $self->{_master}->EVENT(RESOLVED);
        });
    }
    return;
}

sub WRITE {
    my ($self) = @_;
    if ($self->{_state} == HANDLING) {
        $self->{_cb_w}->();
    }
    return;
}

sub _resolve {
    my ($host, $plugin, $cb) = @_;
    if ($host =~ /\A\d{1,3}[.]\d{1,3}[.]\d{1,3}[.]\d{1,3}\z/xms) {
        $cb->($plugin, $host);
    }
    else {
        weaken($plugin);
        # AnyEvent::DNS has own timeouts, so we don't setup own here.
        AnyEvent::DNS::a $host, sub {
            my (@a) = @_;
            return if !$plugin;
            if (@a) {
                $cb->($plugin, @a);
            }
            else {
                $plugin->{_master}->EVENT(0, EDNS);
            }
            return;
        };
    }
    return;
}

sub T {
    my ($self) = @_;
    my $m = $self->{_master};
    $m->EVENT(0, $self->{_state} == CONNECTING ? ETOCONNECT : ETOWRITE);
    return;
}

sub R {
    my ($self) = @_;
    my $m = $self->{_master};
    my $n = sysread $self->{fh}, $m->{in_buf}, BUFSIZE, length $m->{in_buf};
    if (defined $n) {
        if ($n) {
            $m->{in_bytes} += $n;
            $m->EVENT(IN);
        }
        elsif (!$m->{is_eof}) {         # EOF delivered only once
            $m->{is_eof} = 1;
            $m->EVENT(EOF);
        }
    }
    elsif ($! != EAGAIN) {              # may need to handle EINTR too
        $m->EVENT(0, $!);
    }
    return;
}

sub W {
    my ($self) = @_;
    my $m = $self->{_master};
    my $e = 0;

    if ($self->{_state} == CONNECTING) {
        $self->{_state} = HANDLING;
        undef $self->{_t};
        undef $self->{_w};
        $e |= CONNECTED;
    }

    my $len = length $m->{out_buf};
    my $has_out = defined $m->{out_pos} ? ($len > $m->{out_pos}) : ($len>0);
    if ($has_out) {
        my $n = syswrite $self->{fh}, $m->{out_buf}, BUFSIZE, $m->{out_pos}||0;
        if (!defined $n) {
            if ($! != EAGAIN) {
                $m->EVENT($e, $!);
                return;             # WARNING leave {_w} unchanged
            }
        }
        else {
            $m->{out_bytes} += $n;
            if (defined $m->{out_pos}) {
                $m->{out_pos} += $n;
                $has_out = $len > $m->{out_pos};
            }
            else {
                substr $m->{out_buf}, 0, $n, q{};
                $has_out = $len > $n;
            }
            if ($self->{_t}) {
                $self->{_t} = EV::timer(TOWRITE, 0, $self->{_cb_t});
            }
            $e |= $has_out ? OUT : (OUT|SENT);
        }
    }

    if ($self->{_w} && !$has_out) {
        undef $self->{_w};
        undef $self->{_t};
    }
    elsif (!$self->{_w} && $has_out) {
        $self->{_w} = EV::io($self->{fh}, EV::WRITE, $self->{_cb_w});
        $self->{_t} = EV::timer(TOWRITE, 0, $self->{_cb_t});
    }

    $m->EVENT($e);
    return;
}


1;
