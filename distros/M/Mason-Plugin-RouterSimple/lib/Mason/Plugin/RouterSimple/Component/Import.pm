package Mason::Plugin::RouterSimple::Component::Import;
BEGIN {
  $Mason::Plugin::RouterSimple::Component::Import::VERSION = '0.07';
}
use Mason::PluginRole;

after 'import_into' => sub {
    my ( $class, $for_class ) = @_;
    no strict 'refs';
    *{ $for_class . "::route" } = sub ($;$) { $for_class->router_add(@_) };
};

1;
