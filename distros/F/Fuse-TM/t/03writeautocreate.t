# az Mon Nov 10 14:39:13 2008
# test for writing functionality with topic autocreate on
# $Id: 03writeautocreate.t,v 1.2 2009-12-07 05:12:25 az Exp $
use strict;
use Test::More qw(no_plan);
use File::Temp qw(tempdir tempfile);
use Test::Deep;
use TM::PSI;
use Data::Dumper;
use File::Slurp;
use File::Find;

my ($f,$map)=tempfile("/tmp/tmfs.XXXXXX",SUFFIX=>".atm");
my ($g,$outmap)=tempfile("/tmp/tmfs.XXXXXX",SUFFIX=>".atm");
my $td=tempdir("/tmp/tmfs.XXXXXX");
write_file($map,"\n");		# atm parser unhappy with zero-length map

# access map 
system("./bin/tmfs","-d",0,"-b","-W","-o","file:".$outmap,$map,$td);
ok(!($? & 0xffff),"rw-mounting on $td works");
sleep(1);

chdir($td);
# oc, names can contain nonex new topics
# assoc type and roles can contain nonex new topics
ok(mkdir("topics/a"),"creating topic a");
ok(-d "topics/a","topic a exists");
ok(write_file("topics/a/oc/34\@newscope","blafasel"),"adding occ with new scope");
ok(-f "topics/a/oc/34\@newscope" && -d "topics/newscope",
   "autocreated items exist");

ok(write_file("topics/newscope/oc/1:sometype\@otherscope","bla"),
   "adding occ with new scope and new type");
ok(-f "topics/newscope/oc/1:sometype\@otherscope" && -d "topics/otherscope"
   && -d "topics/sometype",
   "autocreated items exist");

ok(mkdir("assocs/atype"),"creating assoc of type atype");
ok(-d "assocs/atype" && -d "topics/atype","autocreated items exist");
ok(mkdir("assocs/atype/1") && mkdir("assocs/atype/1/newrole"),
   "creating assoc instance and newrole");
ok(-d "assocs/atype/1/newrole" && -d "topics/newrole", 
   "autocreated items exist");

# renaming ocs/names with new scopes and types
ok(rename("topics/a/oc/34\@newscope","topics/a/oc/44\@xscope"),
   "renaming oc with new scope");
ok(-f "topics/a/oc/44\@xscope" && -d "topics/xscope",
   "autocreated items exist");

ok(rename("topics/newscope/oc/1:sometype\@otherscope",
	  "topics/newscope/oc/99:newtype"),"renaming oc with new type");
ok(-f "topics/newscope/oc/99:newtype" && -d "topics/newtype",
   "autocreated items exist");





# cleanup
chdir("/");
system("fusermount","-u",$td);
ok(!(0xffff & $?),"unmounting works");
sleep(1);
rmdir($td);
unlink($map);
unlink($outmap);

exit 0;

