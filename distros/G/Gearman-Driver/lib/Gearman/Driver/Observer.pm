package Gearman::Driver::Observer;

use Moose;
use Net::Telnet::Gearman;
use POE;

=head1 NAME

Gearman::Driver::Observer - Observes Gearman status interface

=head1 DESCRIPTION

Each n seconds L<Net::Telnet::Gearman> is used to fetch status of
free/running/busy workers from the Gearman server. L<Gearman::Driver>
decides to fork more workers depending on the queue size and the
MinProcesses/MaxProcesses attribute of the job methods.

Currently there's no public interface.

=cut

has 'callback' => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

has 'interval' => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
);

has 'server' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'telnet' => (
    auto_deref => 1,
    default    => sub { [] },
    is         => 'ro',
    isa        => 'ArrayRef[Net::Telnet::Gearman]',
);

has 'session' => (
    is  => 'ro',
    isa => 'POE::Session',
);

sub BUILD {
    my ($self) = @_;

    $self->_connect();

    $self->{session} = POE::Session->create(
        object_states => [
            $self => {
                _start       => '_start',
                fetch_status => '_fetch_status'
            }
        ]
    );
}

sub _start {
    $_[KERNEL]->delay( fetch_status => $_[OBJECT]->interval );
}

sub _connect {
    my ($self) = @_;

    $self->{telnet} = [];

    foreach my $server ( split /,/, $self->server ) {
        my ( $host, $port ) = split /:/, $server;

        my $telnet = Net::Telnet::Gearman->new(
            Host => $host || 'localhost',
            Port => $port || 4730,
        );

        push @{ $self->{telnet} }, $telnet;
    }
}

sub _fetch_status {
    my %data  = ();
    my @error = ();

    foreach my $telnet ( $_[OBJECT]->telnet ) {
        eval {
            my $status = $telnet->status;

            foreach my $row (@$status) {
                $data{ $row->name } ||= {
                    name    => $row->name,
                    busy    => 0,
                    free    => 0,
                    queue   => 0,
                    running => 0,
                };
                $data{ $row->name }{busy}    += $row->busy;
                $data{ $row->name }{free}    += $row->free;
                $data{ $row->name }{queue}   += $row->queue;
                $data{ $row->name }{running} += $row->running;
            }
        };

        # Try to re-open the telnet connection
        if ($@) {
            push @error, $@ if $@;
            eval { $telnet->open };
        }
    }

    $_[OBJECT]->callback->( { data => [ values %data ], error => \@error } );

    $_[KERNEL]->delay( fetch_status => $_[OBJECT]->interval );
}

no Moose;

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

See L<Gearman::Driver>.

=head1 COPYRIGHT AND LICENSE

See L<Gearman::Driver>.

=head1 SEE ALSO

=over 4

=item * L<Gearman::Driver>

=item * L<Gearman::Driver::Adaptor>

=item * L<Gearman::Driver::Console>

=item * L<Gearman::Driver::Console::Basic>

=item * L<Gearman::Driver::Console::Client>

=item * L<Gearman::Driver::Job>

=item * L<Gearman::Driver::Job::Method>

=item * L<Gearman::Driver::Loader>

=item * L<Gearman::Driver::Worker>

=back

=cut

1;
