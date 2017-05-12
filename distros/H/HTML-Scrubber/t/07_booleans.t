# 07_booleans.t

use strict;
use File::Spec;
use Test::More tests => 9;
BEGIN { $^W = 1 }

use_ok('HTML::Scrubber');

use HTML::Scrubber;
my @allow    = qw[ br hr b a option button th ];
my $scrubber = HTML::Scrubber->new();
$scrubber->allow(@allow);
$scrubber->default(
    undef,    # don't change
    {         # default attribute rules
        '/'        => 1,    # '/' ia boolean (stand-alone) attribute
        'pie'      => 1,
        'selected' => 1,
        'disabled' => 1,
        'nowrap'   => 1,
    }
);

ok( $scrubber, "got scrubber" );

test( q~<br> hi <br /> <a href= >~, q~<br> hi <br /> <a>~, "br /" );

test( q~<option selected> flicka <a href=>~, q~<option selected> flicka <a>~, "selected" );

test(
    q~<button name="flicka" Disabled > the flicker </button>~,
    q~<button disabled> the flicker </button>~,
    "disabled"
);

test( q~<button disabled > dd </button>~, q~<button disabled> dd </button>~, "dd" );

test( q~<a disabled pie=6> | </a>~, q~<a disabled pie="6"> | </a>~, "pie" );

test(
    q~<a selected disabled selected pie pie pie disabled /> | </a>~,
    q~<a selected disabled pie /> | </a>~,
    "selected pie"
);

#dependent on version of HTML::Parser, after 0.36 1st is returned (ie pie)
#test(q~<br pie pie=4>~, q~<br pie="4">~, 'repeated mixed');

test( q~<th nowrap=nowrap>~, q~<th nowrap="nowrap">~, "th nowrap=nowrap" );

sub test {
    my ( $in, $out, $name ) = @_;
    is( $scrubber->scrub($in), $out, $name );
}

