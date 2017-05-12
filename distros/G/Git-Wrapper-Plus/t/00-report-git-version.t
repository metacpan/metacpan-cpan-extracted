
use strict;
use warnings;

use Test::More;

# FILENAME: basic.t
# CREATED: 12/07/13 06:28:57 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Simple functionality test.

use Git::Wrapper::Plus::Tester;
use Git::Wrapper::Plus::Versions;

my $t = Git::Wrapper::Plus::Tester->new();
my $v = Git::Wrapper::Plus::Versions->new( git => $t->git );

$t->run_env(
  sub {
    diag( "Git Version: " . $v->current_version );
    for my $mv (qw( 2.0 1.9 1.8 1.7 1.6 1.5 1.4 1.3 1.2 1.1 1.0 )) {
      if ( $v->newer_than($mv) ) {
        diag("Git is >= $mv");
        last;
      }
    }
  }
);

pass("Basic self check passed");
done_testing;

