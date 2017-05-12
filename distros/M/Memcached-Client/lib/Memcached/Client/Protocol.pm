package Memcached::Client::Protocol;
BEGIN {
  $Memcached::Client::Protocol::VERSION = '2.01';
}
# ABSTRACT: Base Class For Memcached::Client Protocol implementations

use strict;
use warnings;
use Memcached::Client::Log qw{DEBUG LOG};


sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    return $self;
}


sub decode {
    my ($self, $data, $flags) = @_;
    return $self->{serializer}->deserialize ($self->{compressor}->decompress ($data, $flags));
}


sub encode {
    my ($self, $command, $value) = @_;
    if ($command ne 'append' && $command ne 'prepend') {
        $self->log ("Encoding request data") if DEBUG;
        return $self->{compressor}->compress ($self->{serializer}->serialize ($value));
    } else {
        $self->log ("Nothing to do") if DEBUG;
        return $value, 0;
    }
}



sub log {
    my ($self, $format, @args) = @_;
    my $prefix = ref $self || $self;
    $prefix =~ s,Memcached::Client::Protocol::,Protocol/,;
    LOG ("$prefix> " . $format, @args);
}


sub prepare_handle {
    return sub {};
}


sub rlog {
    my ($self, $connection, $request, $message) = @_;
    my $prefix = ref $self || $self;
    $prefix =~ s,Memcached::Client::Protocol::,Protocol/,;
    LOG ("$prefix/%s> %s = %s", $connection->{server}, join (" ", $request->{command}, $request->{key}), $message);
}


1;

__END__
=pod

=head1 NAME

Memcached::Client::Protocol - Base Class For Memcached::Client Protocol implementations

=head1 VERSION

version 2.01

=head1 SYNOPSIS

  package Memcached::Client::Protocol::NewProtocol;
  use strict;
  use base qw{Memcached::Client::Protocol};

=head1 METHODS

=head2 new

C<new()> creates the protocol object.

=head2 C<decode>

=head2 C<encode>

=head2 C<log>

Log the specified message with an appropriate prefix derived from the
class name.

=head2 prepare_handle

This routine is handed the raw file handle before any connection is
done, for any massaging the procotol may need to do to it (this is
typically just the binary protocol setting binmode to true).

=head2 rlog

Knows how to extract information from connections and requests.

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

