use Test;
use File::Spec;
use strict;

use Mail::MboxParser;

my $src = File::Spec->catfile('t', 'testbox');

BEGIN { plan tests => 3 };

my $mb  = Mail::MboxParser->new($src);

ok(defined $mb);
ok($mb->nmsgs == 9);
ok($mb->current_pos == 0);

