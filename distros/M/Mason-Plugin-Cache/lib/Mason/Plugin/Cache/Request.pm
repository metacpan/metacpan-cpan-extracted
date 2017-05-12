package Mason::Plugin::Cache::Request;
BEGIN {
  $Mason::Plugin::Cache::Request::VERSION = '0.05';
}
use Mason::PluginRole;

method cache () {
    return $self->current_comp_class->cache(@_);
}

1;
