package Fork::Promise;
use 5.010;
use strict;
use warnings;

use Class::Tiny { timer_holders => sub { return {} } };
use Promises qw(deferred);
use AnyEvent;

our $VERSION = '0.1.0';

sub run {
    my ($self, $child_cb, $process_data) = @_;

    my $d = deferred();

    my $pid = fork;
    if ($pid) {
        $self->timer_holders->{$pid} = (
            AnyEvent->child(
                pid => $pid,
                cb => sub {
                    my ($pid, $exitcode) = @_;
                    if (my $error = _get_error($exitcode)) {
                        $d->reject($error, $process_data)
                    }
                    else {
                        $d->resolve($exitcode, $process_data);
                    }
                    undef $self->timer_holders->{$pid};
                }
            )
        );

        return $d->promise
    }
    elsif ($pid == 0) {
        $child_cb->();
        exit 0;
    }
    else {
        $d->reject('Unable to fork!', $process_data);
    }

    return $d->promise
}

sub _get_error {
    my ($code) = @_;

    my $error;
    $error = "Child killed by signal ".( $code & 0x7F ) if $code & 0x7F;
    $error = "Child returned error ".( $code >> 8 ) if $code >> 8;

    return $error
}

1;
__END__

=encoding utf-8

=head1 NAME

Fork::Promise - run a code in a subprocess and get a promise that it ended

=head1 SYNOPSIS

    use Fork::Promise;
    use AnyEvent;

    my $pp = Fork::Promise->new();
    my $condvar = AnyEvent->condvar;

    my $promise = $pp->run(sub { sleep 1 });

=head1 DESCRIPTION

Fork::Promise implements only one method - run. It runs given code in a
subprocess and registers AnyEvent child watcher which resolves promise returned
by run method.

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Miroslav Tynovsky E<lt>tynovsky@avast.comE<gt>

=cut
