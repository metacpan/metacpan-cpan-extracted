package MariaDB::NonBlocking::Promises;
use parent 'MariaDB::NonBlocking::Event';

use v5.18.2; # needed for __SUB__, implies strict
use warnings;

BEGIN {
    my $loaded_ok;
    local $@;
    eval { require Sub::StrictDecl; $loaded_ok = 1; };
    Sub::StrictDecl->import if $loaded_ok;
}

use Promises (); # for deferred

sub run_multiple_queries {
    my ($conn, $remaining_sqls, $extras) = @_;

    my $deferred = Promises::deferred();

    $extras //= {};
    local $extras->{success_cb} = sub { $deferred->resolve(@_) };
    local $extras->{failure_cb} = sub { $deferred->reject(@_) };
    $conn->SUPER::run_multiple_queries($remaining_sqls, $extras);

    return $deferred->promise;
}

sub ping {
    my ($conn, $extras) = @_;

    my $deferred = Promises::deferred();

    $extras //= {};
    local $extras->{success_cb} = sub { $deferred->resolve(@_) };
    local $extras->{failure_cb} = sub { $deferred->reject(@_) };
    $conn->SUPER::ping($extras);

    return $deferred->promise;
}

sub connect {
    my ($conn, $connect_args, $extras) = @_;

    my $deferred = Promises::deferred();

    $extras //= {};
    local $extras->{success_cb} = sub { $deferred->resolve(@_) };
    local $extras->{failure_cb} = sub { $deferred->reject(@_) };
    $conn->SUPER::connect($connect_args, $extras);

    return $deferred->promise;
}

1;
