package TestCache;

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

    return $self;
}

sub set {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;           # an HTTP::Response
    my $res   = $value->clone;
    $res->content("DUMMY");
    $self->{$key} = $res;
}

sub get {
    my $self = shift;
    my $key  = shift;
    return $self->{$key};
}

1;
