use strict;
use Test::More tests => 26;
use CGI;

use FormValidator::Simple;
FormValidator::Simple->import('Number::Phone::JP');

my $q = CGI->new;
my $line = 14;

for (1..$line) {
	my $num = <DATA>;
	chomp $num;
	$q->param( tel => $num );
	my $r = FormValidator::Simple->check( $q => [
						     tel => [qw/NUMBER_PHONE_JP/],
						     ] );
	ok(!$r->invalid('tel'));
}

while (<DATA>) {
	chomp;
	$q->param( tel => $_ );
	my $r = FormValidator::Simple->check( $q => [
						     tel => [qw/NUMBER_PHONE_JP/],
						     ] );
	ok($r->invalid('tel'));
}

__DATA__
001 12345678
009120 12345678
0120 000123
011 2001234
050 10001234
080 10012345
020 46012345
070 50112345
0990 500123
0570 000123
060 33001234
0255 731234
096 3471234
080 99912345
00299 12345678
009197 12345678
0800 9231234
0997 711234
050 99991234
020 49812345
070 68912345
0570 998123
060 49991234
06 43391234
0778 891234
0997 381234
