#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;
use Storable qw(nfreeze thaw);

$| = 1;

# Storing complex Perl data structures in memcached.
# Uses flags field to mark serialized values (flags=1 = Storable).

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub { warn "error: @_\n" },
);

my $flags_storable = 1;

sub set_data {
    my ($key, $data, $ttl, $cb) = @_;
    my $frozen = nfreeze($data);
    $mc->set($key, $frozen, $ttl // 0, $flags_storable, $cb);
}

sub get_data {
    my ($key, $cb) = @_;
    $mc->gets($key, sub {
        my ($result, $err) = @_;
        if ($err || !$result) {
            $cb->(undef, $err);
            return;
        }
        if ($result->{flags} == $flags_storable) {
            my $data = thaw($result->{value});
            $cb->($data);
        } else {
            $cb->($result->{value});
        }
    });
}

# Store a complex structure
my $user = {
    id    => 42,
    name  => 'Alice',
    roles => [qw(admin editor)],
    prefs => { theme => 'dark', lang => 'en' },
};

set_data("user:42", $user, 300, sub {
    my ($res, $err) = @_;
    die "set: $err" if $err;
    print "Stored user struct\n";

    get_data("user:42", sub {
        my ($data, $err) = @_;
        die "get: $err" if $err;

        printf "Retrieved: %s (id=%d, roles=%s)\n",
            $data->{name},
            $data->{id},
            join(', ', @{$data->{roles}});

        # Store an array
        my $items = [qw(apple banana cherry)];
        set_data("fruits", $items, 0, sub {
            get_data("fruits", sub {
                my ($data) = @_;
                printf "Fruits: %s\n", join(', ', @$data);
                $mc->disconnect;
            });
        });
    });
});

EV::run;
