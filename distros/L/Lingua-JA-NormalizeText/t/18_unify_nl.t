use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/unify_nl/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $normalizer = Lingua::JA::NormalizeText->new(qw/unify_nl/);

my $CR   = "\x{000D}";
my $LF   = "\x{000A}";
my $CRLF = "\x{000D}\x{000A}";

my $text = "あ${CR}い${LF}う${CRLF}え${LF}${CR}お${CR}${CR}か${LF}${LF}";
is(unify_nl($text), "あ\nい\nう\nえ\n\nお\n\nか\n\n");
is($normalizer->normalize($text), "あ\nい\nう\nえ\n\nお\n\nか\n\n");

my %uniq_counter;

for my $char ( split( //, unify_nl($text) ) )
{
    $uniq_counter{$char} = '';
}

# hira    : 6
# new line: 1
is(scalar keys %uniq_counter, 7);

done_testing;
