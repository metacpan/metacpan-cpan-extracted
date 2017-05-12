package HTTP::Balancer::Command::Status;
use Modern::Perl;
use Moose;

with qw(HTTP::Balancer::Role::Command);

use Path::Tiny;

sub run {
    my ($self, ) = @_;

    my $pidfile = path($self->config->pidfile);

    if ($pidfile->exists) {
        my ($pid, ) = $pidfile->lines({chomp => 1});
        say "$0 is running. pid: $pid";
    } else {
        say "$0 is stop";
    }
}

1;
__END__

=head1 NAME

HTTP::Balancer::Command::Status - show status of the balancer

=head1 SYNOPSIS

    $ http-balancer status

=cut
