package t::Memcached::Servers;

use strict;
use warnings;
use Memcached::Client::Log qw{DEBUG LOG};

# Minimum 2, up to 10
use constant SERVERS => int (rand (9) + 2);

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;
    for my $count (1..SERVERS) {
        my $port = $count + 10000;
        my $host = "127.0.0.1:$port";
        my $weight = int (rand (3) + 1);
        push @{$self->{servers}}, $weight > 1 ? [$host, $weight] : $host;
    }
    $self->log ("%s", $self->{servers}) if DEBUG;
    $self;
}

sub error {
    my ($self) = @_;
    my $choice = int (rand (scalar @{$self->{servers}}));
    my $server = ref $self->{servers}->[$choice] ? $self->{servers}->[$choice]->[0] : $self->{servers}->[$choice];
    $self->log ("Choice is #%s, %s", $choice, $server) if DEBUG;
    return $server;
}

# sub new {
#     my ($class, @args) = @_;
#     my $self = bless {}, $class;
#     $self->{servers} = [['127.0.0.1:10001', 2], ['127.0.0.1:10002', 2], ['127.0.0.1:10003', 3], ['127.0.0.1:10004', 3], ['127.0.0.1:10005', 3], ['127.0.0.1:10006', 3], '127.0.0.1:10007'];
#     $self;
# }

# sub error {
#     return "127.0.0.1:10006";
# }

sub servers {
    my ($self) = @_;
    return $self->{servers};
}

=method log

=cut

sub log {
    my ($self, $format, @args) = @_;
    LOG ("Servers> " . $format, @args);
}

1;
