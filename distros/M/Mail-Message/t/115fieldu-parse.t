#!/usr/bin/env perl
#
# Test processing of general parsing of fields
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Field::Full;

use Test::More tests => 38;

my $mmff = 'Mail::Message::Field::Full';

#
# Test consuming phrases
#

my @tests =
 ( 'hi! this is me <tux>' => ['hi! this is me', '<tux>' ]
 , ' aap, noot <tux>'     => ['aap', ', noot <tux>' ]
 , '" aap, noot " <tux>'  => [' aap, noot ', ' <tux>' ]
 , '"aap", "noot"'        => ['aap', ', "noot"' ]
 , '"a\\"b\\"c" d'        => ['a"b"c', ' d' ]
 , '"\\"b\\"" d'          => ['"b"', ' d' ]
 , '"a\\)b\\(c" d'        => ['a\\)b\\(c', ' d' ]
 , '<tux>'                => [ undef, '<tux>' ]
 , ' <tux>'               => [ undef, '<tux>' ]
 , '" " <tux>'            => [ ' ', ' <tux>' ]
 );

while(@tests)
{   my ($from, $to) = (shift @tests, shift @tests);
    my ($exp_phrase, $exp_rest) = @$to;

    my ($phrase, $rest) = $mmff->consumePhrase($from);
    is($phrase, $exp_phrase,  $from);
    is($rest, $exp_rest,      $from);
}

#
# Test consuming comments
#

@tests =
 ( '(this is a comment) <tux>' => [ 'this is a comment', ' <tux>' ]
 , '(this)'                    => [ 'this', '' ]
 , 'this'                      => [ undef, 'this' ]
 , ' (a(b)c) <tux>'            => [ 'a(b)c', ' <tux>' ]
 , '((a)b(c)) <tux>'           => [ '(a)b(c)', ' <tux>' ]
 , '((a)b(c) <tux>'            => [ undef, '((a)b(c) <tux>' ]
 , '(a\(b) <tux>'              => [ 'a(b', ' <tux>' ]
 , '(a <tux>'                  => [ undef, '(a <tux>' ]
 , 'a) <tux>'                  => [ undef, 'a) <tux>' ]
 );

while(@tests)
{   my ($from, $to) = (shift @tests, shift @tests);
    my ($exp_comment, $exp_rest) = @$to;

    my ($comment, $rest) = $mmff->consumeComment($from);
    is($comment, $exp_comment,  $from);
    is($rest, $exp_rest,      $from);
}

#
