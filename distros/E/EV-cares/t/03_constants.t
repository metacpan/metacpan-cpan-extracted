use strict;
use warnings;
use Test::More;
use EV::cares qw(:all);

my %tag = %EV::cares::EXPORT_TAGS;

# every constant in every tag should resolve to a defined integer
for my $tag (sort keys %tag) {
    next if $tag eq 'all';
    for my $name (@{$tag{$tag}}) {
        my $sub = EV::cares->can($name) or do {
            fail("$name (in :$tag) is not a constant in EV::cares");
            next;
        };
        my $val = $sub->();
        ok(defined $val, ":$tag/$name defined");
        like($val, qr/^-?\d+$/, ":$tag/$name is integer (got $val)");
    }
}

# :all is union of subtags, no duplicates
{
    my %seen;
    my @union;
    for my $tag (grep $_ ne 'all', keys %tag) {
        for my $n (@{$tag{$tag}}) {
            push @union, $n unless $seen{$n}++;
        }
    }
    is_deeply [sort @{$tag{all}}], [sort @union], ':all is dedup union of subtags';
}

# specific record-type values
is(T_A,     1,   'T_A   == 1');
is(T_AAAA,  28,  'T_AAAA == 28');
is(T_HTTPS, 65,  'T_HTTPS == 65');
is(T_SVCB,  64,  'T_SVCB  == 64');
is(C_IN,    1,   'C_IN   == 1');

# AF_* matches Socket
{
    require Socket;
    is(AF_INET,   Socket::AF_INET(),   'AF_INET matches Socket');
    is(AF_INET6,  Socket::AF_INET6(),  'AF_INET6 matches Socket');
}

done_testing;
