package Mason::Plugin::Cache::Filters;
BEGIN {
  $Mason::Plugin::Cache::Filters::VERSION = '0.05';
}
use Mason::PluginRole;

method Cache ( $key, $set_options, %cache_options ) {
    $key = 'Default' if !defined($key);
    Mason::DynamicFilter->new(
        filter => sub {
            $self->cache(%cache_options)->compute( $key, $_[0], $set_options );
        }
    );
}

1;
