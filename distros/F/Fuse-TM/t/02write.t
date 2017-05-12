# az Mon Nov 10 14:39:13 2008
# test for writing functionality
# $Id: 02write.t,v 1.3 2009-12-07 05:12:25 az Exp $
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
system("./bin/tmfs","-d",0,"-b","-w","-o","file:".$outmap,$map,$td);
ok(!($? & 0xffff),"rw-mounting on $td works");
sleep(1);

chdir($td);
# where can we create dirs
my @dirops=qw(a 0
	      xx 0
	      tid 0
	      isa 0
	      topics/a 1
	      topics/b 1
	      topics/c 1
	      topics/124 0
	      topics/a/huhu 0
	      topics/a/isa 0
	      topics/a/123 0
	      topics/atype 1
	      topics/btype 1
	      topics/ascope 1
	      topics/bscope 1
	      topics/cscope 1
	      topics/brole 1
	      topics/arole 1
	      topics/arole/involved/something 0
	      assocs/huhu 0
	      assocs/atype 1
	      assocs/atype/17 1
	      assocs/atype/huhu 0
	      assocs/atype/17/brole 1
	      assocs/atype/17/arole 1
	      assocs/atype/17/bumsti 0
	      );
while (@dirops)
{
    my $o=shift @dirops;
    my $v=shift @dirops;

    my $r=mkdir($o);
    if ($v)
    {
	ok($r,"succeeded making dir $o");
	ok(-d $o,"dir $o exists");
    }
    else
    {
	ok(!$r,"refused making dir $o as expected");
    }
}

my @fileops=qw(topics/a/xx 0
	       topics/a/isas 0
	       topics/a/name/1 1
	       topics/a/name/rumsti 0
	       topics/a/name/17@c 1
	       topics/a/oc/1 1
	       topics/a/oc/2@ascope 1
	       topics/a/oc/3@xscope 0
	       topics/a/oc/4:atype 1
	       topics/a/oc/17:nosuchtype 0
	       topics/b/oc/5:btype@cscope 1
	       topics/c/name/1 1
	       topics/c/oc/1 1
	       topics/c/involved/whatever 0
	       topics/c/oc/2@ascope 1
	       topics/c/oc/3:atype 1
	       topics/c/oc/19@bscope 1
      	       );

# where can we create files
while (@fileops)
{
    my $o=shift @fileops;
    my $v=shift @fileops;

    my $r=open(F,">$o");
    if ($v)
    {
	ok($r,"succeeded creating file $o");
	print F "hallihallo\n";	# dummy
	close(F);
	ok(-e $o,"file $o exists");
    }
    else
    {
	ok(!$r,"refused creating file $o as expected");
    }
}

# files we may truncate
my @truncops=qw(topics/a/isas 0
		topics/a/instances 0
		topics/a/oc/1 1
		topics/a/name/17@c 1
		topics/a/oc/2@ascope 1
		);
while (@truncops)
{
    my $o=shift @truncops;
    my $v=shift @truncops;

    my $curlen=((stat($o))[7]);
    my $newlen=int(rand(20));
    my $old_content=read_file($o);
    my $r=truncate($o,$newlen);
    if ($v)
    {
	ok($r && (stat($o))[7]==$newlen,
	   "truncating file $o (before $curlen) at $newlen");
	if ($newlen>$curlen)
	{
	    ok(scalar(read_file($o)) eq 
	       ($old_content."\0" x ($newlen-$curlen)),
	       "truncating returns correct expanded content");
	}
	else
	{
	    ok(scalar(read_file($o)) eq substr($old_content,0,$newlen),
	       "truncating returns correct content");
	}
    }
    else
    {
	ok(!$r,"refused truncating of $o as expected");
    }
}

# where can we create links
ok(symlink("../../b","topics/a/isa/b"),"isa-symlink ok");
ok(-l "topics/a/isa/b" && -l "topics/b/instance/a","isa-symlink opposite ok");
ok(!symlink("../../b","topics/a/isa/xxy"),"symlinks must have matching names");

ok(!symlink("/etc/passwd","topics/b/instance/xx"),"no symlink pointing outside");
ok(symlink("../c","topics/a/="),"internal reifier symlink ok");
ok(symlink("http://pikiwedia.org/","topics/b/="),"external reifier symlink ok");

ok(symlink("../../../../topics/a","assocs/atype/17/arole/a"),"a role player symlink ok");
ok(symlink("../../../../topics/b","assocs/atype/17/brole/b"),"b role player symlink ok");
ok(-l "topics/b/involved/1:player","b player involved");
ok(!symlink("/etc/passwd","assocs/atype/17/brole/c"),"no role symlinks pointing outside");

ok(!symlink("../../../assocs/atype/17","topics/atype/involved/4711:type"),"involved assoc symlinks static");

# renaming files, dirs
my @renops=qw(topics/c/name/1 topics/c/name/x 0
	      topics/c/name/1 topics/c/name/34@bscope 1
	      topics/c/oc/1 topics/c/name/12 0
	      topics/c/oc/1 topics/c/oc/99@btype 1
	      topics/c/oc/2@ascope topics/c/oc/2@bscope 1
	      topics/c/oc/2@bscope topics/c/oc/2:btype 1
	      topics/c topics/somethingnew 1
	      topics/bscope  topics/oddscopename 1
	      topics/oddscopename topics/12345 0
	      topics/atype/involved topics/atype/thingie 0
	      );
while (@renops)
{
    my $old=shift @renops;
    my $new=shift @renops;
    my $expected=shift @renops;

    my $r=rename($old,$new);
    if ($expected)
    {
	ok($r && -e $new && !-e $old,"renaming $old to $new succeeded");
    }
    else
    {
	ok(!$r && -e $old,"refused renaming $old to $new");
    }
}

# removing stuff: things that we know are odd
ok(rmdir("topics/ascope"),"removing dir ascope");
# for some reason the old files linger a while without a dir listing??
ok(-e "topics/a/oc/2","ascope removal renamed scoped occurrences"); 
ok(rmdir("topics/btype"),"removing dir btype");
ok(-e "topics/b/oc/5\@cscope","btype removal renamed typed occurrences");


ok(!rmdir("topics/brole"),"role topic in use in assoc can't be removed");
ok(unlink("assocs/atype/17/brole/b"),"assoc role player removed fine");
ok(rmdir("assocs/atype/17/brole"),"assoc role dir removed fine");
ok(!-l "topics/brole/involved/1:role","removed assoc role no longer involved");
ok(rmdir("topics/brole"),"idle role topic in assoc can be removed fine");

# can we remove files? dirs?
    my (@allfiles,@alldirs);
finddepth(sub 
     { 
	 my $n=$File::Find::name; 
	 if (!-l $_ && -d $_)
	 {
	     push @alldirs,$n;
	 }
	 else
	 {
	     push @allfiles,$n;
	 }
     },
	  qw(assocs topics));	# assocs first, for dir removal 

for my $f (@allfiles)
{
    next if (!-e $f);
    ok(unlink($f),"succeeded removing $f");
}

# what dirs can we remove?
for my $d (@alldirs)
{
    next if (!-d $d);
    my $r=rmdir($d);
    if ($d eq "topics" || $d eq "assocs")
    {
	ok(!$r,"refused removing dir $d as expected");
    }
    else
    {
	ok($r,"succeeded removing dir $d");
    }
}


# fixme renaming, but with topic-autocreate

# cleanup
chdir("/");
system("fusermount","-u",$td);
ok(!(0xffff & $?),"unmounting works");
sleep(1);
rmdir($td);
unlink($map);
unlink($outmap);

exit 0;

sub getdir
{
    my ($dn)=@_;
    opendir(F,$dn) or fail("can't opendir $dn: $!\n");
    my @r=readdir(F);
    closedir(F);
    return sort @r;
}

