#!/usr/bin/perl
# $File: //member/autrijus/Lingua-ZH-Toke/t/1-basic.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 9669 $ $DateTime: 2004/01/11 13:11:05 $

use strict;
use Test;

BEGIN { plan tests => 20 }

require Lingua::ZH::Toke;
ok($Lingua::ZH::Toke::VERSION) if $Lingua::ZH::Toke::VERSION or 1;

# Create Lingua::ZH::Toke::Sentence object (->Sentence also works)
my $token = Lingua::ZH::Toke->new( '那人卻在/燈火闌珊處/益發意興闌珊' );

my $tmp = $token;

# Easy tokenization via array deferencing
ok($tmp = $tmp->[0], '那人卻在',    'Tokenization - Fragment');
ok($tmp = $tmp->[2], '卻在',	    'Tokenization - Phrase');
ok($tmp = $tmp->[0], '卻',	    'Tokenization - Character');
ok($tmp = $tmp->[0], 'ㄑㄩㄝˋ',	    'Tokenization - Pronounciation');
ok($tmp = $tmp->[2], 'ㄝ',	    'Tokenization - Phonetic');

# Magic histogram via hash deferencing
ok($token->{"那人卻在"},    1,	    'Histogram - Fragment');
ok($token->{"意興闌珊"},    1,	    'Histogram - Phrase');
ok($token->{"發意興闌"},    undef,  'Histogram - No Phrase');
ok($token->{"珊"},	    2,	    'Histogram - Character');
ok($token->{"ㄧˋ"},	    2,	    'Histogram - Pronounciation');
ok($token->{"ㄨ"},	    3,	    'Histogram - Phonetic');

my @phrases = qw(那 人 卻在 燈火 闌珊 處 益發 意興闌珊);

# Iteration
while ($tmp = <$token>) {	# iterate each fragment
    while (<$tmp>) {		# iterate each phrase
	ok($_, shift(@phrases), 'Iteration');
    }
}

1;
