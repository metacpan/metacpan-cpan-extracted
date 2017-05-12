use Test;
use File::Spec;
use strict;

use Mail::MboxParser;

my $src = File::Spec->catfile('t', 'testbox');

BEGIN { plan tests => 5 };

my $mb  = Mail::MboxParser->new($src);
my @a   = $mb->get_messages;
my $msg = $a[8];
ok(defined $mb);
ok($msg->effective_type, 'multipart/mixed');
ok($msg->num_entities, 3);
ok($msg->parts_DFS, 2);
ok($msg->parts(1)->make_singlepart eq 'ALREADY');


