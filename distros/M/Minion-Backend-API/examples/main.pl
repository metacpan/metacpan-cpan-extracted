use Mojolicious::Lite;
use Minion;

plugin 'Minion::API' => {
    minion => Minion->new(Pg => 'postgresql://postgres@/test'),
    pattern => '/my-api' # http://localhost:3000/my-api
};

get '/storage1' => sub {
    my $self = shift;

    $self->minion->enqueue('storage1');
    $self->render(text => 'Added enqueue storage1');
};

get '/storage2' => sub {
    my $self = shift;

    $self->minion->enqueue('storage2');
    $self->render(text => 'Added enqueue storage2');
};

app->start;
