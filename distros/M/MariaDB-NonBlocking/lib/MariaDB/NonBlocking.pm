package MariaDB::NonBlocking;

use v5.18.2; # needed for __SUB__, implies strict
use warnings;
use Sub::StrictDecl;

use constant DEBUG => $ENV{MariaDB_NonBlocking_DEBUG} // 0;
sub TELL (@) {
    say STDERR __PACKAGE__, ': ', join " ", @_;
}

use Carp (); # for confess

=head1 NAME

MariaDB::NonBlocking - Nonblocking connections to MySQL using libmariadbclient

=head1 VERSION

Version 0.20

=cut

use Exporter qw(import);
use XSLoader qw();

BEGIN {
    our $VERSION = '0.20';
    XSLoader::load(__PACKAGE__);
};

our @EXPORT_OK = qw/
    MYSQL_WAIT_READ
    MYSQL_WAIT_WRITE
    MYSQL_WAIT_EXCEPT
    MYSQL_WAIT_TIMEOUT
/;
our %EXPORT_TAGS = (
    'all' => [ @EXPORT_OK ]
);

use constant {
    OPERATION_RUN_QUERY => 0x01,
    OPERATION_CONNECT   => 0x02,
    OPERATION_PING      => 0x04,
};

# Better to import this, since it is a custom op
use Ref::Util qw(is_arrayref is_coderef);
use Scalar::Util qw(weaken);

sub new {
    my $class = shift;
    my $obj = $class->init;
    return $obj;
}

sub ___clean_object {
    my ($maria) = @_;
    delete $maria->{pending};
    delete $maria->{in_use};
    $maria->_clean_object
}

sub _clean_object { ... } # Must be overriden

sub _set_timer { # Must be overriden
    my ($maria, $timer_type, $timeout_s, $cb) = @_;
    ...
}
sub _disarm_timer { # Must be overriden
    my ($maria, $timer_type) = @_;
    ...
}

sub _set_io_watcher { # Must be overriden
    my ($maria, $fd, $wait_type, $cb) = @_;
    ...
}

sub start_work {
    my ($maria, $operation, $operation_args) = @_;
    $maria->{in_use} = 1;
    if ( $operation == OPERATION_RUN_QUERY ) {
        return $maria->run_query_start( @{ $operation_args || [] } );
    }
    elsif ( $operation == OPERATION_CONNECT ) {
        return $maria->connect_start($operation_args);
    }
    elsif ( $operation == OPERATION_PING ) {
        return $maria->ping_start;
    }
    else {
        ...
    }
}

sub work_done {
    my ($maria, $operation) = @_;
    if ( $operation == OPERATION_RUN_QUERY ) {
        return $maria->query_results;
    }
    elsif ( $operation == OPERATION_PING ) {
        return $maria->ping_result;
    }
    elsif ( $operation == OPERATION_CONNECT ) {
        return $maria;
    }
    else {
        ...
    }
}

sub ____run {
    my (
        $outside_maria,
        $operation,
        $success_cb_orig,
        $failure_cb_orig,
        $perl_timeout,
        $start_work_args,
    ) = @_;

    if ( !is_coderef($failure_cb_orig) ) {
        Carp::confess(ref($outside_maria) . " was not given a coderef to failure_cb");
    }

    if ( exists $outside_maria->{in_use} ) {
        $failure_cb_orig->("Attempted to reuse connection $outside_maria which is already running an async operation");
        return;
    }

    if ( !is_coderef($success_cb_orig) ) {
        $failure_cb_orig->(ref($outside_maria) . " was not given a coderef to success_cb");
        return;
    }

    # $maria is weakened here, as otherwise we would
    # have this cycle:
    # $maria->{watchers}{any}{cb} => sub { ...; $maria; ...; }
    my $maria = $outside_maria; # DO NOT USE $outside_maria AFTER THIS LINE
    weaken($maria);

    my $done;
    my $success_cb = sub {
        $done = 1;
        $maria->___clean_object() if $maria;
        goto &$success_cb_orig;
    };
    my $failure_cb = sub {
        $done = 1;
        $maria->___clean_object() if $maria;
        goto &$failure_cb_orig;
    };

    my $previous_wait_for = 0;

    my $have_timer_set_up;
    my $watcher_ready_cb = sub { eval {
        return 1 if $done; # Something previously went wrong, we should not be back here!
        die "Connection object went away" unless $maria;

        my ($events_for_mysql) = @_;

        # Always disarm the mysql-specified timer
        if ( $have_timer_set_up ) {
            $have_timer_set_up = 0;
            $maria->_disarm_timer;
        }

        my $wait_for = $previous_wait_for
                     ? $maria->cont($events_for_mysql)
                     : $maria->start_work($operation, $start_work_args)
        ;

        # If we still don't need to wait for anything, that
        # means we are done with the query! Grab the results.
        if ( !$wait_for ) {
            # query we were waiting on finished!
            # Get the results

            # Ran all the queries! We can resolve and go home
            $success_cb->($maria->work_done($operation));
            return 1;
        }

        if ( $wait_for & MYSQL_WAIT_TIMEOUT ) {
            # If we get here, a timeout was set for this connection.

            # remove for the next check if()
            $wait_for &= ~MYSQL_WAIT_TIMEOUT;

            my $timeout_ms = $maria->get_timeout_value_ms();
            if ( $timeout_ms ) {
                # Bug in the client lib makes the no-timeout case come
                # back as 0 timeout.  So only create the timer if we
                # actually have a timeout.
                # https://lists.launchpad.net/maria-developers/msg09971.html

                $have_timer_set_up = 1;
                # A timeout was specified with the connection.
                # This will call this same callback;
                # query_cont will eventually call
                # the relevant _cont method with MYSQL_WAIT_TIMEOUT,
                # and let the driver decide what to do next.
                $maria->_set_timer(
                    'timer',
                    $timeout_ms/1000, # AE wants fractional seconds
                    __SUB__,
                );
            }
        }

        if ( $wait_for != $previous_wait_for ) {
            $previous_wait_for = $wait_for;
            # Server wants us to wait on something else, so
            # we can't reuse the previous mask.
            # e.g. we had a watcher waiting on the socket
            # being readable, but we need to wait for it to
            # become writeable (or both) instead.
            # This almost never happens, but we need to
            # support it for SSL renegotiation.
            $maria->_set_io_watcher(
                $maria->mysql_socket_fd,
                $wait_for & ~MYSQL_WAIT_TIMEOUT,
                __SUB__,
            );
        }

        return 1;
    } or do {
        return if $done;
        my $error = $@ || 'Zombie error';
        $failure_cb->($error);
    }};

    # Start the query/connect/etc
    $watcher_ready_cb->();

    # If either of these is set, we finished that query immediately
    return if $done;

    $maria->_set_timer(
        'global_timer',
        $perl_timeout,
        sub {
            return if $done;
            DEBUG && TELL "Global timeout reached";

            $failure_cb->(
                "execution was interrupted by perl, maximum execution time exceeded (timeout=$perl_timeout)"
            );
        },
    ) if $perl_timeout;

    $maria->{pending} = $failure_cb;

    return;
}

sub DESTROY {
    my $self = shift;

    my $pending_num = 0;
    if ( my $reject_cb = delete $self->{pending} ) {
        $pending_num++;
        $reject_cb->("Connection object went away");
    }
    DEBUG && $pending_num && TELL "Had $pending_num operations still running when we were freed";
}

sub run_query {
    my ($conn, $sql, $extra, $bind, $success_cb, $failure_cb, $perl_timeout) = @_;

    my $sql_with_args = [ $sql, $extra, is_arrayref($bind) ? $bind : () ];

    $conn->____run(
        OPERATION_RUN_QUERY,
        $success_cb,
        $failure_cb,
        $perl_timeout || 0,
        $sql_with_args,
    );
}

sub ping {
    my ($conn, $success_cb, $failure_cb, $perl_timeout) = @_;

    $conn->____run(
        OPERATION_PING,
        $success_cb,
        $failure_cb,
        $perl_timeout || 0,
    );
}

sub connect {
    my ($conn, $connect_args, $success_cb, $failure_cb, $perl_timeout) = @_;

    $conn->____run(
        OPERATION_CONNECT,
        $success_cb,
        $failure_cb,
        $perl_timeout || 0,
        $connect_args,
    );
}

=head1 SYNOPSIS

A very thin wrapper around the MariaDB non-blocking library to MySQL.
You probably want to check out L<MariaDB::NonBlocking::Promises> for
something that you can actually use for querying!

This class provides access to the basic functionality, so
without adding some sort of eventloop around it it won't be
very useful.

    use MariaDB::NonBlocking;
    my $maria = MariaDB::NonBlocking->new;

    my $wait_for = $maria->connect_start({
                    host        => ...,
                    port        => ...,
                    user        => ...,
                    password    => ...,
                    database    => ...,
                    unix_socket => ...,

                    charset     => ...,

                    mysql_use_results  => undef, # not very useful yet

                    mysql_connect_timeout => ...,
                    mysql_write_timeout   => ...,
                    mysql_read_timeout    => ...,

                    mysql_init_command => ...,
                    mysql_compression  => ...,

                    # NOT TESTED, LIKELY TO SEGFAULT, DO NOT USE YET:
                    ssl => {
                        key    => ...,
                        cert   => ...,
                        ca     => ...,
                        capath => ...,
                        cipher => ...,
                        reject_unauthorized => 1,
                    },
               });

    # Your event loop here
    while ( $wait_for ) {

    }

=head1 EXPORT

Four constants are optionally exported.  They can be logically-and'd with
the status (C<$wait_for>) returned by the C<_start> and C<_cont> methods,
to figure out what events the library wants us to wait on.

They should also be used to communicate with the library what events happened.

=head2 MYSQL_WAIT_READ

=head2 MYSQL_WAIT_WRITE

=head2 MYSQL_WAIT_EXCEPT

=head2 MYSQL_WAIT_TIMEOUT

=head1 SUBROUTINES/METHODS

=head2 function2

=head1 AUTHOR

Brian Fraser, C<< <fraserbn at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mariadb-nonblocking at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MariaDB-NonBlocking>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MariaDB::NonBlocking


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MariaDB-NonBlocking>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MariaDB-NonBlocking>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MariaDB-NonBlocking>

=item * Search CPAN

L<http://search.cpan.org/dist/MariaDB-NonBlocking/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 Brian Fraser.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of MariaDB::NonBlocking
