package Lim::Util::DBI;

use common::sense;
use Carp;
use Scalar::Util qw(weaken);

use Log::Log4perl ();
use DBI ();
use JSON::XS ();

use AnyEvent ();
use AnyEvent::Util ();

use Lim ();

=encoding utf8

=head1 NAME

Lim::Util::DBI - Create a DBH that is executed in a forked process

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our %METHOD = (
    connect => 1,
    disconnect => 1,
    execute => 1,
    begin_work => 1,
    commit => 1,
    rollback => 1
);

=head1 SYNOPSIS

=over 4

use Lim::Util::DBI;

=back

=head1 METHODS

=over 4

=item new

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $dbi = shift;
    my $user = shift;
    my $password = shift;
    my %args = ( @_ );
    my $self = {
        logger => Log::Log4perl->get_logger($class),
        json => JSON::XS->new->utf8->convert_blessed,
        busy => 0
    };
    bless $self, $class;
    weaken($self->{logger});
    my $real_self = $self;
    weaken($self);

    unless (defined $dbi) {
        confess __PACKAGE__, ': Missing dbi connection string';
    }
    unless (defined $args{on_connect} and ref($args{on_connect}) eq 'CODE') {
        confess __PACKAGE__, ': Missing on_connect or it is not CODE';
    }

    my $on_connect = delete $args{on_connect};

    if (defined $args{on_error}) {
        unless (ref($args{on_error}) eq 'CODE') {
            confess __PACKAGE__, ': on_error is not CODE';
        }
        $self->{on_error} = delete $args{on_error};
    }

    my ($child, $parent) = AnyEvent::Util::portable_socketpair;
    unless (defined $child and defined $parent) {
        confess __PACKAGE__, ': Unable to create client/server socket pairs: ', $!;
    }

    AnyEvent::Util::fh_nonblocking $child, 1;
    $self->{child} = $child;

    my $pid = fork;

    if ($pid) {
        #
        # Parent process
        #

        close $parent;

        $self->{child_pid} = $pid;
        $self->{child_watcher} = AnyEvent->io(
            fh => $child,
            poll => 'r',
            cb => sub {
                unless (defined $self and exists $self->{child}) {
                    return;
                }

                my $response;
                my $len = sysread $self->{child}, my $buf, 64*1024;
                if ($len > 0) {
                    undef $@;

                    eval {
                        $response = $self->{json}->incr_parse($buf);
                    };
                    if ($@) {
                        Lim::DEBUG and $self->{logger}->debug('Response JSON parse failed: ', $@);
                        $response = [];
                    }
                    else {
                        my $errstr = shift @$response;
                        if ($errstr) {
                            $@ = $errstr;
                        }
                    }
                }
                elsif (defined $len) {
                    $@ = 'Unexpected EOF';
                    Lim::DEBUG and $self->{logger}->debug($@);

                    shutdown($self->{child}, 2);
                    close(delete $self->{child});
                    $response = [];
                }
                elsif ($! != Errno::EAGAIN) {
                    $@ = 'Unable to read from child: '.$!;
                    Lim::DEBUG and $self->{logger}->debug($@);

                    shutdown($self->{child}, 2);
                    close(delete $self->{child});
                    $response = [];
                }

                if (defined $response and exists $self->{cb}) {
                    unless (ref($response) eq 'ARRAY') {
                        $@ = 'Invalid response';
                        Lim::DEBUG and $self->{logger}->debug($@);
                        $response = [];
                    }

                    my $cb = delete $self->{cb};
                    $self->{busy} = 0;
                    $cb->($self, @$response);
                }
            });
    }
    elsif (defined $pid) {
        #
        # Child process
        #

        $SIG{HUP} => 'IGNORE';
        $SIG{INT} => 'IGNORE';
        $SIG{TERM} => 'IGNORE';
        $SIG{PIPE} => 'IGNORE';
        $SIG{QUIT} => 'IGNORE';
        $SIG{ALRM} => 'IGNORE';

        Log::Log4perl->init( \q(
log4perl.threshold                = OFF
log4perl.logger                   = DEBUG, Screen
log4perl.appender.Screen          = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr   = 0
log4perl.appender.Screen.layout   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %F [%L] %p: %m%n
) );

        if (exists $self->{close_fds} and $self->{close_fds}) {
            my $parent_fno = fileno $parent;

            foreach ($^F+1 .. (POSIX::sysconf (&POSIX::_SC_OPEN_MAX) || 1024)) {
                unless ($_ == $parent_fno) {
                    POSIX::close($_);
                }
            }
        }

        while () {
            my $request;
            my $len = sysread $parent, my $buf, 64*1024;
            if ($len > 0) {
                undef $@;

                eval {
                    $request = $self->{json}->incr_parse($buf);
                };
                if ($@) {
                    last;
                }
            }
            elsif (defined $len) {
                last;
            }
            else {
                last;
            }

            if (defined $request) {
                unless (ref($request) eq 'ARRAY') {
                    last;
                }

                my $response = $self->process(@$request);

                undef $@;
                eval {
                    $response = $self->{json}->encode($response);
                };
                if ($@) {
                    my $errstr = $@;
                    undef $@;
                    eval {
                        $response = $self->{json}->encode([$errstr]);
                    };
                    if ($@) {
                        last;
                    }
                }

                my $wrote = 0;
                my $res_len = length $response;
                while () {
                    $len = syswrite $parent, $response, 64*1024;
                    unless (defined $len and $len > 0) {
                        last;
                    }

                    $wrote += $len;

                    if ($wrote >= $res_len) {
                        last;
                    }

                    $response = substr $response, $len;
                }
                if ($wrote != $res_len) {
                    last;
                }
            }
        }
        shutdown($parent, 2);
        close($parent);
        exit(0);
    }
    else {
        confess __PACKAGE__, ': Unable to fork: ', $!;
    }

    $self->connect($on_connect, $dbi, $user, $password, %args);

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);

    if (exists $self->{child_pid}) {
        my $child_watcher; $child_watcher = AnyEvent->child(
            pid => $self->{child_pid},
            cb => sub {
                undef $child_watcher;
            });
    }

    if (exists $self->{child}) {
        shutdown($self->{child}, 2);
        close($self->{child});
    }
}

=item process

=cut

sub process {
    my $self = shift;
    my $method = shift;
    my $response;

    unless (exists $METHOD{$method}) {
        return ['Method '.$method.' is not allowed'];
    }

    $method = 'child_'.$method;
    eval {
        $response = $self->$method(@_);
    };
    if ($@) {
        return [$@];
    }

    return $response;
}

=item request

=cut

sub request {
    my $self = shift;
    my $cb = shift;
    my ($method) = @_;
    my $request;
    weaken($self);

    undef $@;

    unless (ref($cb) eq 'CODE') {
        confess __PACKAGE__, 'cb is not CODE';
    }

    unless (exists $METHOD{$method}) {
        $@ = 'Method '.$method.' is not allowed';
        $cb->();
        return;
    }

    unless (exists $self->{child}) {
        $@ = 'No connection to the DBI process';
        $cb->();
        return;
    }

    if ($self->{busy}) {
        $@ = 'DBH is busy, multiple command execution is not allowed';
        $cb->();
        return;
    }

    eval {
        $request = $self->{json}->encode(\@_);
    };
    if ($@) {
        $cb->();
        return;
    }

    $self->{busy} = 1;
    $self->{cb} = $cb;

    Lim::DEBUG and $self->{logger}->debug('Sending DBI request ', $method);

    my $len = syswrite $self->{child}, $request;
    unless (defined $len and $len > 0) {
        $@ = 'Connection broken';
        $self->kill;
        $cb->();
        return;
    }

    unless ($len >= length $request) {
        $request = substr $request, $len;

        $self->{request_watcher} = AnyEvent->io(
            fh => $request,
            poll => 'w',
            cb => sub {
                unless (defined $self) {
                    return;
                }

                $len = syswrite $self->{child}, $request;
                unless (defined $len and $len > 0) {
                    $@ = 'Connection broken';
                    my $cb = $self->{cb};
                    $self->kill;
                    $cb->();
                    return;
                }

                unless ($len >= length $request) {
                    $request = substr $request, $len;
                    return;
                }

                delete $self->{request_watcher};
            });
    }

    return 1;
}

=item kill

=cut

sub kill {
    my ($self) = @_;

    if (exists $self->{child}) {
        shutdown($self->{child}, 2);
        close(delete $self->{child});
    }

    delete $self->{child_watcher};
    delete $self->{request_watcher};
    $self->{busy} = 0;
    delete $self->{cb};
}

=item child_connect

=cut

sub child_connect {
    my ($self, $dbi, $user, $pass, $attr) = @_;

    unless (($self->{dbh} = DBI->connect($dbi, $user, $pass, $attr))) {
        return [$DBI::errstr];
    }

    [0, 1];
}

=item child_disconnect

=cut

sub child_disconnect {
    my ($self) = @_;

    unless (defined $self->{dbh}) {
        return ['No connect to the database exists'];
    }

    $self->{dbh}->disconnect;
    delete $self->{dbh};

    [0, 1];
}

=item child_execute

=cut

sub child_execute {
    my ($self, $statement, @args) = @_;
    my ($sth, $rv, $rows);

    unless (defined $self->{dbh}) {
        return ['No connect to the database exists'];
    }

    unless (($sth = $self->{dbh}->prepare_cached($statement, undef, 1))) {
        return [$DBI::errstr];
    }

    unless (($rv = $sth->execute(@args))) {
        return [$sth->errstr];
    }

    $rows = $sth->fetchall_arrayref;
    $sth->finish;

    [0, $rows, $rv];
}

=item child_begin_work

=cut

sub child_begin_work {
    my ($self) = @_;

    unless (defined $self->{dbh}) {
        return ['No connect to the database exists'];
    }

    unless ($self->{dbh}->begin_work) {
        return [$DBI::errstr];
    }

    [0, 1];
}

=item child_commit

=cut

sub child_commit {
    my ($self) = @_;

    unless (defined $self->{dbh}) {
        return ['No connect to the database exists'];
    }

    unless ($self->{dbh}->commit) {
        return [$DBI::errstr];
    }

    [0, 1];
}

=item child_rollback

=cut

sub child_rollback {
    my ($self) = @_;

    unless (defined $self->{dbh}) {
        return ['No connect to the database exists'];
    }

    unless ($self->{dbh}->rollback) {
        return [$DBI::errstr];
    }

    [0, 1];
}

=item connect

=cut

sub connect {
    my ($self, $cb, $dbi, $user, $pass, %attr) = @_;

    $self->request($cb, 'connect', $dbi, $user, $pass, \%attr);
}

=item disconnect

=cut

sub disconnect {
    my ($self, $cb) = @_;

    $self->request($cb, 'disconnect');
}

=item execute

=cut

sub execute {
    my $cb = pop(@_);
    my ($self, $statement, @args) = @_;

    $self->request($cb, 'execute', $statement, @args);
}

=item begin_work

=cut

sub begin_work {
    my ($self, $cb) = @_;

    $self->request($cb, 'begin_work');
}

=item commit

=cut

sub commit {
    my ($self, $cb) = @_;

    $self->request($cb, 'commit');
}

=item rollback

=cut

sub rollback {
    my ($self, $cb) = @_;

    $self->request($cb, 'rollback');
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Util::DBI

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Util::DBI
