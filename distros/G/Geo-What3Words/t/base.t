use strict;
use Test::More tests => 27;
use Test::Exception;
use Test::Warn;
use Data::Dumper;
use List::Util qw(first);
use Test::LWP::Recorder;

use utf8; # this file is written in utf8
binmode STDOUT, ':utf8'; 
binmode STDERR, ':utf8';

# nicer output for diag and failures, see
# http://perldoc.perl.org/Test/More.html#CAVEATS-and-NOTES
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";






## Make sure verbose messages go to the test output instead of STDOUT
## And with 'note' instead of 'diag' the output of test summaries stays
## clean
my $logging_callback = sub {
  my $message = shift;
  note $message;
};


## Instead of live HTTP requests we recorded the responses. To re-record
## them set these two variables, e.g. 
## PERLLIB=./lib W3W_RECORD_REQUESTS=1 W3W_API_KEY=<your key> perl t/base.t
##
my $w3w_record = $ENV{W3W_RECORD_REQUESTS} ? 1 : 0;
my $api_key    = $ENV{W3W_API_KEY} || 'randomteststring';

my $ua = Test::LWP::Recorder->new({
    record => $w3w_record,
    cache_dir => 't/LWPCache', 
    filter_params => [qw(key)],
    filter_header => [qw(Client-Peer Expires Client-Date Cache-Control)],
});

use Geo::What3Words;



## Missing API key
##
dies_ok {
  Geo::What3Words->new( logging => $logging_callback);
} 'missing key';

## Invalid API key
##
warning_like {
  my $w3w = Geo::What3Words->new( key => 'rubbish-key', ua => $ua, logging => $logging_callback );
  is( $w3w->pos2words('1,2'), undef, 'invalid key');
} qr/Unauthorized/, 'got warning';





my $w3w = Geo::What3Words->new( key => $api_key, ua => $ua, logging => $logging_callback );
isa_ok($w3w, 'Geo::What3Words');







##
## POS2WORDS, WORDS2POS
##

{
  my $words = $w3w->pos2words('51.484463,-0.195405');
  ok( $w3w->valid_words_format($words), 'pos2words');

  my $pos = $w3w->words2pos($words);
  like($pos, qr/^51.\d+,-0.19\d+$/, 'words2pos');


  is ( $w3w->pos2words('invalid,coords'), undef, 'pos2words - invalid input' );
  is ( $w3w->words2pos('does.not.exist'), undef, 'words2pos - invalid input' );

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



  is($res->{language}, 'en', 'words_to_position - language');
  is_deeply(
    [ $res->{geometry}->{lat}, $res->{geometry}->{lng} ],
    [ $lat, $lng ],
    'words_to_position - position'
  );

  $three_words_string = $res->{words};
  ok($w3w->valid_words_format($three_words_string), 'words_to_position - got 3 words');

  ## now Russian, питомец.шутить.намеренно
  my $res_ru = $w3w->position_to_words($lat . ',' . $lng, 'ru');
  $three_words_string_russian = $res_ru->{words};

  isnt(
    $three_words_string,
    $three_words_string_russian,
    'words_to_position - english vs russian'
  );

}


##
## WORDS_TO_POSITION
##
{
  my $res = $w3w->words_to_position($three_words_string);

  is($res->{language}, 'en', 'position_to_words - language');
  is_deeply(
    [ $res->{geometry}->{lat}, $res->{geometry}->{lng} ],
    [ $lat, $lng ],
    'position_to_words - position'
  );
  is(
    $res->{words},
    $three_words_string,
    'position_to_words - words'
  );


}



##
## GET_LANGUAGES
##
{
  my $res = $w3w->get_languages();

  ok( scalar(@{$res->{languages}}) > 1, 'get_languages - at least one');

  my $rh_lang = first { $_->{'code'} eq 'ru'} @{$res->{languages}};
  like($rh_lang->{name}, qr/^Russian/, 'get_languages - name');
  like($rh_lang->{native_name}, qr/^Русский/, 'get_languages - name encoded in utf8');
}



## These methods don't access the HTTP API
##
{
  is( $w3w->valid_words_format('abc.def.ghi'),     1, 'valid_words_format - valid' );
  is( $w3w->valid_words_format('abcdef.ghi'),      0, 'valid_words_format - only two' );
  is( $w3w->valid_words_format('abc.def.ghi.jkl'), 0, 'valid_words_format - too many' );
  is( $w3w->valid_words_format('Abc.def.ghi'),     0, 'valid_words_format - not all lowercase' );
  is( $w3w->valid_words_format(''),                0, 'valid_words_format - empty' );
  is( $w3w->valid_words_format(),                  0, 'valid_words_format - undef' );

  is( $w3w->valid_words_format('meyal.şifalı.döşeme'),   1, 'valid_words_format - valid Turkish utf8' );
  is( $w3w->valid_words_format('диета.новшество.компаньон'),   1, 'valid_words_format - valid Russian utf8' );
  is( $w3w->valid_words_format('Mосква.def.ghi'),  0, 'valid_words_format - not all lowercase utf8' );
}


