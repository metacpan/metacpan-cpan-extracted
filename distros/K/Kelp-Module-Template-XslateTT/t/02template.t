# $Id: 02template.t 62 2018-11-16 16:47:13Z stro $

use strict;
use warnings;

use lib 'lib', 't/lib';

use HTTP::Request::Common;
use Kelp::Test;
use Kelp::Module::Template::XslateTT;
use Test::More;

use TestApp;

ok my $app = TestApp->new();
ok my $xstt = $app->{'loaded_modules'}->{'Template::XslateTT'};
isa_ok $xstt => 'Kelp::Module::Template::XslateTT';

ok my $t = Kelp::Test->new('app' => $app);

$t->request( GET '/' )
  ->code_is(200)
  ->content_is($Kelp::Module::Template::XslateTT::VERSION);

done_testing();
