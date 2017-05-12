use warnings;
use strict;
use Lingua::KO::Munja qw/roman2hangul hangul2roman/;
use Test::More;
use utf8;
binmode STDOUT, ":utf8";
binmode Test::More->builder->output, ":utf8";
my %inputs = (
    munja => '문자',
    pyeonji => '편지',
    alpabes => '알파벳',
    sosiji => '소시지',
);

for my $input (keys %inputs) {
    my $h = roman2hangul ($input);
    ok ($h eq $inputs{$input}, "$h = $inputs{$input}");
}
my %r = reverse %inputs;
for my $input (keys %r) {
    my $r = hangul2roman ($input);
    ok ($r eq $r{$input}, "$r = $r{$input}");
}

my $my = '마츠다 유사쿠';
ok (roman2hangul (hangul2roman ($my)) eq $my, "$my round trip");
done_testing ();
