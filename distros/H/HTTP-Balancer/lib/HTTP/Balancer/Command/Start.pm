package HTTP::Balancer::Command::Start;

use Modern::Perl;

use Moose;

with qw( HTTP::Balancer::Role::Command );

sub run {
    my ($self, ) = @_;

    $self
    ->actor("Nginx")
    ->new
    ->start(
        pidfile => $self->config->pidfile,
        hosts   => [$self->model("Host")->all(sub { shift->hash })],
    );
}

1;
__END__

=head1 NAME

HTTP::Balancer::Command::Start - start the balancer

=head1 SYNOPSIS

    $ http-balancer start

=cut
