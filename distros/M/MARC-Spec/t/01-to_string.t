use Test::More;
use MARC::Spec;

my $ms = MARC::Spec::parse('246$b{$a|002}{003[0]/0=\A}');
ok $ms->to_string() eq '246[0-#]$b[0-#]{246[0-#]$b[0-#]?246[0-#]$a[0-#]|246[0-#]$b[0-#]?002[0-#]}{003[0]/0=\A}', 'to_string';

done_testing();