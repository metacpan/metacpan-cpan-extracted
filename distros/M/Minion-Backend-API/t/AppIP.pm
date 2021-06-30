package AppIP;
use Mojo::Base 'Mojolicious';

our $VERSION = 1.00;

sub startup {
    my $self = shift;

    $self->plugin('Minion' => {Fake => 1});
    $self->plugin('Minion::API' => {
        minion      => $self->app->minion,
        ips_enabled => [qw/
            127.0.0.1
        /]
    });
}

1;
