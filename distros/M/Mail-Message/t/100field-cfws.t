#!/usr/bin/env perl
#
# Test stripping CFWS  [comments and folding white spaces] as
# specified by rfc2822.
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Field::Fast;

use Test::More tests => 54;
use Mail::Address;

my @tests =
( 'aap noot mies'                              => 'aap noot mies'
, '  aap  noot mies '                          => 'aap noot mies'
, "aap\n noot\n"                               => 'aap noot'
, "aap (comment) noot"                         => 'aap noot'
, "aap () noot"                                => 'aap noot'
, "(a) aap (comment) noot (c)"                 => 'aap noot'
, "aap (com (nested) ment) noot"               => 'aap noot'
, "aap ((nested) comment) noot"                => 'aap noot'
, "aap (comment (nested)) noot"                => 'aap noot'
, "aap (comment(nested)) noot"                 => 'aap noot'
, "aap ((nested)comment(nested)) noot"         => 'aap noot'
, "((nested)comment(nested)) noot"             => 'noot'
, "aap ((nes(ted))comment(nested)) noot"       => 'aap noot'
, "(nes(ted)comment(nested)) noot (aap)"       => 'noot'
, "aap ((nes\n\nted)co\nmment(nested)\n) noot" => 'aap noot'
, '"aap" noot'                                 => '"aap" noot'
, '"aap" (noot) mies'                          => '"aap" mies'
, '"aap" (noot) mies '                         => '"aap" mies'
, '"aap" noot (mies) '                         => '"aap" noot'
, 'aap "noot" (mies) '                         => 'aap "noot"'
, 'aap (noot) "mies"'                          => 'aap "mies"'
, 'aap (noot) "mies" '                         => 'aap "mies"'
, 'aap (noot) "mies" (noot(nest)) aap'         => 'aap "mies" aap'
, 'aap \( noot'                                => 'aap \( noot'
, 'aap "(" noot'                               => 'aap "(" noot'
, 'aap "(noot)" mies'                          => 'aap "(noot)" mies'
, 'aap \"(noot) mies'                          => 'aap \" mies'
);

my @take = @tests;
while(@take)
{   my ($from, $to) = (shift @take, shift @take);
    is(Mail::Message::Field->stripCFWS($from), $to );
}

@take = @tests;
while(@take)
{   my ($from, $to) = (shift @take, shift @take);
    my $field = Mail::Message::Field::Fast->new('Something' => $from);
    is($field->stripCFWS, $to);
}
