=head1 NAME

MKDoc::Core::FileCache - Cache::FileCache wrapper for MKDoc::Core

=head1 SYNOPSIS

  sub cached_foo
  {
      my $key = shift;
      my $foo_cache = MKDoc::Core::FileCache->instance ('foo_cache');
      return $foo_cache->get ($key) || do {
          my $val = compute_expensive_foo ($key);
          $foo_cache->set ($key, $val, "1 day");
          $val;
      };
  }

=cut
package MKDoc::Core::FileCache;
use MKDoc::Core;
use Cache::FileCache;
use strict;
use warnings;


sub instance
{
    my $class = shift || return;
    my $cache = shift || return;
    my $dir   = MKDoc::Core::site_dir();

    -d "$dir/cache" or mkdir "$dir/cache" or die "No $dir/cache";
    return new Cache::FileCache ( {
        cache_root => "$dir/cache",
        namespace => $cache,
    } );
}


1;
