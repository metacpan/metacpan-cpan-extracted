package Example;
use strict;
use warnings;
use Egg qw/
  -Debug
  ConfigLoader
  /;

our $VERSION= '0.01';

__PACKAGE__->egg_startup(
  title => 'Example',
  root  => '/path/to/Example',
  VIEW=> [
    [ TT => { INCLUDE_PATH=> ['<e.dir.template>'] } ],
    ],
  );

# Dispatch. ------------------------------------------------
__PACKAGE__->run_modes(
  _default => sub {
    my($d, $e)= @_;
    $e->view->param( server_port => $e->req->port );
    $e->stash( test_title => 'test OK' );
    },
  );
# ----------------------------------------------------------

1;
