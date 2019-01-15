use 5.18.0;

use FindBin qw($Bin);
use Inline::Perl6 'OO';
use Test::More skip_all => 'Lexical module loading in rakudo broke this';

ok(my $p6 = Inline::Perl6->new);

$p6->run("use lib '$Bin/lib'");
$p6->use('Perl6Test');
ok(my $tester = $p6->invoke('Perl6Test', 'new'));
is($tester->get_one, 1);
undef $tester;

done_testing;
