package Mason::Plugin::RouterSimple::Request;
BEGIN {
  $Mason::Plugin::RouterSimple::Request::VERSION = '0.07';
}
use Mason::PluginRole;

around 'construct_page_component' => sub {
    my ( $orig, $self, $compc, $args ) = @_;

    if ( $compc->router_object() ) {
        if ( defined( my $path_info = $self->path_info ) ) {
            if ( my $router_result = $compc->router_object->match($path_info) ) {
                $args = { router_result => $router_result, %$router_result, %$args };
            }
            else {
                $self->decline("'$path_info' did not match any routes");
            }
        }
    }
    return $self->$orig( $compc, $args );
};

1;
