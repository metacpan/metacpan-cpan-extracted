#!/usr/local/bin/perl -w

use lib qw(blib ../blib ../../blib lib);
use HTTPD::Realm;


sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

my ($realms,$def,$db);

print "1..22\n";
test 1,$realms = new HTTPD::Realm(-config=>'./t/realms.conf');
test 2,$def = $realms->realm(-realm=>'main');
test 3,$def->name eq 'main';
test 4,$def->userdb eq './passwd';
test 5,$def->groupdb eq './group';
test 6,$def->usertype eq 'text';
test 7,$def->grouptype eq 'text';
test 8,$def->server eq 'apache';
test 9,$def->crypt eq 'crypt';
test 10,$db = $def->connect;

test 11,$def = $realms->realm('wizards');
test 12,$data = $def->SQLdata;
test 13,$data->{database} eq 'www';
test 14,$data->{host} eq 'localhost';
test 15,$data->{usertable} eq 'users';
test 16,$data->{grouptable} eq 'groups';
test 17,$data->{userfield} eq 'uid';
test 18,$data->{groupfield} eq 'group';
test 19,$data->{passwdfield} eq 'password';
test 20,$data->{userfield_len} == 20;
test 21,$data->{groupfield_len} == 30;
test 22,$data->{passwdfield_len} == 13;
