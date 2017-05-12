package HTTP::Daemon::Patch::IPv6;

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

our $VERSION = '0.06'; # VERSION

use IO::Socket qw(AF_INET INADDR_ANY INADDR_LOOPBACK inet_ntoa);
my $p_url = sub {
    my $ctx  = shift;
    my $orig = $ctx->{orig};

    my $self = shift;
    my $url = $self->_default_scheme . "://";
    my $addr = $self->sockaddr;
    if (!$addr || $addr eq INADDR_ANY || $self->isa("IO::Socket::INET6")) {
        require Sys::Hostname;
        $url .= lc Sys::Hostname::hostname();
    }
    elsif ($addr eq INADDR_LOOPBACK) {
        $url .= inet_ntoa($addr);
    }
    else {
        $url .= gethostbyaddr($addr, AF_INET) || inet_ntoa($addr);
    }
    my $port = $self->sockport;
    $url .= ":$port" if $port != $self->_default_port;
    $url .= "/";
    $url;
};

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action => 'wrap',
                mod_version => qr/^6\.0.+/,
                sub_name => 'url',
                code => $p_url,
            },
        ],
    };
}

1;
# ABSTRACT: Avoid error when IO::Socket::INET6 is around


__END__
=pod

=head1 NAME

HTTP::Daemon::Patch::IPv6 - Avoid error when IO::Socket::INET6 is around

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use HTTP::Daemon::Patch::IPv6;

=head1 DESCRIPTION

This module contains patch for HTTP::Daemon::url() for
https://rt.cpan.org/Ticket/Display.html?id=71395

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

