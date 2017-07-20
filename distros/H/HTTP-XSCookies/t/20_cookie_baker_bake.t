use strict;
use warnings;

use Date::Parse;
use Test::More;
use HTTP::XSCookies qw[bake_cookie];

exit main();

sub main {
    test_bake_simple();
    test_bake_time();
    test_url_encode();
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
        [
            't108',
            'foo',
            {
                value => 'val',
                Expires => $now + 24*60*60, # we pass an exact time
            },
            sprintf('foo=val; Expires=%s', format_time($now + 24*60*60)),
        ],
    );

    for my $test (@tests) {
        is( cookie_to_string(bake_cookie($test->[1], $test->[2])),
            cookie_to_string($test->[3]),
            sprintf('%s - baked simple cookie', $test->[0] ));
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

    my $name = 'foo';
    my $value = 'val';
    for my $test (@tests) {
        # we pass a relative time
        my $hash = { value => $value, Expires => $test->[1] };
        my $cookie = bake_cookie($name, $hash);

        my $now = time();
        my $expected = sprintf('%s=%s; Expires=%s', $name, $value,
                               format_time(($test->[1] eq '0' ? 0 : $now) + $test->[2]));

        my $string1 = cookie_to_string($cookie);
        my $string2 = cookie_to_string($expected);

        my $epoch1 = cookie_epoch($string1);
        my $epoch2 = cookie_epoch($string2);
        my $delta = abs($epoch1 - $epoch2);
        cmp_ok($delta, '<=', 1,
               sprintf("%s - baked cookie with expiration time '%s', times are within 1 second", $test->[0], $test->[1]));
    }
}

sub test_url_encode {

    is(bake_cookie( 'test', "!\"\x{a3}\$%^*(*^%\$\x{a3}\":1" ),
       'test=%21%22%a3%24%25%5e%2a%28%2a%5e%25%24%a3%22%3a1',
       'tested URL encode for cookie name with binary characters');
}

sub format_time {
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

sub cookie_to_string {
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

sub cookie_epoch {
    my ($cookie) = @_;
    # Expires=Wed, 18-Jul-2018 16:48:10 GMT
    $cookie =~ m/Expires=(.*)$/i;
    my $time = str2time($1);
    return $time;
}
