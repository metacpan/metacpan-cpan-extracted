# $Id: admin.t,v 1.3 2008-04-30 11:17:23 mike Exp $

use strict;
use warnings;
use Test::More tests => 33;

use Keystone::Resolver::Admin;
ok(1, "Admin module loaded");

# Test initialisation
my $admin = Keystone::Resolver::Admin->admin();
ok(defined $admin, "got admin object");

my $tag = $admin->hostname2tag("resolver.indexdata.com");
ok(defined $tag, "determined tag");
is($tag, "id", "tag is 'id'");

$ENV{KRrwuser} ||= "kr_admin";
$ENV{KRrwpw} ||= "kr_adm_3636";

my $site = $admin->site($tag);
ok(defined $site, "found site");
is($site->tag(), $tag, "site is consistent");
is($site->name(), "Index Data", "site is Index Data");

# Test searching for single items
my $user = $site->user1(id => 1);
ok(defined $user, "found user");
is($user->name(), "Mike Taylor", "user is Mike Taylor");
is($user->admin(), 2, "user can modify the database");

my $u2 = $site->user1(id => 2);
ok(defined $u2, "found second user");
is($u2->name(), "Some Guy", "user 2 is Some Guy");
is($u2->admin(), 0, "user 2 can not modify the database");

my $u3 = $site->user1(id => 3);
ok(!defined $u3, "user 3 belongs to a different vsite");

# Test searching for multiple hits
# See ../web/htdocs/admin/mc/search/submitted.mc
my($rs, $errmsg) = $site->search("Service", _sort => "name");
ok(defined $rs, "found some service records");
ok(!defined $errmsg, "no error message");
my $n = $rs->count();
is($n, 22, "number of records");

my $rec = $rs->fetch(1);
ok(defined $rec, "fetched record");
is($rec->tag(), "APP", "first tag is 'APP'");
my $id = $rec->id();
ok(defined $id, "got ID for subsequent re-find");

# Check sorting
my $last = "";
my $ok = 1;
for (my $i = 1; $i <= $n; $i++) {
    my $rec2 = $rs->fetch($i);
    if (lc($rec2->name()) lt lc($last)) {
	$ok = 0;
	last;
    }
    $last = $rec2->name();

}
ok($ok, "names are sorted");

# Check transitory writing to in-memory record
my $oldname = $rec->name();
is($oldname, "Acta Palaeontologica Polonica", "old name");
my $newname = "Wainwright's fruit emporium";
$rec->name($newname);
ok(1, "wrote new name");
is($rec->name(), $newname, "new name remains in memory");

# Check reversion on re-running search
($rs, $errmsg) = $site->search("Service", id => $id);
ok(defined $rs, "re-found service record");
is($rs->count(), 1, "single record");
$rec = $rs->fetch(1);
ok(1, "re-fetched record");
is($rec->name(), $oldname, "old name reverted from cache");

# Write through to database and check permanence
$n = $rec->update(name => $newname);
is($n, 1, "updated with one change");

# We should add an on_exit() at this point, to revert the change, but
# I can't immediately see how to do that in Perl.  This doesn't work:
#$SIG{EXIT} = sub { print "on_exit\n" };

($rs, $errmsg) = $site->search("Service", id => $id);
ok(defined $rs, "re-re-found service record");
$rec = $rs->fetch(1);
ok(1, "re-re-fetched record");
is($rec->name(), $newname, "new name saved in database");

# Finally, revert the database ready for next time
$n = $rec->update(name => $oldname);
is($n, 1, "reverted with one change");
