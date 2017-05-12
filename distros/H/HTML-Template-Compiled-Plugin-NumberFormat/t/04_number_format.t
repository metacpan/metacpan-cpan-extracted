use constant SKIPTESTS => 2;
use Test::More tests => SKIPTESTS + 3;
use strict;
use warnings;
BEGIN { use_ok('HTML::Template::Compiled::Plugin::NumberFormat') };
my $pd = eval "use Parse::RecDescent; 1";

my $nf_version = Number::Format->VERSION;
my $nf1 = Number::Format->new(
    -thousands_sep      => '.',
    -decimal_point      => ',',
    -int_curr_symbol    => "\x{20ac}",
    -kilo_suffix        => 'Kb',
    -mega_suffix        => 'Mb',
    -decimal_digits     => 2,
);
my $nf2 = Number::Format->new(
    -thousands_sep      => ',',
    -decimal_point      => '.',
    -int_curr_symbol    => '$',
    -kilo_suffix        => 'K',
    -mega_suffix        => 'M',
    -decimal_digits     => 2,
);
my @nf = ($nf1, $nf2);
my $t_plug = <<"EOM";
<%= .nums.big escape=format_number %>
<%format_number .nums.big_dec precision=3 %>
<%format_number .nums.big_dec precision=3 type=price %>
<%format_number .nums.big_dec precision=3 type=bytes %>
<%= .nums.price escape=format_price %>
<%= .nums.bytes1 escape=format_bytes %>
<%= .nums.bytes2 escape=format_bytes %>
<%= .nums.bytes3 escape=format_bytes %>
EOM
my %p = (
    nf1 => $nf1,
    nf2 => $nf2,
    nums => {
        big => 123_456_789_123,
        big_dec => 123_456_789_123.765,
        price => 459.95,
        bytes1 => 1_024,
        bytes2 => 1_500,
        bytes3 => 1_500_000,
    },
);


my $plug = HTML::Template::Compiled::Plugin::NumberFormat->new({
});
my $t = <<"EOM";
<%= expr=".nfx.format_number(.nums{'big'})" %>
<%= expr=".nfx.format_number(.nums{'big_dec'}, 3)" %>
<%= expr=".nfx.format_price(.nums{'big_dec'}, 3)" %>
<%= expr=".nfx.format_bytes(.nums{'big_dec'}, 'precision', 3)" %>
<%= expr=".nfx.format_price(.nums{'price'})" %>
<%= expr=".nfx.format_bytes(.nums{'bytes1'})" %>
<%= expr=".nfx.format_bytes(.nums{'bytes2'})" %>
<%= expr=".nfx.format_bytes(.nums{'bytes3'})" %>
EOM
test_nf($plug);
SKIP: {
    skip "no Parse::RecDescent", SKIPTESTS unless $pd;
    test_nf();
}

sub test_nf {
    my ($plug) = @_;
    for my $count (1, 2) {
        my $htc;
        my $nf = $nf[$count - 1];
        if ($plug) {
            $htc = HTML::Template::Compiled->new(
                scalarref => \$t_plug,
                debug => 0,
                plugin => [$plug],
            );
            $plug->formatter($nf);
        }
        else {
            my $html = $t;
            $html =~ s/nfx/nf$count/g;
            $htc = HTML::Template::Compiled->new(
                scalarref => \$html,
                debug => 0,
                use_expressions => 1,
            );
        }
        $htc->param( %p );
        my $exp = '';
        $exp .= <<"EOM";
@{[ $nf->format_number($p{nums}->{big}) ]}
@{[ $nf->format_number($p{nums}->{big_dec}, 3) ]}
@{[ $nf->format_price($p{nums}->{big_dec}, 3) ]}
@{[ $nf->format_bytes($p{nums}->{big_dec}, precision => 3) ]}
@{[ $nf->format_price($p{nums}->{price}) ]}
@{[ $nf->format_bytes($p{nums}->{bytes1}) ]}
@{[ $nf->format_bytes($p{nums}->{bytes2}) ]}
@{[ $nf->format_bytes($p{nums}->{bytes3}) ]}
EOM
        my $out = $htc->output;
        if ($plug) {
            cmp_ok($out, "eq", $exp, "Number::Format $nf_version (plugin)");
        }
        else {
            cmp_ok($out, "eq", $exp, "Number::Format $nf_version (expressions)");
        }
    }


}

