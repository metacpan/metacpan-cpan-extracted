package Gearman::Driver::Console::Client;

use Moose;
use POE qw(Wheel::ReadLine);
use Net::Telnet;
with qw(MooseX::Getopt);

=head1 NAME

Gearman::Driver::Console::Client - Console client with readline

=head1 DESCRIPTION

If you got many worker servers and want to change processes at once
on all servers while runtime, this tool comes in handy:

    usage: gearman_driver_console.pl [long options...]
            --server       A list of servers to connect to: "host1 host2 host3:47301 host4:47302"
            --history      Readline history, defaults to $HOME/.gearman_driver_history

    $ ~/Gearman-Driver$ gearman_driver.pl --console_port 47301 &
    [1] 89053
    $ ~/Gearman-Driver$ gearman_driver.pl --console_port 47302 &
    [2] 89066
    $ ~/Gearman-Driver$ gearman_driver.pl --console_port 47303 &
    [3] 89079

    $ ~/Gearman-Driver$ gearman_driver_console.pl --server "localhost:47301 localhost:47302 localhost:47303"
    console> status
    localhost:47301> GDExamples::Convert::convert_to_jpeg  0  5  0  1970-01-01T00:00:00  1970-01-01T00:00:00
    localhost:47301> GDExamples::Convert::convert_to_gif   0  5  0  1970-01-01T00:00:00  1970-01-01T00:00:00
    localhost:47301> .
    localhost:47302> GDExamples::Convert::convert_to_jpeg  0  5  0  1970-01-01T00:00:00  1970-01-01T00:00:00
    localhost:47302> GDExamples::Convert::convert_to_gif   0  5  0  1970-01-01T00:00:00  1970-01-01T00:00:00
    localhost:47302> .
    localhost:47303> GDExamples::Convert::convert_to_jpeg  0  5  0  1970-01-01T00:00:00  1970-01-01T00:00:00
    localhost:47303> GDExamples::Convert::convert_to_gif   0  5  0  1970-01-01T00:00:00  1970-01-01T00:00:00
    localhost:47303> .
    console> show GDExamples::Convert::convert_to_jpeg
    localhost:47301> GDExamples::Convert::convert_to_jpeg  0  5  0  1970-01-01T00:00:00  1970-01-01T00:00:00
    localhost:47301> 89061
    localhost:47301> 89063
    localhost:47301> 89062
    localhost:47301> .
    localhost:47302> GDExamples::Convert::convert_to_jpeg  0  5  0  1970-01-01T00:00:00  1970-01-01T00:00:00
    localhost:47302> 89074
    localhost:47302> 89075
    localhost:47302> 89076
    localhost:47302> .
    localhost:47303> GDExamples::Convert::convert_to_jpeg  0  5  0  1970-01-01T00:00:00  1970-01-01T00:00:00
    localhost:47303> 89088
    localhost:47303> 89089
    localhost:47303> 89087
    localhost:47303> .
    console> shutdown
    [1]   Done                    gearman_driver.pl --console_port 47301
    [2]-  Done                    gearman_driver.pl --console_port 47302
    [3]+  Done                    gearman_driver.pl --console_port 47303
    $ ~/Gearman-Driver$

=cut

has 'server' => (
    documentation => 'A list of servers to connect to: "host1 host2 host3:47301 host4:47302"',
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
);

has 'telnet' => (
    default => sub { {} },
    handles => {
        add_telnet => 'set',
        get_telnet => 'get',
        servers    => 'keys',
    },
    is     => 'ro',
    isa    => 'HashRef',
    traits => [qw(NoGetopt Hash)],
);

has 'history' => (
    default       => "$ENV{HOME}/.gearman_driver_history",
    documentation => 'Readline history, defaults to $HOME/.gearman_driver_history',
    is            => 'rw',
    isa           => 'Str',
);

has 'session' => (
    is     => 'ro',
    isa    => 'POE::Session',
    traits => [qw(NoGetopt)],
);

sub run {
    my ($self) = @_;

    foreach my $server ( split /\s+/, $self->server ) {
        my ( $host, $port ) = split /:/, $server;
        $port ||= 47300;
        my $telnet = Net::Telnet->new(
            host => $host,
            port => $port,
        );
        $telnet->open;
        $self->add_telnet( $server => $telnet );
    }

    $self->{session} = POE::Session->create(
        object_states => [
            $self => {
                _start         => '_start',
                got_user_input => '_handle_user_input',
            }
        ]
    );

    POE::Kernel->run();
}

sub _handle_user_input {
    my ( $self, $input, $exception ) = @_[ OBJECT, ARG0, ARG1 ];
    my $console = $_[HEAP]{console};

    unless ( defined $input ) {
        $console->put("$exception caught.  B'bye!");
        $_[KERNEL]->signal( $_[KERNEL], "UIDESTROY" );
        $console->write_history( $self->history );
        return;
    }

    $console->addhistory($input);

    my ( $command, $pipe ) = split /\|/, $input;
    my @lines = ();

    foreach my $server ( sort $self->servers ) {
        my $telnet = $self->get_telnet($server);
        $telnet->print($command);
        while ( my $line = $telnet->getline() ) {
            if ($pipe) {
                push @lines, "$server> $line";
            }
            else {
                print "$server> $line";
            }
            last if $line eq ".\n";
        }
    }

    if ($pipe) {
        open CMD, "|$pipe";
        print CMD $_ foreach @lines;
        close CMD;
    }

    if ( $input eq 'quit' || $input eq 'shutdown' ) {
        $console->write_history( $self->history );
        $_[KERNEL]->signal( $_[KERNEL], "UIDESTROY" );
        return;
    }

    $console->get("console> ");
}

sub _start {
    $_[HEAP]{console} = POE::Wheel::ReadLine->new( InputEvent => 'got_user_input' );
    $_[HEAP]{console}->read_history( $_[OBJECT]->history );
    $_[HEAP]{console}->get("console> ");
}

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

=item * L<Gearman::Driver::Job>

=item * L<Gearman::Driver::Job::Method>

=item * L<Gearman::Driver::Loader>

=item * L<Gearman::Driver::Observer>

=item * L<Gearman::Driver::Worker>

=item * L<Gearman::Driver::Worker::Base>

=back

=cut

1;
