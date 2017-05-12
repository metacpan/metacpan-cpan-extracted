# No-op plugin example based on Data::Alias.
package IO::Stream::NoopAlias;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.2';

use Data::Alias 0.08;

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub PREPARE {
    my ($self, $fh, $host, $port) = @_;
    for (qw( out_buf out_pos out_bytes in_buf in_bytes ip is_eof )) {
        alias $self->{$_} = $self->{_master}->{$_};
    }
    $self->{_slave}->PREPARE($fh, $host, $port);
    return;
}

sub WRITE {
    my ($self) = @_;
    $self->{_slave}->WRITE();
    return;
}

sub EVENT {
    my ($self, $e, $err) = @_;
    $self->{_master}->EVENT($e, $err);
    return;
}


1;
