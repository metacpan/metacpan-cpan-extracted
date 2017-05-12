use strict;
use warnings;

use Test::More tests => 17;

require_ok('HTML::Laundry');
use URI;
use HTML::Laundry::Rules;
use HTML::Laundry::Rules::Default;
use HTML::Laundry::Rules::Minimal;

my $str = q{<p class="lyrics"><span>I wanna be instamatic</span></p>};

my $l1 = HTML::Laundry->new( 'HTML::Laundry::Rules::Minimal' );
ok( $l1, 'Creating Laundry object with scalar ruleset classname argument' );
is( $l1->clean( $str ), q{<p>I wanna be instamatic</p>},
    'HTML::Laundry::Rules::Minimal removes <span> tag, "class" attribute');
my $minimal = HTML::Laundry::Rules::Minimal->new();
my $l2 = HTML::Laundry->new( $minimal );
ok( $l2, 'Created Laundry object with ruleset object argument' );
is( $l2->clean( $str ), q{<p>I wanna be instamatic</p>},
    'HTML::Laundry::Rules::Minimal removes <span> tag, "class" attribute');
my $l3 = HTML::Laundry->new({ rules => $minimal });
ok( $l3, 'Created Laundry object with hash argument' );
is( $l3->clean( $str ), q{<p>I wanna be instamatic</p>},
    'HTML::Laundry::Rules::Minimal removes <span> tag, "class" attribute');
my $l4 = HTML::Laundry->new( 123 );
ok( $l4, 'Created Laundry object with scalar integer' );
is( $l4->clean( $str ), $str,
    'Ruleset defaults to HTML::Laundry::Rules::Default' );
my $l5 = HTML::Laundry->new( 'URI' );
ok( $l5, 'Created Laundry object with non-rules classname argument' );
is( $l5->clean( $str ), $str,
    'Ruleset defaults to HTML::Laundry::Rules::Default' );    
my $l6 = HTML::Laundry->new( [ ] );
ok( $l6, 'Created Laundry object with array-ref argument' );
is( $l6->clean( $str ), $str,
    'Ruleset defaults to HTML::Laundry::Rules::Default' );
my $l7 = HTML::Laundry->new({});
ok( $l7, 'Created Laundry object with empty hash argument' );
is( $l7->clean( $str ), $str,
    'Ruleset defaults to HTML::Laundry::Rules::Default' );
my $l8 = HTML::Laundry->new({});
ok( $l8, 'Created Laundry object with no argument' );
is( $l8->clean( $str ), $str,
    'Ruleset defaults to HTML::Laundry::Rules::Default' );