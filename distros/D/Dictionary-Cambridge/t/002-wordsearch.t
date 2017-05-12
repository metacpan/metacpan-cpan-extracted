#!/usr/bin/perl


use strict;
use warnings;
use Test::More tests=>6;
use lib "./lib";

my $meaningful_word = "test";
my $not_a_word      = "sdfkljsdflsdkj";
use_ok( 'Dictionary::Cambridge' );

#to make the tests pass user must regsiter for their own access key from the
#following http://dictionary-api.cambridge.org/index.php/request-api-key
#

SKIP: {
        skip "no access key provided skipping all tests", 5 if not exists $ENV{ACCESS_KEY};
        my $word = Dictionary::Cambridge->new(
            access_key => $ENV{ACCESS_KEY},
            dictionary => 'british',
            format     => 'xml'
        );

        isa_ok($word, 'Dictionary::Cambridge' );
        can_ok($word, 'get_entry');
        my $meaning = $word->get_entry($meaningful_word);

         is(ref ($meaning) ,'HASH', "Content is a Hashref");
         $meaning = $word->get_entry($not_a_word);
         is($meaning, "Entry \'$not_a_word\' not found.", "Correct reply from API");
         $meaning = $word->get_entry();
         is($meaning, "Dictionary id or word not found", "Correct reply when undef params");
}
