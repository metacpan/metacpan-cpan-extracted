use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use File::Spec;
use HTTP::Tiny;
use Test::More;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use Encode     ();
use List::Util qw(first);
use FixtureUA;

use utf8; # this file is written in utf8
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

# nicer output for diag and failures, see
# http://perldoc.perl.org/Test/More.html#CAVEATS-and-NOTES
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

## Make sure verbose messages go to the test output instead of STDOUT
## And with 'note' instead of 'diag' the output of test summaries stays
## clean
my $logging_callback = sub {
    my $message = shift;
    note $message;
};

## By default the tests use responses recorded from the API, saved in
## t/data/responses. To run them against the live API:
##
##   W3W_API_KEY=<your key> prove -l t/base.t
##
## and to update the recorded responses:
##
##   W3W_API_KEY=<your key> W3W_RECORD=1 prove -l t/base.t
##
## W3W_API_ENDPOINT=<url> sends those requests to another server, e.g. a
## self-hosted installation, instead of https://api.what3words.com/v3/
##
die "W3W_RECORD needs W3W_API_KEY\n" if ($ENV{W3W_RECORD} && !$ENV{W3W_API_KEY});

my $api_key      = $ENV{W3W_API_KEY} || 'randomteststring';
my $live         = $ENV{W3W_API_KEY} && !$ENV{W3W_RECORD};
my $api_endpoint = $ENV{W3W_API_ENDPOINT};
my $fixture_dir  = File::Spec->catdir($FindBin::Bin, 'data', 'responses');

sub test_ua {
    my $label = shift;
    return HTTP::Tiny->new() if $live;
    return FixtureUA->new(dir => $fixture_dir, label => $label, record => $ENV{W3W_RECORD});
}

my $ua = test_ua('base');

use Geo::What3Words;

## Missing API key
##
dies_ok {
    Geo::What3Words->new(logging => $logging_callback);
}
'dies when missing key';

## These methods don't access the HTTP API
##
{
    my $w3w = Geo::What3Words->new(key => $api_key, ua => $ua, logging => $logging_callback);
    is($w3w->valid_words_format('abc.def.ghi'),     1, 'valid_words_format - valid');
    is($w3w->valid_words_format('abcdef.ghi'),      0, 'valid_words_format - only two');
    is($w3w->valid_words_format('abc.def.ghi.jkl'), 0, 'valid_words_format - too many');
    is($w3w->valid_words_format('Abc.def.ghi'),     0, 'valid_words_format - not all lowercase');
    is($w3w->valid_words_format(''),                0, 'valid_words_format - empty');
    is($w3w->valid_words_format(),                  0, 'valid_words_format - undef');

    is($w3w->valid_words_format('meyal.şifalı.döşeme'), 1, 'valid_words_format - valid Turkish utf8');
    is($w3w->valid_words_format('диета.новшество.компаньон'),
        1, 'valid_words_format - valid Russian utf8');
    is($w3w->valid_words_format('Mосква.def.ghi'), 0, 'valid_words_format - not all lowercase utf8');
}

## Net::Ping is only loaded when calling ping()
##
ok(!exists($INC{'Net/Ping.pm'}), 'Net::Ping not loaded on startup');

## Fake user agent, records requested URLs and returns a canned response
##
{

    package FakeUA;
    sub new {
        my ($class, $content, $status) = @_;
        return bless {content => $content, status => $status || 200, urls => []}, $class;
    }
    sub agent { }

    sub get {
        my ($self, $url) = @_;
        push @{$self->{urls}}, $url;
        return {
            success => ($self->{status} == 200 ? 1 : 0),
            status  => $self->{status},
            reason  => 'Some Reason',
            content => $self->{content}
        };
    }
}

## Request building and response decoding, no HTTP API access
##
{
    ## raw UTF-8 bytes, like HTTP::Tiny returns them
    my $content
        = '{"words":"' . Encode::encode_utf8('диета.новшество.компаньон') . '","language":"ru"}';
    my $fake_ua = FakeUA->new($content);
    my $w3w     = Geo::What3Words->new(key => 'abc', ua => $fake_ua, logging => $logging_callback);

    is( $w3w->pos2words('51.484463,-0.195405', 'ru'),
        'диета.новшество.компаньон',
        'pos2words - decodes utf8'
    );
    is( $fake_ua->{urls}->[0],
        'https://api.what3words.com/v3/convert-to-3wa?coordinates=51.484463%2C-0.195405&format=json&key=abc&language=ru',
        'pos2words - request url'
    );

    $w3w->position_to_words('51.484463,-0.195405');
    unlike($fake_ua->{urls}->[1], qr/language/, 'position_to_words - no language parameter if not set');

    $w3w->words_to_position('prom.cape.pump');
    like(
        $fake_ua->{urls}->[2],
        qr{/convert-to-coordinates\?format=json&key=abc&words=prom\.cape\.pump$},
        'words_to_position - request url'
    );

    $w3w->words_to_position('///Index.Home.Raft');
    is(scalar(@{$fake_ua->{urls}}), 4, 'words_to_position - lenient check passes on input valid_words_format rejects');
}

## Invalid input is rejected without calling the HTTP API
##
{
    my $fake_ua = FakeUA->new('{}');
    my $w3w     = Geo::What3Words->new(key => 'abc', ua => $fake_ua, logging => $logging_callback);

    foreach my $words (undef, '', 'abc.def', 'abc.def.ghi.jkl', 'abc..ghi', 'abc def.ghi.jkl') {
        my $label = defined($words) ? "'$words'" : 'undef';
        warning_like {
            is($w3w->words_to_position($words), undef, "words_to_position - invalid $label");
        }
        qr/invalid 3 word address/, "words_to_position - warning for $label";
        is($w3w->error->{code}, 'BadWords', "words_to_position - error code for $label");
    }

    foreach my $position (undef, '', 'invalid,coords', '1', '1,2,3', '91,0', '0,181', '-90.1,0') {
        my $label = defined($position) ? "'$position'" : 'undef';
        warning_like {
            is($w3w->pos2words($position), undef, "pos2words - invalid $label");
        }
        qr/invalid coordinates/, "pos2words - warning for $label";
        is($w3w->error->{code}, 'BadCoordinates', "pos2words - error code for $label");
    }

    is(scalar(@{$fake_ua->{urls}}), 0, 'invalid input - no API requests');

    ## valid edge cases still reach the API
    $w3w->position_to_words($_) for ('90,180', '-90,-180', ' 1.5 , -.5 ', '+1,2.');
    is(scalar(@{$fake_ua->{urls}}), 4,     'position_to_words - valid edge cases call the API');
    is($w3w->error,                 undef, 'error - cleared after a successful request');
}

## Error details from failed requests, no HTTP API access
##
{
    my $fake_ua = FakeUA->new('{"error":{"code":"QuotaExceeded","message":"Quota Exceeded"}}', 402);
    my $w3w     = Geo::What3Words->new(key => 'abc', ua => $fake_ua, logging => $logging_callback);
    warning_like { is($w3w->pos2words('1,2'), undef, 'error - failed request') } qr/402/, 'error - warning';
    is_deeply(
        $w3w->error,
        {status => 402, code => 'QuotaExceeded', message => 'Quota Exceeded'},
        'error - code and message from the API'
    );

    $fake_ua = FakeUA->new("Could not connect to 'api.what3words.com:443': timeout\n", 599);
    $w3w     = Geo::What3Words->new(key => 'abc', ua => $fake_ua, logging => $logging_callback);
    warning_like { $w3w->get_languages() } qr/599/, 'error - connection failure warning';
    is_deeply(
        $w3w->error,
        {status => 599, code => undef, message => "Could not connect to 'api.what3words.com:443': timeout\n"},
        'error - connection failure'
    );

    $fake_ua = FakeUA->new('<html>Bad Gateway</html>', 502);
    $w3w     = Geo::What3Words->new(key => 'abc', ua => $fake_ua, logging => $logging_callback);
    warning_like { $w3w->get_languages() } qr/502/, 'error - non JSON error warning';
    is_deeply($w3w->error, {status => 502, code => undef, message => 'Some Reason'}, 'error - non JSON error');
}

## The API key is sent, but never shown in warnings or logs
##
{
    my $fake_ua = FakeUA->new('{"error":{"code":"InvalidKey","message":"invalid API key"}}', 401);
    my @log;
    my $w3w = Geo::What3Words->new(key => 'secret-key-123', ua => $fake_ua, logging => sub { push @log, shift });

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, shift };
        $w3w->pos2words('1,2');
    }

    like($fake_ua->{urls}->[0], qr/[?&]key=secret-key-123(&|$)/, 'api key - sent in request');
    is(scalar(@warnings), 1, 'api key - got warning');
    unlike($warnings[0], qr/secret-key-123/, 'api key - not in warning');
    like($warnings[0], qr/[?&]key=XXXX[&:]/, 'api key - blanked out in warning');
    ok(scalar(@log) >= 2, 'api key - got log messages');
    is((grep {/secret-key-123/} @log), 0, 'api key - not in log messages');
}

## Host extraction for ping()
##
is(Geo::What3Words::_host_from_url('https://api.what3words.com/v3/'), 'api.what3words.com', '_host_from_url - host');
is(Geo::What3Words::_host_from_url('http://user:pw@127.0.0.1:8080/v3/'),
    '127.0.0.1', '_host_from_url - ip, port and userinfo');
is(Geo::What3Words::_host_from_url('http://[::1]:8080/v3/'), '::1', '_host_from_url - ipv6');
is(Geo::What3Words::_host_from_url('not a url'),             undef, '_host_from_url - invalid');


## Invalid API key
##
## Always uses the public API, even with W3W_API_ENDPOINT set: a self-hosted
## installation might not check keys. Only sends the made-up key below.
##
warning_like {
    my $w3w = Geo::What3Words->new(key => 'rubbish-key', ua => test_ua('invalid-key'), logging => $logging_callback);
    is($w3w->pos2words('1,2'), undef, 'invalid key');
    my $error = $w3w->error || {};
    is($error->{status}, 401,          'invalid key - error status');
    is($error->{code},   'InvalidKey', 'invalid key - error code');
}
qr/401/, 'got 401 warning';


my $w3w = Geo::What3Words->new(key => $api_key, api_endpoint => $api_endpoint, ua => $ua, logging => $logging_callback);
isa_ok($w3w, 'Geo::What3Words');


##
## POS2WORDS, WORDS2POS
##

{
    my $words = $w3w->pos2words('51.484463,-0.195405');
    ok($w3w->valid_words_format($words), 'pos2words');

    my $pos = $w3w->words2pos($words);
    like($pos, qr/^51.\d+,-0.19\d+$/, 'words2pos');


    warning_like { is($w3w->pos2words('invalid,coords'), undef, 'pos2words - invalid input') } qr/invalid coordinates/,
        'pos2words - invalid input warning';
    warning_like { is($w3w->words2pos('does.not.exist'), undef, 'words2pos - unknown words') } qr/failed response/,
        'words2pos - unknown words warning';
    my $error = $w3w->error || {};
    like($error->{status}, qr/^4\d\d$/, 'words2pos - unknown words error status');
    ok($error->{code}, 'words2pos - unknown words error code');

}


##
## POSITION_TO_WORDS
##

my $lat = 51.484463;
my $lng = -0.195405;
my $three_words_string;
my $three_words_string_russian;

{
    my $res = $w3w->position_to_words($lat . ',' . $lng);
    #print STDERR Dumper $res;
    is($res->{language}, 'en', 'position_to_words - language');
    is_deeply([$res->{coordinates}->{lat}, $res->{coordinates}->{lng}], [$lat, $lng], 'position_to_words - position');

    $three_words_string = $res->{words};
    ok($w3w->valid_words_format($three_words_string), 'position_to_words - got 3 words');

    ## now Russian, питомец.шутить.намеренно
    my $res_ru = $w3w->position_to_words($lat . ',' . $lng, 'ru');
    $three_words_string_russian = $res_ru->{words};

    isnt($three_words_string, $three_words_string_russian, 'position_to_words - english vs russian');
}


##
## WORDS_TO_POSITION
##
{
    my $res = $w3w->words_to_position($three_words_string);
    #print STDERR Dumper $res;

    is($res->{language}, 'en', 'words_to_position - language');
    is_deeply([$res->{coordinates}->{lat}, $res->{coordinates}->{lng}], [$lat, $lng], 'words_to_position - position');
    is($res->{words}, $three_words_string, 'words_to_position - words');
}


##
## GET_LANGUAGES
##
{
    my $res       = $w3w->get_languages() || {};
    my $languages = $res->{languages}     || [];

    ok(scalar(@$languages) > 1, 'get_languages - at least one');

    my $rh_lang = first { $_->{'code'} eq 'ru' } @$languages;
    like($rh_lang->{name},       qr/^Russian/,        'get_languages - name');
    like($rh_lang->{nativeName}, qr/^Русский/, 'get_languages - name encoded in utf8');
}


done_testing();
1;
