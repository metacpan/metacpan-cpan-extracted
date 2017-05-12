use strict;
use warnings;

use Test::More;
use HTTP::XSCookies qw[bake_cookie];

exit main();

sub main {
    test_bake_simple();
    test_bake_time();
    done_testing();

    return 0;
}

sub test_bake_simple {
    my $now = time();

    my @tests = (
        [ 't100', 'foo', 'val', 'foo=val'],
        [ 't101', 'foo', { value => 'val' }, 'foo=val'],
        [ 't102', 'foo', { value => 'foo bar baz' }, 'foo=foo%20bar%20baz'],
        [ 't103', 'foo', { value => 'val', Expires => undef }, 'foo=val'],
        [ 't104', 'foo', { value => 'val', Path => '/' }, 'foo=val; Path=/'],
        [ 't105', 'foo', { value => 'val', Path => '/', Secure => 1, HttpOnly => 0 }, 'foo=val; Path=/; Secure'],
        [ 't106', 'foo', { value => 'val', Path => '/', Secure => 0, HttpOnly => 1 }, 'foo=val; Path=/; HttpOnly'],
        [ 't107', 'foo', { value => 'val', Expires => 'foo' }, 'foo=val; Expires=foo'],
        [ 't108', 'foo', { value => 'val', Expires => $now + 24*60*60 }, sprintf('foo=val; Expires=%s', fmt($now + 24*60*60))],
    );

    for my $test (@tests) {
        printf("Running %s...\n", $test->[2]);
        is( sc(bake_cookie($test->[1], $test->[2])), sc($test->[3]), $test->[0] );
    }
}

sub test_bake_time {

    my @tests = (
        [ 't200', 'now' ,  0 ],
        [ 't201', '1s'  , +1 ],
        [ 't202', '+10' , +10 ],
        [ 't203', '+1m' , +60 ],
        [ 't204', '+1h' , +60*60 ],
        [ 't205', '+1d' , +24*60*60 ],
        [ 't206', '-1d' , -24*60*60 ],
        [ 't207', '+1M' , +30*24*60*60 ],
        [ 't208', '+1y' , +365*24*60*60 ],
        [ 't209', '0'   , +0 ],
        [ 't210', '-1'  , -1 ],
    );

    for my $test (@tests) {
        printf("Running %s...\n", $test->[0]);
        my $now = time();
        my $value = { value => 'val', Expires => $test->[1] };
        my $expected = sprintf('foo=val; Expires=%s',
                               fmt(($test->[1] eq '0' ? 0 : $now) + $test->[2]));

        is( sc(bake_cookie('foo', $value)), sc($expected), $test->[0] );
    }
}

sub fmt {
    my ($time) = @_;

    my @Mon = qw{
            Jan
            Feb
            Mar
            Apr
            May
            Jun
            Jul
            Aug
            Sep
            Oct
            Nov
            Dec
        };
    my @Day = qw{
            Sun
            Mon
            Tue
            Wed
            Thu
            Fri
            Sat
        };

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time);
    return sprintf("%3s, %02d-%3s-%04d %02d:%02d:%02d GMT",
                   $Day[$wday], $mday, $Mon[$mon], $year+1900,
                   $hour, $min, $sec);
}

sub sc {
    my ($str) = @_;

    my @parts = split('; ', $str);
    return $str unless @parts > 1;

    my $first = $parts[0];
    @parts = @parts[1..$#parts];
    my %fields;
    for my $part (@parts) {
        my @p = split('=', $part);
        next unless @p == 2;
        $fields{$p[0]} = $p[1];
    }

    $str = $first;
    for my $key (sort keys %fields) {
        $str .= sprintf("; %s=%s", $key, $fields{$key});
    }
    return $str;
}
