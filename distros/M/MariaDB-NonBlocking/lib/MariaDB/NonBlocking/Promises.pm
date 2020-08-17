package MariaDB::NonBlocking::Promises;
use parent 'MariaDB::NonBlocking::Event';

use v5.18.2; # needed for __SUB__, implies strict
use warnings;
use Sub::StrictDecl;

use AnyEvent::XSPromises (); # for deferred

sub run_query {
    my ($conn, $sql, $bind, $extra) = @_;

    my $deferred = AnyEvent::XSPromises::deferred();

    $conn->SUPER::run_query(
        $sql, $extra, $bind,
        sub { $deferred->resolve(@_) if $deferred },
        sub { $deferred->reject(@_)  if $deferred },
        $extra->{perl_timeout} || 0,
    );

    return $deferred->promise;
}

sub ping {
    my ($conn, $extra) = @_;

    my $deferred = AnyEvent::XSPromises::deferred();

    $conn->SUPER::ping(
        sub { $deferred->resolve(@_) if $deferred },
        sub { $deferred->reject(@_)  if $deferred },
        $extra->{perl_timeout} || 0,
    );

    return $deferred->promise;
}

sub connect {
    my ($conn, $connect_args, $extra) = @_;

    my $deferred = AnyEvent::XSPromises::deferred();

    $conn->SUPER::connect(
        $connect_args,
        sub { $deferred->resolve(@_) if $deferred },
        sub { $deferred->reject(@_)  if $deferred },
        $extra->{perl_timeout},
    );

    return $deferred->promise;
}

1;
