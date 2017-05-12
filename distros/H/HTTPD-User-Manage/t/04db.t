#!/usr/local/bin/perl -w

use lib ('./lib','./blib');
use HTTPD::RealmManager;

BEGIN {
    unlink <./db.passwd*>;
    unlink <./db.group*>;
}
END {
    unlink <./db.passwd*>;
    unlink <./db.group*>;
}

sub test {
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

unless (eval { require DB_File } ) {
  print "1..0 # Skipped: no DB_File module installed\n";
  exit 0;
}
print "1..14\n";

test 1,$db = HTTPD::RealmManager->open(-config=>'./t/realms.conf',
	                               -realm=>'test2',
				       -writable=>1);
test 2,$db->set_passwd(-user=>'lincoln',
		       -passwd=>'xyzzy',
		       -fields=>{ Name=>'Lincoln D. Stein'});
test 3,$db->passwd('lincoln');
test 4,$db->match(-user=>'lincoln',-passwd=>'xyzzy');
test 5,$fields = $db->get_fields(-user=>'lincoln');
test 6,$fields->{Name} eq 'Lincoln D. Stein';
test 7,$db->set_group(-user=>'lincoln',-group=>[qw/users administrators authors/]);
test 8,$db->set_passwd(-user=>'fred',
		       -passwd=>'xyzzy',
		       -fields=>{ Name=>'Fred Smith' });
test 9,$db->set_passwd(-user=>'anne',
		       -passwd=>'xyzzy',
		       -fields=>{ Name=>'Anne Greenaway' });
test 10,$db->set_group(-user=>'fred',
		       -group=>[qw/users/]);
test 11,$db->set_group(-user=>'anne',
		       -group=>[qw/users authors/]);
test 12,$db->group(-user=>'anne',-group=>'authors');
test 13,join(' ',sort $db->group('lincoln')) eq 'administrators authors users';
test 14,join(' ',sort $db->members('authors')) eq 'anne lincoln';

