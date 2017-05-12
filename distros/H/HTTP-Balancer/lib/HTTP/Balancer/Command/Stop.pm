package HTTP::Balancer::Command::Stop;

use Modern::Perl;

use Moose;

with qw( HTTP::Balancer::Role::Command );

sub run {
    my ($self, ) = @_;

    $self
    ->actor("Nginx")
    ->new
    ->stop(pidfile => $self->config->pidfile);

}

1;
__END__

=head1 NAME

HTTP::Balancer::Command::Stop - stop the balancer

=head1 SYNOPSIS

    $ http-balancer stop

=cut
