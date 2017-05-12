package KiokuDB::Backend::Redis;
use Moose;

use Carp qw(croak);
use Redis;

our $VERSION = '0.02';

has '_redis' => (
    is => 'rw',
    isa => 'Redis'
);

with qw(
    KiokuDB::Backend
    KiokuDB::Backend::Serialize::Delegate
);

sub new_from_dsn_params {
    my ( $self, %args ) = @_;

    $args{debug} = 1;

    $self->new(_redis => Redis->new(%args));
}

sub delete {
    my ($self, @ids_or_entries) = @_;

    my $redis = $self->_redis;

    my @uids = map { ref($_) ? $_->id : $_ } @ids_or_entries;

    foreach my $id ( @uids ) {

        $redis->del($id);
        # TODO Error checking
    }

    return;
}

sub exists {
    my ($self, @ids) = @_;

    my @exists;

    my $redis = $self->_redis;
    foreach my $id (@ids) {

        if($redis->exists($id)) {
            push(@exists, 1);
        } else {
            push(@exists, 0);
        }
    }
    # TODO Error checking
    return @exists;
}

sub insert {
    my ($self, @entries) = @_;

    my $redis = $self->_redis;

    my @exists = $self->exists(@entries);

    foreach my $entry ( @entries ) {

        if($entry->has_prev) {
            my $ret = $redis->set(
                $entry->id => $self->serialize($entry),
            );
            # TODO Error checking
        } else {
            my $ret = $redis->setnx(
                $entry->id => $self->serialize($entry),
            );
            # TODO Error checking
        }
    }
}

sub get {
    my ($self, @ids) = @_;

    my ( $var, @ret );

    my $redis = $self->_redis;

    foreach my $id ( @ids ) {
        my $val = $redis->get($id);
        # TODO Error checking
        if(defined($val)) {
            push @ret, $val;
        } else {
            return;
        }
    }

    return map { $self->deserialize($_) } @ret;
}

1;

__END__

=head1 NAME

KiokuDB::Backend::Redis - Redis backend for KiokuDB

=head1 SYNOPSIS


    use KiokuDB::Backend::Redis;

    my $kiokudb = KiokuDB->connect('Redis:server=127.0.0.1;debug=1);
    ...

=head1 DESCRPTION

This is a KiokuDB backend for Redis, a self proclaimed data structures server.
It is rather embryonic, but passes the tests.  I expect to expand it as I
explore Redis and KiokuDB.

=head1 SEE ALSO

L<http://code.google.com/p/redis/>

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
