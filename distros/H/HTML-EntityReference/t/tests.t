use strict;
use warnings;
use utf8;
use Test::More;
use Test::Fatal;

use HTML::EntityReference;

ok (HTML::EntityReference::ordinal('ldquo') == 8220, 'ordinal()');
ok (HTML::EntityReference::valid('ldquo') , 'valid()');
is (HTML::EntityReference::character('amp') , '&',    'character()');
ok (!defined HTML::EntityReference::character('foobar'), 'character returns undef');
is (HTML::EntityReference::hex('thinsp'), '2009',   'hex()');
ok (HTML::EntityReference::valid('clubs'), 'valid()');
ok (! HTML::EntityReference::valid('cokebottle'), 'valid()');

is (HTML::EntityReference::from_ordinal(0x2026), 'hellip',  'from_ordinal()');
is (HTML::EntityReference::from_character('<'), 'lt',   'from_character()');
ok (!defined HTML::EntityReference::from_character('A'),    'from_character() undefined');

ok (HTML::EntityReference::ordinal('lceil', 'HTML4') == 8968,   q{ordinal('lceil', 'HTML4')});
ok (HTML::EntityReference::ordinal('CapitalDifferentialD', 'HTML5_draft') == 0x2145,   
        q{ordinal('CapitalDifferentialD', 'HTML5_draft')});

ok (HTML::EntityReference::ordinal('CapitalDifferentialD', ':all') == 0x2145,   
        q{ordinal('CapitalDifferentialD', ':all')});

ok (HTML::EntityReference::valid('CapitalDifferentialD', ':all') ,   q{valid('CapitalDifferentialD', ':all')});

my $test_name= "no such bundle";
my $err= exception { HTML::EntityReference::ordinal('CapitalDifferentialD', ':fooXX') } ;
ok (defined $err, $test_name);
like ($err, qr/:fooXX/, "$test_name - mentions cause of error");
like ($err, qr/at t[\\\/]tests\.t/, "$test_name - carps correctly");


$test_name= "no such table";
$err= exception { HTML::EntityReference::ordinal('nosuchFoo', [ qw/HTML4 HTMLL5/ ] ) } ;
ok (defined $err, $test_name);
like ($err, qr/HTMLL5/, "$test_name - mentions cause of error");
like ($err, qr/at t[\\\/]tests\.t/, "$test_name - carps correctly");



#     NotNestedGreaterGreater => [0x2AA2, 0x338],
is_deeply (HTML::EntityReference::ordinal('NotNestedGreaterGreater','HTML5_draft'), [0x2AA2, 0x338],
        q{ordinal('NotNestedGreaterGreater') is two values } );

is (HTML::EntityReference::character('NotNestedGreaterGreater','HTML5_draft'), "\x{2aa2}\x{338}",
        q{character('NotNestedGreaterGreater') is two code points } );

is (HTML::EntityReference::from_ordinal([0x2AA1, 0x338], 'HTML5_draft'), 'NotNestedLessLess',
        q{from_ordinal([0x2AA1, 0x338], 'HTML5_draft')}  );
        
is (HTML::EntityReference::from_character("\x{2aa2}\x{338}", ':all'), 'NotNestedGreaterGreater',
        q{from_character("\x{2aa2}\x{338}", ':all')}  );

is (HTML::EntityReference::from_ordinal([234]), 'ecirc', q{ordinal takes array form with one item});
        
is (HTML::EntityReference::format ('&#x%X;', 'NotHumpDownHump', 'HTML5_draft'), "&#x224E; &#x338;",
        q{format in scalar context} );

my @list= HTML::EntityReference::format ('&#x%X;', 'NotHumpDownHump', 'HTML5_draft');
is_deeply (\@list, [ "&#x224E;",  "&#x338;" ],  q{format in list context} );

done_testing();
