#!/usr/bin/perl -w
use strict;
use Test::More tests => 103;
use t::helper;

# to read a file's contents
sub f_cont {
    my $fn = $mountpt."/".shift;
    open(IN, $fn) or return "ERR: can't open file $fn: $!";
    my $ret = join("", <IN>);
    close IN;
    return $ret;
}

# to write a file's contents
sub f_write {
    my ($fn, $cont) = @_;
    open(OUT, ">$mountpt/$fn") or return 0;
    print OUT $cont;
    close OUT;
    return 1;
}

# to get a directory's contents
sub d_cont {
    my $fn = $mountpt."/".shift;
    opendir DIR, $fn or return "ERR: can't read dir $fn: $!";
    my @ret = sort readdir(DIR);
    closedir DIR;
    return join(" ", @ret);
}

# to get an error on read or write
sub f_rd_err {
    $!=0;
    open(IN, $mountpt."/".shift);
    return "$!";
}

sub f_wr_err {
    $!=0;
    open(OUT, ">".$mountpt."/".shift);
    return "$!";
}

#    "a"  => "This is file a.\n",

ok(-e $mountpt."/a", "file a exists");
ok(-f $mountpt."/a", "file a is a file");
ok(-r $mountpt."/a", "file a readable");
ok(-s $mountpt."/a", "file a has size");
is(f_cont("a"), "This is file a.\n", "file a contents");

#    "b"  => "... and this... is file b, which is slightly longer!\n",

is(f_cont("b"), "... and this... is file b, which is slightly longer!\n",
    "file b");

#    "c"  => "This file contains \\all \r\n sorts \@ of \$ fun £ stuff\n",

is(f_cont("c"), "This file contains \\all \r\n sorts \@ of \$ fun £ stuff\n",
    "file c");

#    "d"  => {
#	"this"=>"", "dir"=>"", "contains"=>"", "a"=>"", "few"=>"",
#	"empty"=>"","files"=>"", "and"=>"", "one"=>"",
#	"subdir" => {
#	    "wow" => "this is fun!\n\n",
#	    "symlink" => \ "../empty",
#	},
#    },

ok(-d $mountpt."/d", "dir d is a dir");
is(d_cont("d"), ". .. a and contains dir empty few files one subdir this",
    "dir d contents");

ok(-d $mountpt."/d", "dir d/subdir is a dir");
is(d_cont("d/subdir"), ". .. symlink wow", "dir s/subdir contents");

ok(-f $mountpt."/d/subdir/wow", "d/subdir/wow is a file");
ok(-l $mountpt."/d/subdir/symlink", "d/subdir/symlink is a symlink");
is(readlink($mountpt."/d/subdir/symlink"), "../empty", "readlink");

#    "array" => [], # this is invalid. Any ideas?

ok(-e   $mountpt."/array", "array exists");
ok(-f   $mountpt."/array", "array is a file");
ok(! -r $mountpt."/array", "array not readable");
ok(! -w $mountpt."/array", "array not writable");
ok(! -s $mountpt."/array", "array has no size");
like(f_rd_err("array"), qr/not impl/i, "array error");

#    "progs" => {
#	"magic" => wrap(sub {return "42\n"; }, "MAGIC"),

ok(-f $mountpt."/progs/magic", "magic file is a file");
is(f_cont("progs/magic"), "42\n", "magic number is 42");

#	"time"  => wrap(
#	    sub {return         "the time is ".time()."\n";  }, "TIME"
#	),
#	"timenc"  => wrap(
#	    sub {return nocache("the time is ".time()."\n"); }, "TIMENC"
#	),

sub f_time {
    my ($a, $b) = @_;
    $a = f_cont($a);
    $a =~ /the time is (\d+)/ or return "not time file";
    my $diff = $1 - $b;
    return "out" if $diff < -1;
    return "out" if $diff > 1;
    return "right";
}

my $then = time();
ok(-f $mountpt."/progs/time", "time is a file");     # this gets cached
ok(-f $mountpt."/progs/timenc", "timenc is a file"); # this doesn't

diag("about to sleep for 5s to test cache");
sleep 5;

is(f_time("progs/time",   $then),  "right", "time was cached");
is(f_time("progs/timenc", time()), "right", "timenc was not cached");

#	"var"   => wrap(accessor(\$var), "VAR ACCESSOR"),
#	"var-dup" => wrap(accessor(\$var), "VAR-DUP ACCESSOR"),

ok(-s $mountpt."/progs/var", "progs/var has size");

ok(f_write("progs/var",     "wibble"), "writing progs/var wibble");
is(f_cont("progs/var"),     "wibble",  "read progs/var wibble");
is(f_cont("progs/var-dup"), "wibble",  "read progs/var-dup wibble");

# due to a FUSE (not Fuse.pm r FUSE::Simple?) bug, this would fail if
# the new contents had a different length, as the length of var is cached
# on the write above, and changed by writing to var-dup below.   :-(

ok(f_write("progs/var-dup", "wobble"), "writing progs/var-dup fnord");
is(f_cont("progs/var"),     "wobble",  "read progs/var fnord");
is(f_cont("progs/var-dup"), "wobble",  "read progs/var-dup fnord");

#	"var2"  => wrap(accessor(\ my $tmp2), "VAR2 ACCESSOR"),

ok(! -s $mountpt."/progs/var2", "progs/var2 has no size");
ok(! -r $mountpt."/progs/var2", "progs/var2 is not readable");
like(f_rd_err("progs/var2"), qr/Bad file descriptor/, "var2 bad fd");

ok(f_write("progs/var2", "erk"), "writing progs/var2");
ok(-s $mountpt."/progs/var2", "progs/var2 has size");
ok(-r $mountpt."/progs/var2", "progs/var2 is readable");
is(f_cont("progs/var2"), "erk", "var2 contents");

#	"var3"  => wrap(accessor(\ "unwritable value\n"), "VAR3 ACCESSOR"),

like(f_cont("progs/var3"), qr/unwritable/, "var3 contents");
like(f_wr_err("progs/var3"), qr/stale/i, "var3 unwritable");

#	"nasty" => wrap(sub {die "die sucker!"}, "NASTY"),

like(f_rd_err("progs/nasty"), qr/stale/i, "nasty unreadable");
like(f_wr_err("progs/nasty"), qr/stale/i, "nasty unwritable");

#	"nastync" => wrap(sub {die nocache "die sucker!\n"}, "NASTYNC"),

ok(-f $mountpt."/progs/nastync", "nastync is a file");
ok(-r $mountpt."/progs/nastync", "nastync  readable");
ok(-s $mountpt."/progs/nastync", "nastync has size");
like(f_cont("/progs/nastync"), qr/die sucker/, "nastync contents");

#	"dirsub" => wrap(sub { return {"1"=>"one", "2"=>"two"}}, "DIRSUB"),

ok(-d $mountpt."/progs/dirsub", "dirsub is a dir");
is(d_cont("progs/dirsub"), ". .. 1 2", "dirsub contents");
ok(-f $mountpt."/progs/dirsub/1", "dirsub/1 is a file");
is(f_cont("progs/dirsub/1"), "one", "dirsub/1 contents");
ok(-f $mountpt."/progs/dirsub/2", "dirsub/2 is a file");
is(f_cont("progs/dirsub/2"), "two", "dirsub/2 contents");

#	"odd-err-on-write" => wrap(
#	    sub {
#		die fserr(75) if defined shift; # EOVERFLOW
#		return "write to me\n"
#	    }, "odd-err-on-write"
#	),

ok(-f $mountpt."/progs/odd-err-on-write", "odd-err-on-write is a file");
ok(-r $mountpt."/progs/odd-err-on-write", "odd-err-on-write  readable");
ok(-s $mountpt."/progs/odd-err-on-write", "odd-err-on-write has size");
like(f_cont("/progs/odd-err-on-write"), qr/write to me/,
    "odd-err-on-write contents");
like(f_wr_err("/progs/odd-err-on-write"), qr/too large|overflow/,
    "odd-err-on-write err");

#	"die-sub" => wrap( sub { die { "1"=>"one", "2"=>"two" }}),

ok(-d $mountpt."/progs/die-sub", "die-sub is a dir");
is(d_cont("progs/die-sub"), ". .. 1 2", "die-sub contents");
ok(-f $mountpt."/progs/die-sub/1", "die-sub/1 is a file");
is(f_cont("progs/die-sub/1"), "one", "die-sub/1 contents");
ok(-f $mountpt."/progs/die-sub/2", "die-sub/2 is a file");
is(f_cont("progs/die-sub/2"), "two", "die-sub/2 contents");

#    "link_to_a" => \ "a",
#    "link_to_d" => \ "d",
#    "link_to_wow" => \ "d/subdir/wow",
#    "link_to_magic" => \ "./progs/magic",
#    "link_to_me" => \ "link_to_me",
#    "link_to_nofile" => \ "this-file-does-not-exist",

my %frto = (
    "link_to_a" => "a",
    "link_to_d" => "d",
    "link_to_wow" => "d/subdir/wow",
    "link_to_magic" => "./progs/magic",
    "link_to_me" => "link_to_me",
    "link_to_nofile" => "this-file-does-not-exist",
);
while ( my ($from, $to) = each %frto) {
    ok(-l $mountpt."/".$from, "$from is a symlink");
    is(readlink($mountpt."/".$from), $to, "$from links to $to");
}

#    "undef" => undef,

ok(-e $mountpt."/undef", "file undef exists");
ok(-f $mountpt."/undef", "file undef is a file");
ok(!-r $mountpt."/undef", "file undef not readable");
is(-s $mountpt."/undef", 0, "file undef has no size");
like(f_rd_err("undef"), qr/Bad file descriptor/, "undef bad fd");

ok(f_write("undef", "blargh"), "writing undef");

# same cache-size-on-write bug as above, can't trust size until:
diag "about to sleep for 2s to clear FUSE cache (not Fuse.pm or Fuse::Simple)";
sleep 2;

ok(!-r $mountpt."/undef", "file undef still not readable");
is(-s $mountpt."/undef", 0, "file undef STILL has no size");
like(f_rd_err("undef"), qr/Bad file descriptor/, "undef still bad fd");

# diag(`ls -Fal $mountpt/undef`);

#    "quotes" => {
#	"q"  => q{a single-quoted string\n},

is(d_cont("quotes"), ". .. q qq qr", "quotes contents");

ok(-e $mountpt."/quotes/q", "quotes/q exists");
ok(-f $mountpt."/quotes/q", "quotes/q is a file");
ok(-r $mountpt."/quotes/q", "quotes/q is readable");
ok(-s $mountpt."/quotes/q", "quotes/q has size");
is(f_cont("quotes/q"), 'a single-quoted string\n', "quotes/q contents");

#	"qq" => qq{a double-quoted string\n},

ok(-e $mountpt."/quotes/qq", "quotes/qq exists");
ok(-f $mountpt."/quotes/qq", "quotes/qq is a file");
ok(-r $mountpt."/quotes/qq", "quotes/qq is readable");
ok(-s $mountpt."/quotes/qq", "quotes/qq has size");
is(f_cont("quotes/qq"), "a double-quoted string\n", "quotes/qq contents");

#	"qr" => qr{a regular expression\n},

ok(-e   $mountpt."/quotes/qr", "quotes/qr exists");
ok(-f   $mountpt."/quotes/qr", "quotes/qr is a file");
ok(! -r $mountpt."/quotes/qr", "quotes/qr not readable");
ok(! -w $mountpt."/quotes/qr", "quotes/qr not writable");
ok(! -s $mountpt."/quotes/qr", "quotes/qr has no size");
like(f_rd_err("quotes/qr"), qr/not impl/i, "quotes/qr error");
