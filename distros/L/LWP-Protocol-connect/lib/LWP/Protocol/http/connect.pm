package LWP::Protocol::http::connect;

use strict;
use warnings;

our $VERSION = '6.09'; # VERSION

require LWP::Protocol::http;
our @ISA = qw(LWP::Protocol::http);
LWP::Protocol::implementor('http::connect' => 'LWP::Protocol::http::connect');

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

