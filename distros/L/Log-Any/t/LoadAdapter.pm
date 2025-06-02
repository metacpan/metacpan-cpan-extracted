# This module is here to test that Log::Any::Adapter::Multiplex will
# dynamically load an adapter at runtime instead of unexpectedly dying.
package # splitting into two lines hides from PAUSE/CPAN
  LoadAdapter;
use base qw(Log::Any::Adapter::Base);
foreach my $method ( Log::Any->logging_methods() ) {
    no strict 'refs';
    *$method = sub { 
      # Do nothing
    };
}
foreach my $method ( Log::Any->detection_methods() ) {
    no strict 'refs';
    *$method = sub {1};
}
1;
