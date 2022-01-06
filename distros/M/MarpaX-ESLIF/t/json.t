use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::More::UTF8;
use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;
#
# Init log
#
our $defaultLog4perlConf = '
log4perl.rootLogger              = INFO, Screen
log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr  = 0
log4perl.appender.Screen.layout  = PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %6P %m{chomp}%n
';
Log::Log4perl::init(\$defaultLog4perlConf);
Log::Any::Adapter->set('Log4perl');

BEGIN { require_ok('MarpaX::ESLIF') };

my @inputs = (
    "{\"test\":\"1.25\"}",
    "{\"test\":\"1.25e4\"}",
    "{\"test\":1.25}",
    "{\"test\":1.25e4}",
    "[]",
    "[
       { 
          \"precision\": \"zip\",
          \"Latitude\":  37.7668,
          \"Longitude\": -122.3959,
          \"Address\":   \"\",
          \"City\":      \"SAN FRANCISCO\",
          \"State\":     \"CA\",
          \"Zip\":       \"94107\",
          \"Country\":   \"US\"
       },
       {
          \"precision\": \"zip\",
          \"Latitude\":  37.371991,
          \"Longitude\": -122.026020,
          \"Address\":   \"\",
          \"City\":      \"SUNNYVALE\",
          \"State\":     \"CA\",
          \"Zip\":       \"94085\",
          \"Country\":   \"US\"
       }
     ]",
    "{
       \"Image\": {
         \"Width\":  800,
         \"Height\": 600,
         \"Title\":  \"View from 15th Floor\",
         \"Thumbnail\": {
             \"Url\":    \"http://www.example.com/image/481989943\",
             \"Height\": 125,
             \"Width\":  \"100\"
         },
         \"IDs\": [116, 943, 234, 38793]
       }
     }",
    "{
       \"source\" : \"<a href=\\\"http://janetter.net/\\\" rel=\\\"nofollow\\\">Janetter</a>\",
       \"entities\" : {
           \"user_mentions\" : [ {
                   \"name\" : \"James Governor\",
                   \"screen_name\" : \"moankchips\",
                   \"indices\" : [ 0, 10 ],
                   \"id_str\" : \"61233\",
                   \"id\" : 61233
               } ],
           \"media\" : [ ],
           \"hashtags\" : [ ],
          \"urls\" : [ ]
       },
       \"in_reply_to_status_id_str\" : \"281400879465238529\",
       \"geo\" : {
       },
       \"id_str\" : \"281405942321532929\",
       \"in_reply_to_user_id\" : 61233,
       \"text\" : \"\@monkchips Ouch. Some regrets are harsher than others.\",
       \"id\" : 281405942321532929,
       \"in_reply_to_status_id\" : 281400879465238529,
       \"created_at\" : \"Wed Dec 19 14:29:39 +0000 2012\",
       \"in_reply_to_screen_name\" : \"monkchips\",
       \"in_reply_to_user_id_str\" : \"61233\",
       \"user\" : {
           \"name\" : \"Sarah Bourne\",
           \"screen_name\" : \"sarahebourne\",
           \"protected\" : false,
           \"id_str\" : \"16010789\",
           \"profile_image_url_https\" : \"https://si0.twimg.com/profile_images/638441870/Snapshot-of-sb_normal.jpg\",
           \"id\" : 16010789,
          \"verified\" : false
       }
     }",
    "{\"+Inf\":+Inf, \"-Inf\":-Inf, \"+NaN\":+NaN, \"-NaN\":-NaN}",
    "{\"\\uDFAA\":0}",
    "[\"\\uDADA\"]",
    "[\"\\uD888\\u1234\"]",
    "[\"\\uD800\\n\"]",
    "[\"\\uDd1ea\"]",
    "[\"\\uD800\\uD800\\n\"]",
    "[\"\\ud800\"]",
    "[\"\\ud800abc\"]",
    "[\"\\uDd1e\\uD834\"]",
    "[\"\\uDFAA\"]",
    "[\"\\u0060\\u012a\\u12AB\"]",
    "[\"\\uD801\\udc37\"]",
    "[\"\\ud83d\\ude39\\ud83d\\udc8d\"]",
    "[\"\\\"\\\\\\/\\b\\f\\n\\r\\t\"]",
    "[\"\\\\u0000\"]",
    "[\"\\\"\"]",
    "[\"a/*b*/c/*d//e\"]",
    "[\"\\\\a\"]",
    "[\"\\\\n\"]",
    "[\"\\u0012\"]",
    "[\"\\uFFFF\"]",
    "[\"\\uDBFF\\uDFFF\"]",
    "[\"new\\u00A0line\"]",
    "[\"\\u0000\"]",
    "[\"\\u002c\"]",
    "[\"\\uD834\\uDd1e\"]",
    "[\"\\u0061\\u30af\\u30EA\\u30b9\"]",
    "[\"\\uA66D\"]",
    "[\"\\u005C\"]",
    "[\"\\uDBFF\\uDFFE\"]",
    "[\"\\uD83F\\uDFFE\"]",
    "[\"\\u200B\"]",
    "[\"\\u2064\"]",
    " [] ",
    );
{
  use POSIX qw(setlocale);
  setlocale(&POSIX::LC_ALL, "fr_FR.utf-8");
  push(@inputs, "{\"invalid\": 123.45e-17}");
}

my $eslif = MarpaX::ESLIF->new($log);
isa_ok($eslif, 'MarpaX::ESLIF');

$log->info('Creating JSON native grammar');
my $eslifJson = MarpaX::ESLIF::JSON->new($eslif, 0);

foreach (0..$#inputs) {
    if (! doparse($inputs[$_], 0)) {
        BAIL_OUT("Failure when parsing:\n$inputs[$_]\n");
    }
}

done_testing();

sub doparse {
    my ($inputs, $recursionLevel) = @_;
    my $rc;

    $log->infof('Input: %s', $inputs);
    my $value = $eslifJson->decode($inputs);
    if (! defined($value)) {
        BAIL_OUT("Failure with decode:\n$inputs\n");
    }
    $log->infof('Decoded: %s', $value);
    #
    # Re-encode
    #
    my $string = $eslifJson->encode($value);
    $log->infof('Re-encoded: %s', $string);

    $rc = 1;
    goto done;

  err:
    $rc = 0;

  done:
    return $rc;
}
