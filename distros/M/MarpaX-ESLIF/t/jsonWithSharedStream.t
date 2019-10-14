#
# This file is adapted from MarpaX::ESLIF::ECMA404
#
package MyRecognizerInterface;
use strict;
use diagnostics;

sub new                    { my ($pkg, $string) = @_; bless { string => $string }, $pkg }
sub read                   { 1 }
sub isEof                  { 1 }
sub isCharacterStream      { 1 }
sub encoding               { }
sub data                   { $_[0]->{string} }
sub isWithDisableThreshold { 0 }
sub isWithExhaustion       { 0 }
sub isWithNewline          { 1 }
sub isWithTrack            { 1 }

package MyValueInterface;
use strict;
use diagnostics;

sub new                { my ($pkg) = @_; bless { result => undef }, $pkg }
sub isWithHighRankOnly { 1 }
sub isWithOrderByRank  { 1 }
sub isWithAmbiguous    { 0 }
sub isWithNull         { 0 }
sub maxParses          { 0 }
sub getResult          { $_[0]->{result} }
sub setResult          { $_[0]->{result} = $_[1] }

package main;
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

my $base_dsl = q{
:default ::= action => ::shift
:start       ::= XXXXXX # Replaced on-the-fly by json or object
:discard ::= perl_comment event => perl_comment$
perl_comment ::= /(?:(?:#)(?:[^\\n]*)(?:\\n|\\z))/u

json         ::= object
               | array
object       ::= LCURLY members RCURLY
               | OBJECT_FROM_INNER_GRAMMAR
members      ::= pair*                 action => do_array separator => ','
pair         ::= string ':' value      action => do_array
value        ::= string
               | object
               | number
               | array
               | 'true'                action => do_true
               | 'false'               action => do_true
               | 'null'                action => ::undef
array        ::= '[' ']'               action => do_empty_array
               | '[' elements ']'
elements     ::= value+                action => do_array separator => ','
number         ~ int
               | int frac
               | int exp
               | int frac exp
int            ~ digits
               | '-' digits
digits         ~ [\d]+
frac           ~ '.' digits
exp            ~ e digits
e              ~ 'e'
               | 'e+'
               | 'e-'
               | 'E'
               | 'E+'
               | 'E-'
string       ::= lstring
:lexeme ::= lstring pause => after event => lstring$
lstring        ~ quote in_string quote
quote          ~ '"'
in_string      ~ in_string_char*
in_string_char  ~ [^"] | '\\\\' '"'
:discard       ::= whitespace
whitespace     ~ [\s]+
:lexeme ::= LCURLY pause => before event => ^LCURLY
LCURLY         ~ '{'
:lexeme ::= RCURLY pause => before event => ^RCURLY
RCURLY         ~ '}'
OBJECT_FROM_INNER_GRAMMAR ~ [^\s\S]
};

my @inputs = (
    "{\"test\":\"1\"}",
    "{\"test\":[1,2,3]}",
    "{\"test\":true}",
    "{\"test\":false}",
    "{\"test\":null}",
    "{\"test\":null, \"test2\":\"hello world\"}",
    "{\"test\":\"1.25\"}",
    "{\"test\":\"1.25e4\"}",
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
     } # Last discard is a perl comment"
    );

my $eslif = MarpaX::ESLIF->new($log);
isa_ok($eslif, 'MarpaX::ESLIF');

my @GRAMMARARRAY;

$log->info('Creating JSON grammar');
{
    my $dsl = $base_dsl;
    $dsl =~ s/XXXXXX/json/smg;
    push(@GRAMMARARRAY, MarpaX::ESLIF::Grammar->new($eslif, $dsl));
}

$log->info('Creating object grammar');
{
    my $dsl = $base_dsl;
    $dsl =~ s/XXXXXX/object/smg;
    push(@GRAMMARARRAY, MarpaX::ESLIF::Grammar->new($eslif, $dsl));
}

foreach (0..$#inputs) {
    my $recognizerInterface = MyRecognizerInterface->new($inputs[$_]);
    my $marpaESLIFRecognizerJson = MarpaX::ESLIF::Recognizer->new($GRAMMARARRAY[0], $recognizerInterface);
    if (! doparse($marpaESLIFRecognizerJson, $inputs[$_], 0)) {
        BAIL_OUT("Failure when parsing:\n$inputs[$_]\n");
    }
}

my $newFromOrshared = 0;
sub doparse {
    my ($marpaESLIFRecognizer, $inputs, $recursionLevel) = @_;
    my $rc;

    if (defined($inputs)) {
        $log->infof('[%d] Scanning JSON', $recursionLevel);
        $log->info ('-------------');
        $log->infof('%s', $inputs);
        $log->info ('-------------');
    } else {
        $log->infof("[%d] Scanning JSON's object", $recursionLevel);
    }
    my $ok = $marpaESLIFRecognizer->scan(1); # Initial events
    while ($ok && $marpaESLIFRecognizer->isCanContinue()) {
        my $events = $marpaESLIFRecognizer->events();
        for (my $k = 0; $k < scalar(@{$events}); $k++) {
            my $event = $events->[$k];
            next unless defined($event);
            $log->debugf('Event %s', $event->{event});
            if ($event->{event} eq 'lstring$') {
                my $pauses = $marpaESLIFRecognizer->lexemeLastPause('lstring');
                my ($line, $column) = $marpaESLIFRecognizer->location();
                $log->infof("Got lstring: %s; length=%ld, current position is {line, column} = {%ld, %ld}", $pauses, length($pauses), $line, $column);
            }
            elsif ($event->{event} eq '^LCURLY') {
                my $marpaESLIFRecognizerObject;
                if ((++$newFromOrshared) %2 == 0) {
                    $marpaESLIFRecognizerObject = $marpaESLIFRecognizer->newFrom($GRAMMARARRAY[1]);
                } else {
                    $marpaESLIFRecognizerObject = MarpaX::ESLIF::Recognizer->new($GRAMMARARRAY[1], MyRecognizerInterface->new(undef));
                    $marpaESLIFRecognizerObject->share($marpaESLIFRecognizer);
                }
                # Set exhausted flag since this grammar is very likely to exit when data remains
                $marpaESLIFRecognizerObject->set_exhausted_flag(1);
                # Force read of the LCURLY lexeme
                $marpaESLIFRecognizerObject->lexemeRead('LCURLY', '{', 1); # In UTF-8 '{' is one byte
                my $value = doparse($marpaESLIFRecognizerObject, undef, $recursionLevel + 1);
                # Inject object's value
                $marpaESLIFRecognizer->lexemeRead('OBJECT_FROM_INNER_GRAMMAR', $value, 0); # Stream moved synchroenously
            }
            elsif ($event->{event} eq '^RCURLY') {
                # Force read of the RCURLY lexeme
                $marpaESLIFRecognizer->lexemeRead('RCURLY', '}', 1); # In UTF-8 '}' is one byte
                $rc = 1;
                goto done;
            } else {
                $log->errorf('Unmanaged event %s', $event);
                goto err;
            }
        }
        #
        # Check if there is something else to read
        #
        my $eof = $marpaESLIFRecognizer->isEof;
        my $bytes = $marpaESLIFRecognizer->input;
        if ((! defined($bytes)) && $eof) {
            $rc = 1;
            goto done;
        }
        #
        # Resume
        #
        $ok = $marpaESLIFRecognizer->resume();
    }

    $rc = 1;
    goto done;

  err:
    $rc = 0;

  done:
    if ($rc) {
        #
        # Get last discarded data
        #
        my $discardLast = $marpaESLIFRecognizer->discardLast;
        $log->infof("[%d] Last discarded data: %s", $recursionLevel, $discardLast);
    }
    return $rc;
}

done_testing();


