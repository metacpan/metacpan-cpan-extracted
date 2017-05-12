package MyApp::Foo;
use Moo;
use namespace::clean;

has [qw(controller action)] => (
    is       => 'ro',
    required => 1
);

sub bar {
    my $self = shift;

    my $params     = shift;
    my $extra_args = +[@_];

    +{
        controller => $self->controller,
        action     => $self->action,
        params     => $params,
        extra_args => $extra_args,
    };
}

1;
__END__
