package t::Internal;
use Any::Moose;
use FCGI::Client::Constant;
use File::Temp ();
use autodie;
use HTTP::Request;
use IO::Socket::UNIX;
use FCGI::Client::RecordFactory;
use FCGI::Client::Record;
use FCGI::Client::Connection;
use Time::HiRes 'sleep';

has path   => ( is => 'ro', isa     => 'Str' );
has sock_path => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { File::Temp::tmpnam() },
);
has child_pid => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $path = $self->sock_path;   # generate common path before fork(2)
        my $pid  = fork();
        if ( $pid > 0 ) {              # parent
            return $pid;
        }
        else {
            my $sock = IO::Socket::UNIX->new(
                Local  => $path,
                Listen => 30,
            ) or die $!;
            open *STDIN, '>&', $sock;    # dup(2)
            exec $self->path;
            die "should not reach here: $!";
        }
    }
);

sub DEMOLISH {
    my $self = shift;
    if ($self->child_pid) {
        kill 'TERM' => $self->child_pid;
        wait;
    }
    unlink $self->sock_path;
}

sub create_socket {
    my $self = shift;
    $self->child_pid();    # invoke child

    my $path = $self->sock_path;
    my $retry = 30;
    while ($retry-- >= 0) {
        my $sock = IO::Socket::UNIX->new( Peer => $path, );
        return $sock if $sock;
        sleep 0.3;
    }
    die "cannot open socket $path: $!";
}

sub request {
    my ($self, $env, $content, $timeout) = @_;
    my $con = FCGI::Client::Connection->new(sock => $self->create_socket, timeout => $timeout || 1);
    return $con->request($env, $content);
}

__PACKAGE__->meta->make_immutable;
