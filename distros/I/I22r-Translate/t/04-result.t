use Test::More;
use I22r::Translate::Result;

my $r = I22r::Translate::Result->new(
    id => 'foo',
    olang => 'en',
    otext => 'hello world',
    lang => 'fr',
    text => 'bonjour monde',
    source => 'none',
    time => time);

ok($r);
   

done_testing();
