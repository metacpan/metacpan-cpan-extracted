use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('LaTeXML::Plugin::LtxMojo');
$t->get_ok('/')->status_is(302);
$t->get_ok('/about')->status_is(200);

done_testing();
