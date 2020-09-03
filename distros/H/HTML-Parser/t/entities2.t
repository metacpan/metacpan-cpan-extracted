use strict;
use warnings;
use utf8;

use HTML::Entities qw(_decode_entities);
use Test::More tests => 9;

{
    local $@;
    my $error;

    #<<<  do not let perltidy touch this
    $error = $@ || 'Error' unless eval {
        _decode_entities("&lt;", undef);
        1;
    };
    #>>>
    like($error,
        qr/^(?:Can't inline decode readonly string|Modification of a read-only value attempted)/
    );
}

{
    local $@;
    my $error;

    #<<<  do not let perltidy touch this
    $error = $@ || 'Error' unless eval {
        my $x = "";
        _decode_entities($x, $x);
        1;
    };
    #>>>
    like($error, qr/^2nd argument must be hash reference/);
}

{
    local $@;
    my $error;

    #<<<  do not let perltidy touch this
    $error = $@ || 'Error' unless eval {
        my $x = "";
        _decode_entities($x, []);
        1;
    };
    #>>>
    like($error, qr/^2nd argument must be hash reference/);
}

my $x = "&lt;";
_decode_entities($x, undef);
is($x, "&lt;");

_decode_entities($x, {"lt" => "<"});
is($x, "<");

$x = "x" x 20;

my $err;
for (":", ":a", "a:", "a:a", "a:a:a", "a:::a") {
    my $x = $_;
    $x =~ s/:/&a;/g;
    my $y = $_;
    $y =~ s/:/$x/g;
    _decode_entities($x, {"a" => $x});
    if ($x ne $y) {
        diag "Something went wrong with '$_'";
        $err++;
    }
}
ok(!$err);

$x = "foo&nbsp;bar";
_decode_entities($x, \%HTML::Entities::entity2char);
is($x, "foo\xA0bar");

$x = "foo&nbspbar";
_decode_entities($x, \%HTML::Entities::entity2char);
is($x, "foo&nbspbar");

_decode_entities($x, \%HTML::Entities::entity2char, 1);
is($x, "foo\xA0bar");
