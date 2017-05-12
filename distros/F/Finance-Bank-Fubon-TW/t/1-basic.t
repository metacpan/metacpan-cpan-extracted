# $File: //member/autrijus/Finance-Bank-Fubon-TW/t/1-basic.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 5938 $ $DateTime: 2003/05/17 22:34:34 $

use Test;
BEGIN { plan tests => 2; $|++ }

use Finance::Bank::Fubon::TW;
ok(Finance::Bank::Fubon::TW->VERSION);

if (!@ARGV) {
    skip(1);
    warn << '.';

Full test skipped; run this test manually with an account id as the argument:
    perl t/1-basic.t 015226123456
.
    exit;
}

my $uid = shift;
my $pwd = shift;
if (!defined($pwd) or !length($pwd)) {
    print "Enter Fubon eBank password for '$uid', and press [Enter] twice: ";
    eval {
	require Term::ReadKey;
	Term::ReadKey::ReadMode('noecho');
	$pwd = Term::ReadKey::ReadLine(0);
	Term::ReadKey::ReadMode('restore');
	1;
    } or ($pwd = <STDIN>);

    chomp($pwd);

    if (!defined($pwd) or !length($pwd)) {
	skip(1);
	exit;
    }
}

my $ok;
foreach ( Finance::Bank::Fubon::TW->check_balance(
    username  => $uid,
    password  => $pwd,
)) {
    warn "[", $_->name, ': $', $_->balance, "]\n";
    warn join("\t", split(/,/, $_->statement));
    $ok++;
}

ok($ok);

