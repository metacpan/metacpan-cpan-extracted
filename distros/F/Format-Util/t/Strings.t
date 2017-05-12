use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use Test::NoWarnings;

use Math::BigInt;

use Format::Util::Strings qw(defang defang_lite set_selected_item);

subtest 'defang protects us from teen-aged girls' => sub {
    plan tests => 9;

    is(defang_lite, '', 'defang_lite');
    is(defang,      '', 'defang');

    is(defang_lite('0'), '0', 'defang_lite "0"');
    is(defang('0'),      '0', 'defang "0"');

    my $scary_string = 'I <3 ~you~';

    is(defang_lite($scary_string), 'I  3 ~you~', 'defang_lite replaces the very dangerous < character');
    is(defang($scary_string),      'I  3  you ', 'defang replaces even more exciting stuff');

    my $long_string = '';
    is(defang($long_string), '', 'Your empty string comes back empty.');
    while (length $long_string < 600) {
        $long_string .= $scary_string;
    }
    my $same_long_string = $long_string;

    is(length defang_lite($long_string),      500, 'defang_lite truncates long strings..');
    is(length defang_lite($same_long_string), 500, '... and defang does too!');
};

subtest 'set_selected_item' => sub {
    plan tests => 4;

    my $options = {
        input => {
            options => [{
                    name  => 'picked',
                    value => 'thisone'
                },
                {
                    name  => 'unpicked',
                    value => 'nope'
                }]}};

    is(set_selected_item('thisone', $options), 1, 'wherein we used a string package and it claims to have found and set the selected item');
    is($options->{input}->{options}->[0]->{selected},        'selected', '...and it did');
    is(exists $options->{input}->{options}->[1]->{selected}, '',         '...without changing other stuff.');
    my $html_string =
        '<select name="us" id="b_u"> <option value="WOW">WOW</option><option value="WOW2">WOW2</option><option selected="selected" disabled="disabled" value="WOW3" class="disabled">WOW3</option><option value="WOW4">WOW4</option> </select>';
    my $selected_html =
        '<select name="us" id="b_u"> <option value="WOW">WOW</option><option value="WOW2">WOW2</option><option selected="selected" disabled="disabled" value="WOW3" class="disabled">WOW3</option><option value="WOW4">WOW4</option> </select>';

    is(set_selected_item('WOW3', $html_string), $selected_html, 'Plus it "works" on strings!');
};

1;
