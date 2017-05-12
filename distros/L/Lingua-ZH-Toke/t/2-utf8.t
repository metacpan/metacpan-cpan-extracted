#!/usr/bin/perl
# $File: //member/autrijus/Lingua-ZH-Toke/t/2-utf8.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 9669 $ $DateTime: 2004/01/11 13:11:05 $

use strict;
use Test;

BEGIN {
    eval { require Encode::compat } if $] < 5.007;
    eval { require Encode } or do {
	plan tests => 0;
	exit;
    };
    plan tests => 20;
}

use utf8;
require Lingua::ZH::Toke;
ok($Lingua::ZH::Toke::VERSION) if $Lingua::ZH::Toke::VERSION or 1;
Lingua::ZH::Toke->import('utf8');

# Create Lingua::ZH::Toke::Sentence object (->Sentence also works)
my $token = Lingua::ZH::Toke->new( '那人卻在/燈火闌珊處/益發意興闌珊' );

my $tmp = $token;

# Easy tokenization via array deferencing
$tmp = $tmp->[0];
ok("$tmp", '那人卻在',    'Tokenization - Fragment');
$tmp = $tmp->[2];
ok("$tmp", '卻在',	    'Tokenization - Phrase');
$tmp = $tmp->[0];
ok("$tmp", '卻',	    'Tokenization - Character');
$tmp = $tmp->[0];
ok("$tmp", 'ㄑㄩㄝˋ',	    'Tokenization - Pronounciation');
$tmp = $tmp->[2];
ok("$tmp", 'ㄝ',	    'Tokenization - Phonetic');

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
	ok("$_", shift(@phrases), 'Iteration');
    }
}

1;
