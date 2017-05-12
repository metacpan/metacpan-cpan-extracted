package HTTP::Balancer::Config;
use Modern::Perl;
use Moose;
use MooseX::Singleton;

has dbpath => (
    is      => "rw",
    isa     => "Str",
    default => "/var/lib/http-balancer/",
);

has pidfile => (
    is      => "rw",
    isa     => "Str",
    default => "/var/run/http-balancer.pid",
);

1;
__END__

=head1 NAME

HTTP::Balancer::Config - config loader

=head1 SYNOPSIS

    package HTTP::Balancer::Any;
    use Moose;
    with qw(HTTP::Balancer::Role);
    my $config = $self->config;

=cut
