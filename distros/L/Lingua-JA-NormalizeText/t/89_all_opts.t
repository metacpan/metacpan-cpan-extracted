use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText;
use Test::More;
use Test::Warn;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my @all_opts = (qw/lc uc/, @Lingua::JA::NormalizeText::EXPORT_OK);
my $normalizer = Lingua::JA::NormalizeText->new(@all_opts);

my $text = "<script>パ\x{0000}ン\x{0000}ツ</script>.?*";
warning_is { $normalizer->normalize($text); } '';
warning_is { $normalizer->normalize; } '';
warning_is { $normalizer->normalize(''); } '';

is($text, "<script>パ\x{0000}ン\x{0000}ツ</script>.?*", 'non-destructive');

done_testing;
