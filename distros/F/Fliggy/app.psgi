use Plack::Builder;

builder {
    sub {[200, [], ['']]};
};
