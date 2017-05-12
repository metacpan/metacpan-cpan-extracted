package Mason::Plugin::Cache::Component;
BEGIN {
  $Mason::Plugin::Cache::Component::VERSION = '0.05';
}
use Mason::PluginRole;

my %memoized;

method cache_memoized ($class:) {
    $class = ref($class) || $class;
    if (@_) { $memoized{$class} = $_[0] }
    return $memoized{$class};
}

method cache_defaults ($class:)   { $class->cmeta->interp->cache_defaults }
method cache_root_class ($class:) { $class->cmeta->interp->cache_root_class }
method cache_namespace ($class:)  { $class->cmeta->path }

method cache ($class:) {
    if ( !@_ && $class->cache_memoized ) {
        return $class->cache_memoized;
    }
    my $cache_root_class = $class->cache_root_class;
    my %options = ( %{ $class->cache_defaults }, @_ );
    if ( !exists( $options{namespace} ) ) {
        $options{namespace} = $class->cache_namespace;
    }
    my $cache = $cache_root_class->new(%options);
    if ( !@_ ) {
        $class->cache_memoized($cache);
    }
    return $cache;
}

1;
