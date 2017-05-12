#!/usr/local/bin/perl -w

use lib qw(blib/lib ../blib/lib ../../blib/lib);
use HTTPD::RealmManager;

BEGIN {
    unlink './passwd','./group';
}

sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

my ($realms,$def,$db);

print "1..16\n";
test 1,$db = HTTPD::RealmManager->open(-config=>'./t/realms.conf',
	                               -realm=>'main',
				       -writable=>1);
test 2,$db->set_passwd(-user=>'lincoln',
		       -passwd=>'xyzzy',
		       -fields=>{ name=>'Lincoln D. Stein',
				  age=>37,
				  paid=>'Y' });
test 3,$db->passwd('lincoln');
test 4,$db->match(-user=>'lincoln',-passwd=>'xyzzy');
test 5,$fields = $db->get_fields(-user=>'lincoln');
test 6,$fields->{age} == 37;
$db->close;

test 7,$db = HTTPD::RealmManager->open(-config=>'./t/realms.conf',
	                               -realm=>'main');
test 8,$db->match(-user=>'lincoln',-passwd=>'xyzzy');
test 9,$db->set_group(-user=>'lincoln',-group=>[qw/users administrators authors/]);
test 10,$db->set_passwd(-user=>'fred',
		       -passwd=>'xyzzy',
		       -fields=>{ name=>'Fred Smith',
				  age=>30,
				  paid=>'Y' });
test 11,$db->set_passwd(-user=>'anne',
		       -passwd=>'xyzzy',
		       -fields=>{ name=>'Anne Greenaway',
				  age=>41,
				  paid=>'N' });
test 12,$db->set_group(-user=>'fred',
		       -group=>[qw/users/]);
test 13,$db->set_group(-user=>'anne',
		       -group=>[qw/users authors/]);
test 14,$db->group(-user=>'anne',-group=>'authors');
test 15,join(' ',sort $db->group('lincoln')) eq 'administrators authors users';
test 16,join(' ',sort $db->members('authors')) eq 'anne lincoln';

