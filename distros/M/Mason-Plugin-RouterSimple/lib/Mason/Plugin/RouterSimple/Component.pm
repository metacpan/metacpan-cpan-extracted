package Mason::Plugin::RouterSimple::Component;
BEGIN {
  $Mason::Plugin::RouterSimple::Component::VERSION = '0.07';
}
use Mason::PluginRole;
use Router::Simple;

my %router_objects;

has 'router_result' => ( is => 'ro' );

method allow_path_info ($class:) {
    return $class->router_object ? 1 : 0;
}

method router_add ($class: $pattern, $dest) {
    $dest ||= {};
    unless ( $class->router_object ) {
        $class->router_object( $class->router_create_object() );
    }
    $class->router_object->connect( $pattern, $dest );
}

method router_create_object ($class:) {
    return Router::Simple->new();
}

method router_object ($class: $object) {
    $router_objects{$class} = $object if ( defined($object) );
    return $router_objects{$class};
}

1;
