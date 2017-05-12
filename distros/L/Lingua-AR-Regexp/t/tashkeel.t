use Test::More;
use utf8;

BEGIN {
    use_ok 'Lingua::AR::Regexp';
}
my %testcases = (
    'مكرونة' => 'مكرونة',
    'مَكَرُونَة' => 'مكرونة',
    'äüöéñà' => 'äüöéñà',
    'auoena' => 'auoena',
);

use Unicode::Normalize;
while (my ($before, $after) = each %testcases) {
    is $before =~ s/\p{Lingua::AR::Regexp::IsTashkeel}//gr, $after;
}
done_testing;
