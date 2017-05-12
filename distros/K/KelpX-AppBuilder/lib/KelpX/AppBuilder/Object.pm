package KelpX::AppBuilder::Object;

sub new { return bless { routes => $_[1] }, 'KelpX::AppBuilder::Object'; }

sub apps {
    my ($self, @apps) = @_;
    my $routes = $self->{routes};
    for (@apps) {
        KelpX::AppBuilder->new($_)->add_maps($routes);
    } 
}

1;
__END__
