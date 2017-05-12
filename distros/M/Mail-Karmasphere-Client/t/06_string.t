use strict;
use warnings;
use blib;
use Carp qw(cluck);

use Test::More tests => 10;

use_ok('Mail::Karmasphere::Client');
use_ok('Mail::Karmasphere::Query');
use_ok('Mail::Karmasphere::Response');

local $SIG{__WARN__} = sub { cluck @_; };

my $DEBUG = 1 if $ENV{MKS_DEBUG_TESTS};

my $q = new Mail::Karmasphere::Query();
$q->identity('foo.com', 'domain', 'a.b.c');
$q->feed('karmasphere.test');
$q->feed('karmasphere.a');
$q->feed('karmasphere.fb');
$q->combiner('karmasphere.other');
$q->combiner('karmasphere.a');
$q->combiner('karmasphere.cb');
my $s = $q->as_string;

like($s, qr/Combiner.*\.other/, 'Contains other combiner');
like($s, qr/Combiner.*\.a/, 'Contains a combiner');
like($s, qr/Combiner.*\.cb/, 'Contains cb combiner');

like($s, qr/Feed.*\.test/, 'Contains test feed');
like($s, qr/Feed.*\.a/, 'Contains a feed');
like($s, qr/Feed.*\.fb/, 'Contains fb feed');

like($s, qr/Identity.*foo.*=.*a\.b\.c/, 'Contains foo identity');
