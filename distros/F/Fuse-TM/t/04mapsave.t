# az Mon Nov 10 14:39:13 2008
# test for writing functionality
# $Id: 04mapsave.t,v 1.2 2009-12-07 05:12:25 az Exp $
use strict;
use Test::More qw(no_plan);
use File::Temp qw(tempdir tempfile);
use Data::Dumper;
use File::Slurp;

my ($f,$map)=tempfile("/tmp/tmfs.XXXXXX",SUFFIX=>".atm");
my ($g,$outmap)=tempfile("/tmp/tmfs.XXXXXX",SUFFIX=>".atm");
my $td=tempdir("/tmp/tmfs.XXXXXX");
write_file($map,"\n");		# atm parser unhappy with zero-length map

# access map 
system("./bin/tmfs","-d",0,"-b","-W","-o","file:".$outmap,$map,$td);
ok(!($? & 0xffff),"rw-mounting on $td works");
sleep(1);

chdir($td);

map { ok(mkdir("topics/$_"),"making topic $_"); } (qw(a b c d e f));

ok(mkdir("assocs/ass"),"making assoc ass");
ok(mkdir("assocs/ass/1"),"making assoc ass 1");
map { ok(mkdir("assocs/ass/1/$_"),"making assoc ass 1 role $_"); } (qw(rolea roleb));

# names 
ok(write_file("topics/a/name/1","first name"),"adding basename 1");
ok(write_file("topics/a/name/2\@ascope","second name scoped"),
   "adding basename 2");
ok(write_file("topics/a/name/3:atype","third name typed"),
   "adding basename 3");

# ocs
ok(write_file("topics/b/oc/1","http://first"),"adding oc 1");
ok(write_file("topics/b/oc/2\@ascope","second oc scoped"),
   "adding oc 2");
ok(write_file("topics/b/oc/3:atype","third oc typed"),
   "adding oc 3");
ok(write_file("topics/b/oc/4:atype\@ascope","fourth oc typed and scoped"),
   "adding oc 4");

# sins
ok(write_file("topics/a/~","http://wikipedia.org/"),"creating subject indicator");
ok(write_file("topics/b/~","http://no.damn.org/\nurn:x-whatever:nope"),"creating double subject indicator");

# slocs, int, ext, assoc
ok(symlink("http://never.ever/","topics/c/="),"creating external subject locator");
ok(symlink("../d/","topics/e/="),"creating internal subject locator");
ok(symlink("../../assocs/ass/1","topics/f/="),"creating internal subject locator for assoc");

# class-instance
ok(symlink("../../b","topics/a/isa/b"),"creating isa b");
ok(symlink("../../d","topics/c/instance/d"),"creating instance d");

# player
ok(symlink("../../../../topics/a","assocs/ass/1/rolea/a"),"creating player a");
ok(symlink("../../../../topics/b","assocs/ass/1/rolea/b"),"creating player b");
ok(symlink("../../../../topics/c","assocs/ass/1/roleb/c"),"creating player c");

# cleanup
chdir("/");
system("fusermount","-u",$td);
ok(!(0xffff & $?),"unmounting works");
sleep(1);
rmdir($td);
unlink($map);
ok(!-z $outmap,"wrote map $outmap");

# now test the resulting map for correctness
my $out=read_file($outmap);
my %seen;
for my $p (split(/\n\n/,$out))
{
    my @lines=split(/\n/,$p);
    if ($lines[0]=~/^a\s*\(b\)\s*$/)
    {
	ok(1,"topic a has survived with intact isa");
	$seen{a}=1;
	ok(grep(/^bn:\sfirst name\s*$/,@lines),"plain basename");
	ok(grep(/^bn\s*\@\s*ascope\s*:\s+second name scoped\s*$/,@lines),"scoped basename");
	ok(grep(/^bn\s*\(\s*atype\s*\)\s*:\s+third name typed\s*$/,@lines),"typed basename");
	ok(grep(m!^sin:\s+http://wikipedia.org/\s*$!,@lines),"single sin");
    }
    elsif ($lines[0]=~/^b\s*$/)
    {
    	ok(1,"topic b has survived");
	$seen{b}=1;
	ok(grep(m!^(in|oc):\s*http://first$!,@lines),"plain oc");
	ok(grep(/^(in|oc)\s*\@\s*ascope: second oc scoped$/,@lines),"scoped oc");
	ok(grep(/^(in|oc)\s*\@\s*ascope\s*\(\s*atype\s*\)\s*: fourth oc typed and scoped$/,@lines),
	   "scoped and typed oc");
	ok(grep(/^sin: http/,@lines) && grep(/^sin: urn/,@lines),
	   "multiple sins");
    }
    elsif ($lines[0]=~m!^c\s*reifies\s*http://never.ever/$!)
    {
	$seen{c}=1;
	ok(1,"topic c has survived with intact reification");
    }
    elsif ($lines[0]=~m!^d\s*\(\s*c\s*\)\s*is-reified-by\s*e\s*$!)
    {
	$seen{d}=1;
	ok(1,"topic d has survived with intact isa and reification");
    }
    elsif ($lines[0]=~/^\(\s*ass\s*\)\s*is-reified-by\s*f\s*$/)
    {
	$seen{assoc}=1;
	ok(1,"assoc ass has survived with intact reification");
	ok(grep(/^rolea\s*:\s*(a\s*b|b\s*a)\s*$/,@lines),"rolea ok");
	ok(grep(/^roleb\s*:\s*c\s*$/,@lines),"roleb ok");
    }
    elsif ($lines[0]=~/^([a-zA-Z0-9]+)\s*$/)
    {
	$seen{$1}=1;
	ok(1,"topic $1");
    }
}
ok(keys %seen==12,"all topics and assocs have survived");
unlink($outmap);
exit 0;

