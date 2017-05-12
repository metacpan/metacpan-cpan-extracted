package Mason::Plugin::Cache::Interp;
BEGIN {
  $Mason::Plugin::Cache::Interp::VERSION = '0.05';
}
use CHI;
use Mason::Util qw(catdir);
use Mason::PluginRole;

# Passed attributes
#
has 'cache_defaults'   => ( is => 'ro', isa => 'HashRef', lazy_build => 1 );
has 'cache_root_class' => ( is => 'ro', isa => 'Str', default => 'CHI' );

method _build_cache_defaults () {
    return {
        driver   => 'File',
        root_dir => catdir( $self->data_dir, 'cache' )
    };
}

1;
