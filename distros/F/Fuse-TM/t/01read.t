# az Mon Nov 10 14:39:13 2008
# test for read functionality
# $Id: 01read.t,v 1.4 2009-12-07 05:12:25 az Exp $
use strict;
use Test::More qw(no_plan);
use File::Temp qw(tempdir tempfile);
use Test::Deep;
use TM::PSI;
use Data::Dumper;
use File::Slurp;

my ($f,$map)=tempfile("/tmp/tmfs.XXXXXX",SUFFIX=>".atm");
my $td=tempdir("/tmp/tmfs.XXXXXX");

write_file($map,<main::DATA>);

# access map 
system("./bin/tmfs","-b",$map,$td);
ok(!($? & 0xffff),"mounting on $td works");
sleep(1);

# toplevel dirs
cmp_deeply([getdir($td)],bag(qw(. .. topics assocs)),"toplevel dirs ok");

my @assoctypes=qw(assoca assocb assocc);
my @assocroles=qw(one two);
my @mytopics=((map { "topic".$_} ("a".."g")),
	      qw(somescope otherscope dud odd),@assoctypes,@assocroles);
my @infra=(keys(%{$TM::PSI::core->{mid2iid}}),
	   keys(%{$TM::PSI::topicmaps_inc->{mid2iid}}),
	   keys(%{$TM::PSI::astma_inc->{mid2iid}}));

cmp_deeply([getdir("$td/topics")],bag(qw(. ..),@mytopics,@infra),
	   "topic dirs ok");

# check invariant dir structure
for my $t (@mytopics)
{
#    print("got $t: ".Dumper(getdir("$td/topics/$t")));
    cmp_deeply([grep($_ ne "=", getdir("$td/topics/$t"))],
	       bag('~',qw(. .. isa isas instance instances name oc involved)),
	       "topic $t dir ok");
}

# check individual content
# plain basename
my $t="$td/topics/topica";
ok(!-e "$t/=","topica has no reifier");
ok(-z "$t/~","topica has no indicator");
ok(-e "$t/name/1","topica basename exists");
ok("has basename\n" eq read_file("$t/name/1"),"topica basename content");
for (qw(oc isa instance))
{
    cmp_deeply([getdir("$t/$_")],
	       bag(qw(. ..)),"topica has no $_");
}

# scoped and unscoped bns
$t="$td/topics/topicb";
my @bns=getdir("$t/name");
ok(@bns == 5, "topicb all basenames visible");
for my $n (@bns)
{
    next if $n=~/^\./;
    if ($n=~/^\d+\@(.+)$/)
    {
	ok("$1\n" eq scalar read_file("$t/name/$n"),
	   "topicb scoped bn ok");
    }
    else
    {
	ok("unscoped bn\n" eq scalar read_file("$t/name/$n"),
	   "topicb plain bn ok");
    }
}
ok(!-e "$t/=","topicb has no reifier");
ok(-z "$t/~","topicb has no indicator");
for (qw(oc isa instance))
{
    cmp_deeply([getdir("$t/$_")],
	       bag(qw(. ..)),"topicb has no $_");
}

# scoped and/or typed occurrences and inlines, class/instance
$t="$td/topics/topicc";
ok(!-e "$t/=","topicc has no reifier");
ok(-z "$t/~","topicc has no indicator");
for (qw(name instance))
{
    cmp_deeply([getdir("$t/$_")],
	       bag(qw(. ..)),"topicb has no $_");
}
cmp_deeply([getdir("$t/isa")],
	       bag(qw(. .. topice topicf)),"topicc isa topice/f");
ok("topice\ntopicf\n" eq read_file("$t/isas"),"topicc isas ok");
ok(readlink("$t/isa/topice") eq "../../topice","topicc isa 1 correct");
ok(readlink("$t/isa/topicf") eq "../../topicf","topicc isa 2 correct");

cmp_deeply([getdir("$td/topics/topice/instance")],
	       bag(qw(. .. topicc)),"topice has instance topicc");
cmp_deeply([getdir("$td/topics/topicf/instance")],
	       bag(qw(. .. topicc)),"topicf has instance topicc");
ok(readlink("$td/topics/topice/instance/topicc") eq "../../topicc","topice instance correct");
ok("topicc\n" eq read_file("$td/topics/topice/instances"),"topice instances ok");

ok(readlink("$td/topics/topicf/instance/topicc") eq "../../topicc","topicf instance correct");
ok("topicc\n" eq read_file("$td/topics/topicf/instances"),"topicf instances ok");

my @ocs=grep($_ !~ /^\./, getdir("$t/oc"));
ok(@ocs == 6,"topicc all oc/in visible");
for my $o (@ocs)
{
    if ($o=~/^\d+$/)
    {
	my $c=read_file("$t/oc/$o");
	chomp $c;
	ok($c eq "some text" || $c eq "some more text" || $c eq "http://pikiwedia.org/",
	   "topicc plain oc/in ok");
    }
    elsif ($o=~/^\d+:dud$/)
    {
	ok("http://some.dud.link/\n" eq read_file("$t/oc/$o"),"topicc typed oc ok");
    }
    elsif ($o=~/^\d+\@otherscope$/)
    {
	ok("thingie\n" eq read_file("$t/oc/$o"),"topicc scoped oc ok");
    }
    else
    {
	ok($o=~/^\d+:odd\@somescope$/,"topicc scoped+typed oc name $o ok");
	ok("http://odd.link/\n" eq read_file("$t/oc/$o"),"topicc scoped+typed oc $o content ok");
    }
}

# subject indicators
$t="$td/topics/topice";
ok(!-e "$t/=","topice has no reifier");
ok("http://pikiwedia.org/gaiagaiagaia/\nurn:x:y\n" eq read_file("$t/~"),"topice ok indicators");
for (qw(name oc isa))
{
    cmp_deeply([getdir("$t/$_")],
	       bag(qw(. ..)),"topice has no $_");
}


# reifiers external and internal
$t="$td/topics/topicf";
ok(-z "$t/~","topicf has no indicators");
ok("http://some.place/" eq readlink("$t/="),"topicf ok external locator");
for (qw(name oc isa))
{
    cmp_deeply([getdir("$t/$_")],
	       bag(qw(. ..)),"topicf has no $_");
}

$t="$td/topics/topicg";
ok(-z "$t/~","topicg has no indicators");
ok(readlink("$t/=") eq "../../assocs/assocc/1","topicg ok assoc locator");
for (qw(name oc isa instance))
{
    cmp_deeply([getdir("$t/$_")],
	       bag(qw(. ..)),"topicg has no $_");
}

# assocs: type dirs
cmp_deeply([getdir("$td/assocs")],bag(qw(. .. is-subclass-of),@assoctypes),"assoc type dirs ok");
# assoc tag dirs 
cmp_deeply([getdir("$td/assocs/assoca")],bag(qw(. .. 1)),"assoca tag dir ok");
cmp_deeply([getdir("$td/assocs/assocb")],bag(qw(. .. 1)),"assocb tag dir ok");
cmp_deeply([getdir("$td/assocs/assocc")],bag(qw(. .. 1 2)),"assocc tag dir ok");

# type links, role dirs, player dirs
for my $x (qw(assoca/1 assocb/1 assocc/1 assocc/2))
{
    my $tn=$x;
    $tn=~s/\/.*$//;
    ok(readlink("$td/assocs/$x/.type") eq "../../../topics/$tn","$x type link ok");
    cmp_deeply([getdir("$td/assocs/$x")],bag(qw(. .. .type one two)),"$x role dirs ok");
}

# player links, one simple assoc
cmp_deeply([getdir("$td/assocs/assoca/1/one")],bag(qw(. .. topica)),"assoca player one dir ok");
ok(readlink("$td/assocs/assoca/1/one/topica") eq "../../../../topics/topica","assoca player one link ok");
cmp_deeply([getdir("$td/assocs/assoca/1/two")],bag(qw(. .. topicb)),"assoca player two dir ok");
ok(readlink("$td/assocs/assoca/1/two/topicb") eq "../../../../topics/topicb","assoca player two link ok");

# player links, one multi-player assoc
cmp_deeply([getdir("$td/assocs/assocc/2/one")],bag(qw(. .. topicb)),"assocc player one dir ok");
ok(readlink("$td/assocs/assocc/2/one/topicb") eq "../../../../topics/topicb","assocc player one link ok");

cmp_deeply([getdir("$td/assocs/assocc/2/two")],bag(qw(. .. topica topicc)),"assocc player two dir ok");
ok(readlink("$td/assocs/assocc/2/two/topicc") eq "../../../../topics/topicc","assocc player two-1 link ok");
ok(readlink("$td/assocs/assocc/2/two/topica") eq "../../../../topics/topica","assocc player two-2 link ok");

# topics involved in assoc
cmp_deeply([getdir("$td/topics/assoca/involved")],bag(qw(. .. 1:type)),"assoca involved as type");
cmp_deeply([getdir("$td/topics/one/involved")],bag(qw(. .. 1:role 2:role 3:role 4:role)),"one involved as role");
cmp_deeply([getdir("$td/topics/topica/involved")],bag(qw(. .. 1:player 2:player)),"topica involved as player");

# check one link each
ok(readlink("$td/topics/assoca/involved/1:type") eq "../../../assocs/assoca/1","assoca type involvement ok");
ok(readlink("$td/topics/one/involved/1:role") =~ m!../../../assocs/assoc([ab]/1|c/[12])$!,
   "one role involvement ok");
ok(readlink("$td/topics/topice/involved/1:player") eq "../../../assocs/assocc/1","topice player involvement ok");


# check hiding function
system("fusermount","-u",$td);
ok(!(0xffff & $?),"unmounting works");

system("./bin/tmfs","-b","-h",$map,$td);
ok(!($? & 0xffff),"mounting on $td with option hide-infra works");
sleep(1);

cmp_deeply([getdir("$td/topics")],bag(qw(. ..),@mytopics,map { ".".$_} @infra),
	   "topic dirs with hidden infrastructure topics ok");
ok(readlink("$td/assocs/is-subclass-of/1/.type") eq "../../../topics/.is-subclass-of",
   "assocs of hidden type ok");

# cleanup
system("fusermount","-u",$td);
ok(!(0xffff & $?),"unmounting works");
rmdir($td);
unlink($map);
exit 0;

sub getdir
{
    my ($dn)=@_;
    opendir(F,$dn) or fail("can't opendir $dn: $!\n");
    my @r=readdir(F);
    closedir(F);
    return sort @r;
}


__DATA__
# small testmap for tmfs reading

topica
bn: has basename

topicb
bn@somescope: somescope
bn: unscoped bn
bn@otherscope: otherscope

topicc (topice topicf)
oc: http://pikiwedia.org/
in: some text
in: some more text
oc(dud): http://some.dud.link/
oc@somescope(odd): http://odd.link/
in@otherscope: thingie

topice
sin: http://pikiwedia.org/gaiagaiagaia/
sin: urn:x:y

topicf reifies http://some.place/

(assoca)
one: topica
two: topicb

(assocb)
one: topicb
two: topicc

(assocc) is-reified-by topicg
one: topicd
two: topice

(assocc)
one: topicb
two: topica topicc
