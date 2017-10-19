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

sub run_query {
    my ($conn, $remaining_sqls, $extras) = @_;

    my $deferred = Promises::deferred();

    $conn->SUPER::run_query($remaining_sqls, $extras,
        sub { $deferred->resolve(@_) },
        sub { $deferred->reject(@_) },
    );

    return $deferred->promise;
}

sub ping {
    my ($conn, $extras) = @_;

    my $deferred = Promises::deferred();

    $conn->SUPER::ping($extras,
        sub { $deferred->resolve(@_) },
        sub { $deferred->reject(@_) },
    );

    return $deferred->promise;
}

sub connect {
    my ($conn, $connect_args, $extras) = @_;

    my $deferred = Promises::deferred();

    $conn->SUPER::connect($connect_args, $extras,
        sub { $deferred->resolve(@_) },
        sub { $deferred->reject(@_) },
    );

    return $deferred->promise;
}

1;
