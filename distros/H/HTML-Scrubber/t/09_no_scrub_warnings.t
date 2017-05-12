use strict;
use warnings;
use Test::More;

use_ok('HTML::Scrubber');
use HTML::Scrubber;

my $scrubber = HTML::Scrubber->new;

# really one of the Test:: warnings would be better here
# but lets keep this simple
local $SIG{__WARN__} = sub {
    fail("warning raised by scrub: @_");
};

ok( !$scrubber->scrub );
ok( !$scrubber->scrub('') );
ok( !$scrubber->scrub('<html></html>') );

done_testing;
