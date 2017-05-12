use strict;
use warnings;

use Test::More tests => 4;
use EntityModel::Web::PSGI;
my $psgi = new_ok('EntityModel::Web::PSGI');
can_ok($psgi, qw(run_psgi psgi_result web template));
$psgi->web(EntityModel::Web->new);
is(ref $psgi->run_psgi({}), 'ARRAY', 'returns arrayref with no streaming');
is(ref $psgi->run_psgi({'psgi.streaming' => '1'}), 'CODE', 'returns coderef with streaming');

