package MyApp;
use Mojo::Base 'Mojolicious';

our $VERSION = 1.00;

sub startup {
    my $self = shift;

    $self->plugin('Minion' => {Fake => 1});
    $self->plugin('Minion::API' => minion => $self->app->minion);
}

1;
