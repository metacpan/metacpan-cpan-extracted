package MyApp;
use Moo;
use JSON::RPC::Spec v1.0.5;
use MyApp::Foo;
use namespace::clean;

has jsonrpc => (is => 'lazy');

sub _build_jsonrpc {
    my $jsonrpc = JSON::RPC::Spec->new;
    $jsonrpc->register(
        '{controller}.{action}' => sub {
            my $params = shift;
            my $match  = shift;

            my $sub_class = ucfirst $match->{controller};
            my $method    = $match->{action};
            my $class     = join '::', 'MyApp', $sub_class;

            $class->new($match)->$method($params, @_);
        }
    );
    $jsonrpc;
}

1;
__END__
