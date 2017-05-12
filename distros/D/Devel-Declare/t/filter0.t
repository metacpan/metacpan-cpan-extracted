use warnings;
use strict;

use Test::More;
use Test::Requires 'Filter::Util::Call';

plan tests => 2;

use Devel::Declare ();
use Filter::Util::Call qw(filter_add filter_del);

sub my_quote($) { $_[0] }

my $i = 0;

BEGIN { Devel::Declare->setup_for(__PACKAGE__, { my_quote => { const => sub { } } }); }
BEGIN { filter_add(sub { filter_del(); $_ .= "ok \$i++ == 0;"; return 1; }); }

ok $i++ == 1;

1;
