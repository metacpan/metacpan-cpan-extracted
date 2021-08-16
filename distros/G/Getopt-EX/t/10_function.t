use strict;
use warnings;
use utf8;
use Test::More;

use Getopt::EX::Colormap qw(colorize);

my %hash = (
    SUB => "",
    );

my $cm = Getopt::EX::Colormap->new(
    HASH => \%hash,
    );

# anonymous sub
$cm->load_params(qw( SUB=sub{"<$_>"} ));
is($cm->color("SUB", "text"), "<text>", "sub{...}");

# named sub
sub quote { "[ $_ ]" }
$cm->load_params(qw( SUB=&quote ));
is($cm->color("SUB", "text"),
    do { local $_="text"; $_=quote(); $_ },
    "&quote");

# multiple subs
sub indent { "> $_" }
$cm->load_params(qw( SUB=&quote;&indent ));
is($cm->color("SUB", "text"),
    do { local $_="text"; $_=quote(); $_=indent(); $_ },
    "&quote;&indent");

# multiple subs with color
$cm->load_params(qw( SUB=&quote;&indent;R ));
is($cm->color("SUB", "text"),
    do { local $_="text"; $_=quote(); $_=indent(); colorize('R', $_) },
    "&quote;&indent;R");

# call sub from anonymous sub
$cm->load_params(qw( SUB=sub{quote($_)} ));
is($cm->color("SUB", "text"),
    do { local $_ = "text"; $_=quote(); $_ },
    "call sub from anonymous sub");

done_testing;
