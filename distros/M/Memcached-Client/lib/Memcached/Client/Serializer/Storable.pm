package Memcached::Client::Serializer::Storable;
BEGIN {
  $Memcached::Client::Serializer::Storable::VERSION = '2.01';
}
#ABSTRACT: Implements Memcached Serializing using Storable

use strict;
use warnings;
use Memcached::Client::Log qw{DEBUG LOG};
use Storable qw{nfreeze thaw};
use base qw{Memcached::Client::Serializer};

use constant F_STORABLE => 1;

sub deserialize {
    my ($self, $data, $flags) = @_;

    return unless defined $data;

    $flags ||= 0;

    if ($flags & F_STORABLE) {
        $self->log ("Deserializing data") if DEBUG;
        $data = thaw $data;
    }

    return $data;
}

sub serialize {
    my ($self, $data) = @_;

    return unless defined $data;

    my $flags = 0;

    if (ref $data) {
        $self->log ("Serializing data") if DEBUG;
        $data = nfreeze $data;
        $flags |= F_STORABLE;
    }

    return ($data, $flags);
}


sub log {
    my ($self, $format, @args) = @_;
    LOG ($format, @args);
}

1;

__END__
=pod

=head1 NAME

Memcached::Client::Serializer::Storable - Implements Memcached Serializing using Storable

=head1 VERSION

version 2.01

=head1 METHODS

=head2 log

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

