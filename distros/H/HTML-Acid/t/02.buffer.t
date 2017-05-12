use strict;
use warnings;
use Carp;
use Test::More tests =>7;
use Test::NoWarnings;
use HTML::Acid::Buffer;

my $acid = HTML::Acid::Buffer->new('blah');
isa_ok($acid, 'HTML::Acid::Buffer', 'is a HTML::Acid::Buffer');

$acid->set_attr({class=>'xxx',id=>'yyy'});
is_deeply($acid->get_attr, {class=>'xxx',id=>'yyy'}, 'attributes');
is($acid->state, '', 'empty state');

$acid->add('This is a ');
is($acid->state, 'This is a ', 'empty state');

$acid->add('cool sentence.');
is($acid->state, 'This is a cool sentence.', 'empty state');

is($acid->stop,
    '<blah class="xxx" id="yyy">This is a cool sentence.</blah>',
    'finished');

