package LWP::Protocol::https::connect;

use strict;
use warnings;

our $VERSION = '6.09'; # VERSION

require LWP::Protocol::https;
our @ISA = qw(LWP::Protocol::https);
LWP::Protocol::implementor('https::connect' => 'LWP::Protocol::https::connect');

sub new {
    my $self = shift->SUPER::new(@_);
    $self->{scheme} =~ s/::connect$//;
    $self;
}

sub _extra_sock_opts {
    my $self = shift;
    my($host, $port) = @_;
    my @extra_sock_opts = $self->SUPER::_extra_sock_opts(@_);
    return (@extra_sock_opts, @{$self->{proxy_connect_opts}});
}

1;

