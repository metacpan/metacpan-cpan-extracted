use strict;
use warnings;

use HTML::Parser ();
use Test::More tests => 5;

# Check that the magic signature at the top of struct p_state works and that we
# catch modifications to _hparser_xs_state gracefully

my $p = HTML::Parser->new(api_version => 3);
$p->xml_mode(1);

# We should not be able to simply modify this stuff
{
    local $@;
    my $error;
    #<<<  do not let perltidy touch this
    $error = $@ || 'Error' unless eval {
        ${$p->{_hparser_xs_state}} += 4;
        1;
    };
    #>>>
    like($error, qr/^Modification of a read-only value attempted/);
}

my $x = delete $p->{_hparser_xs_state};
{
    local $@;
    my $error;
    #<<<  do not let perltidy touch this
    $error = $@ || 'Error' unless eval {
        $p->xml_mode(1);
        1;
    };
    #>>>
    like($error, qr/^Can't find '_hparser_xs_state'/);
}

$p->{_hparser_xs_state} = \($$x + 16);
{
    local $@;
    my $error;
    #<<<  do not let perltidy touch this
    $error = $@ || 'Error' unless eval {
        $p->xml_mode(1);
        1;
    };
    #>>>
    like($error, qr/^Lost parser state magic/);
}

$p->{_hparser_xs_state} = 33;
{
    local $@;
    my $error;
    #<<<  do not let perltidy touch this
    $error = $@ || 'Error' unless eval {
        $p->xml_mode(1);
        1;
    };
    #>>>
    like($error, qr/^_hparser_xs_state element is not a reference/);
}

$p->{_hparser_xs_state} = $x;
ok($p->xml_mode(0));
