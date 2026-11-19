use strict;
use warnings;
use utf8;

use HTML::Entities qw(_decode_entities);
use Test::More tests => 15;

{
    package EntityValueDeletesKey;
    use overload '""' => sub {
        delete $main::entity_table{foo};
        return "\x{100}";
    };
}

{
    our %entity_table = (
        foo   => bless({}, 'EntityValueDeletesKey'),
        other => 'unused',
    );
    my $text = '&foo;';
    _decode_entities($text, \%entity_table);
    is($text, "\x{100}", 'entity value survives deletion during stringification');
}

{
    our %entity_table = (
        foo   => bless({}, 'EntityValueDeletesKey'),
        other => 'unused',
    );
    my $text = '&foobar;';
    _decode_entities($text, \%entity_table, 1);
    is($text, "\x{100}bar;", 'prefix entity value survives deletion during stringification');
}

{
    my %entity_table = (foo => undef);
    my $warnings = 0;
    local $SIG{__WARN__} = sub {
        $warnings++;
        delete $entity_table{foo};
    };
    my $text = '&foo;';
    my $error = do { local $@; eval { _decode_entities($text, \%entity_table) }; $@ };
    like("$error", qr/^Entity value is undefined/, 'undefined entity value is rejected');
    is($warnings, 0, 'undefined value does not invoke a warning hook');

    my $prefix = '&foobar;';
    $error = do { local $@; eval { _decode_entities($prefix, \%entity_table, 1) }; $@ };
    like("$error", qr/^Entity value is undefined/, 'undefined prefix value is rejected');
    is($warnings, 0, 'undefined prefix does not invoke a warning hook');
}

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
