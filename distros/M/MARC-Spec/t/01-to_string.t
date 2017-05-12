use Test::More;
use MARC::Spec;

my $ms = MARC::Spec->parse('246{$a}$b{001|002}{003}');

ok $ms->to_string() eq '246[0-#]{246[0-#]?246[0-#]$a[0-#]}$b[0-#]{246[0-#]$b[0-#]?001[0-#]|246[0-#]$b[0-#]?002[0-#]}{246[0-#]$b[0-#]?003[0-#]}', 'to_string';

done_testing();