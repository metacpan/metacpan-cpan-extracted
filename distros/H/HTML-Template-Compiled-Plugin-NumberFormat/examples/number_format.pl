#!/usr/bin/perl
# vim:et:sts=4:sws=4:sw=4
use 5.010;
use strict;
use warnings;
use HTML::Template::Compiled;
use HTML::Template::Compiled::Plugin::NumberFormat;
use Number::Format;
my $template = <<"EOM";
<%= .nums.big escape=format_number %>
<%format_number .nums.big_dec precision=3 %>
<%= .nums.price escape=format_price %>
<%= .nums.bytes1 escape=format_bytes %>
<%= .nums.bytes2 escape=format_bytes %>
<%= .nums.bytes3 escape=format_bytes %>
EOM
my $nf = Number::Format->new(
    -thousands_sep      => '.',
    -decimal_point      => ',',
    -int_curr_symbol    => "\x{20ac}",
    -kilo_suffix        => 'Kb',
    -mega_suffix        => 'Mb',
    -decimal_digits     => 2,
);

my $plug = HTML::Template::Compiled::Plugin::NumberFormat->new({
    formatter => $nf,
});
my $htc = HTML::Template::Compiled->new(
    scalarref => \$template,
    plugin => [$plug],
);

my %p = (
    nums => {
        big => 123_456_789_123,
        big_dec => 123_456_789_123.765,
        price => 459.95,
        bytes1 => 1_024,
        bytes2 => 1_500,
        bytes3 => 1_500_000,
    },
);
$htc->param( %p );

binmode STDOUT, ":encoding(utf-8)";
say $htc->output;
