package Memcached::Client::Selector::Traditional;
BEGIN {
  $Memcached::Client::Selector::Traditional::VERSION = '2.01';
}
#ABSTRACT: Implements Traditional Memcached Hashing

use strict;
use warnings;
use Memcached::Client::Log qw{DEBUG};
use String::CRC32 qw{crc32};
use base qw{Memcached::Client::Selector};


sub set_servers {
    my ($self, $list) = @_;
    $self->log ("list: %s", $list) if DEBUG;
    if ($list) {
        my $count = scalar @{$list};
        if (1 < $count) {
            $self->{buckets} = [];
            for my $server (@{$list}) {
                if (ref $server eq "ARRAY") {
                    for (1..$server->[1]) {
                        push @{$self->{buckets}}, $server->[0];
                    }
                } else {
                    push @{$self->{buckets}}, $server;
                }
            }
            $self->{bucketcount} = scalar @{$self->{buckets}};
            $self->log ("bucket count: %d\nbucket list: %s", $self->{bucketcount}, $self->{buckets}) if DEBUG;
        } elsif (1 == $count) {
            $self->{_single_sock} = ref $list->[0] ? $list->[0]->[0] : $list->[0];
        }
    } else {
        delete $self->{buckets};
        delete $self->{bucket_count};
        delete $self->{_single_sock};
    }

    1;
}

sub get_server {
    my ($self, $key, $namespace) = @_;
    return unless $key;
    return $self->{_single_sock} if $self->{_single_sock};
    return unless $self->{buckets};
    $namespace ||= "";
    my $hash = ref $key ? int ($key->[0]) : crc32 ($namespace . $key) >> 16 & 0x7fff;
    $self->log ("Hash is %d, bucket # %d, bucket %s", $hash, $hash % $self->{bucketcount}, $self->{buckets}->[$hash % $self->{bucketcount}]) if DEBUG;
    return $self->{buckets}->[$hash % $self->{bucketcount}];
}

1;

__END__
=pod

=head1 NAME

Memcached::Client::Selector::Traditional - Implements Traditional Memcached Hashing

=head1 VERSION

version 2.01

=head1 SYNOPSIS

This code is intended to be strictly compatible with Cache::Memcached
in the presence of the no_rehash constructor parameter (since I agree
with Tomash Brechko, the author of Cache::Memcached::Fast, that
rehashing is a consistency mistake waiting to happen).

I initially just copied the code from Cache::Memcached, though I then
tweaked it extensively, therefore I reproduce the original information
from Cache::Memcached:

=head1 ORIGINAL COPYRIGHT

This module is Copyright (c) 2003 Brad Fitzpatrick.  All rights
reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 ORIGINAL WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 ORIGINAL FAQ

See the memcached website: http://www.danga.com/memcached/

=head1 ORIGINAL AUTHORS

Brad Fitzpatrick <brad@danga.com>

Anatoly Vorobey <mellon@pobox.com>

Brad Whitaker <whitaker@danga.com>

Jamie McCarthy <jamie@mccarthy.vg>

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

