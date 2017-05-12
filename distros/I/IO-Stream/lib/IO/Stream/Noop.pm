# No-op plugin example.
package IO::Stream::Noop;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.2';

use IO::Stream::const;

sub new {
    my ($class) = @_;
    my $self = bless {
        out_buf     => q{},                 # modified on: OUT
        out_pos     => undef,               # modified on: OUT
        out_bytes   => 0,                   # modified on: OUT
        in_buf      => q{},                 # modified on: IN
        in_bytes    => 0,                   # modified on: IN
        ip          => undef,               # modified on: RESOLVED
        is_eof      => undef,               # modified on: EOF
    }, $class;
    return $self;
}

sub PREPARE {
    my ($self, $fh, $host, $port) = @_;
    $self->{_slave}->PREPARE($fh, $host, $port);
    return;
}

sub WRITE {
    my ($self) = @_;
    my $m = $self->{_master};
    $self->{out_buf}    = $m->{out_buf};
    $self->{out_pos}    = $m->{out_pos};
    $self->{out_bytes}  = $m->{out_bytes};
    $self->{_slave}->WRITE();
    return;
}

sub EVENT {
    my ($self, $e, $err) = @_;
    my $m = $self->{_master};
    if ($e & OUT) {
        $m->{out_buf}   = $self->{out_buf};
        $m->{out_pos}   = $self->{out_pos};
        $m->{out_bytes} = $self->{out_bytes};
    }
    if ($e & IN) {
        $m->{in_buf}    .= $self->{in_buf};
        $m->{in_bytes}  += $self->{in_bytes};
        $self->{in_buf}  = q{};
        $self->{in_bytes}= 0;
    }
    if ($e & RESOLVED) {
        $m->{ip} = $self->{ip};
    }
    if ($e & EOF) {
        $m->{is_eof} = $self->{is_eof};
    }
    $m->EVENT($e, $err);
    return;
}


1;
