package Server;
# ABSTRACT: A runner for test HTTP servers

=head1 SYNOPSIS

    use Server;
    my $server = Server->new('app.psgi');

=head1 DESCRIPTION

Throws up an HTTP server on a random port, suitable for testing. Server logs will be printed to
C<STDERR> as test notes.

=cut

use warnings;
use strict;

use IO::Handle;
use Plack::Runner;
use Util qw(recv_env);

=method new

    $server = Server->new($path);
    $server = Server->new(\&app);
    $server = Server->new(\&app, type => 'Starman');

Construct and L</start> a new test HTTP server.

=cut

sub new {
    my $class   = shift;
    my $app     = shift or die 'PSGI app required';
    my %args    = @_;

    $args{type} ||= 'HTTP::Server::PSGI';

    my $self = bless {app => $app, %args}, $class;
    return $self->start;
}

=attr app

Get the app that was passed to L</new>.

=attr in

Get a filehandle for reading the server's STDOUT.

=attr pid

Get the process identifier of the server.

=attr port

Get the port number the server is listening on.

=attr url

Get the URL for the server.

=attr type

Get the type of server that was passed to L</new>.

=cut

sub app  { shift->{app}  }
sub in   { shift->{in}   }
sub pid  { shift->{pid}  }
sub port { shift->{port} }
sub url  { 'http://localhost:' . shift->port }
sub type { shift->{type} }

=method start

    $server->start;

Start the server.

=cut

sub start {
    my $self = shift;

    # do not start on top of an already-started server
    return $self if $self->{pid};

    my $type = $self->type;

    my $pid = open(my $pipe, '-|');
    defined $pid or die "fork failed: $!";

    $pipe->autoflush(1);

    if ($pid) {
        my $port = <$pipe>;
        die 'Could not start test server' if !$port;
        chomp $port;

        $self->{in}     = $pipe;
        $self->{pid}    = $pid;
        $self->{port}   = $port;
    }
    else {
        tie *STDERR, 'Server::RedirectToTestHarness';

        autoflush STDOUT 1;

        for my $try (1..10) {
            my $port_num = $ENV{PERL_HTTP_ANYUA_TEST_PORT} || int(rand(32768)) + 32768;
            print STDERR sprintf('Try %02d - Attempting to start a server on port %d for testing...', $try, $port_num);

            local $SIG{ALRM} = sub { print "$port_num\n" };
            alarm 1;

            eval {
                my $runner = Plack::Runner->new;
                $runner->parse_options('-s', $type, '-p', $port_num);
                $runner->run($self->app);
            };
            warn $@ if $@;

            alarm 0;
        }

        print STDERR "Giving up...";
        exit;
    }

    return $self;
}

=method stop

    $server->stop;

Stop the server. Called implicitly by C<DESTROY>.

=cut

sub stop {
    my $self = shift;

    if (my $pid = $self->pid) {
        kill 'TERM', $pid;
        waitpid $pid, 0;
        $? = 0;             # don't let child exit status affect parent
    }
    %$self = (app => $self->app);
}

sub DESTROY {
    my $self = shift;
    $self->stop;
}


=method read_env

    $env = $server->read_env;

Read a L<PSGI> environment from the server, sent by L<Util/send_env>.

=cut

sub read_env {
    my $self = shift;
    return recv_env($self->in or die 'Not connected');
}


{
    package Server::RedirectToTestHarness;

    use Test::More ();

    sub TIEHANDLE   { bless {} }
    sub PRINT       { shift; Test::More::note('Server: ', @_) }
    sub PRINTF      { shift; Test::More::note('Server: ', sprintf(@_)) }
}

1;
