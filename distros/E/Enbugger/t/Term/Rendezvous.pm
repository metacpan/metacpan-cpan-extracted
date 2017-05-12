package Term::Rendezvous;

sub null {
    unless ($null) {
        open $null, '+<', '/dev/null';
    }
    $null;
}

sub new {
    my ($class, $rv) = @_;

    my $self = {
        rv => $rv,
        IN => null(),
        OUT => null(),
    };
    bless $self, $class;
    return $self;
}

sub IN {
    $_[0]{IN};
}

sub OUT {
    $_[0]{OUT};
}

<<V
Christmas Eve, 1955, Benny Profane, wearing black levis, suede
jacket, sneaker and big cowboy hat, happened to pass through Norfolk,
Virginia.
V
