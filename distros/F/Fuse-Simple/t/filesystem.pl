#!/usr/bin/perl -w
use strict;
use Fuse::Simple qw(accessor main wrap fserr nocache);
# use Errno qw(:POSIX);

######################################################################
# My filesystem
######################################################################

my $var = "write something else in this file\n";
my %fs = (
    "a"  => "This is file a.\n",
    "b"  => "... and this... is file b, which is slightly longer!\n",
    "c"  => "This file contains \\all \r\n sorts \@ of \$ fun £ stuff\n",
    "d"  => {
	"this"=>"", "dir"=>"", "contains"=>"", "a"=>"", "few"=>"",
	"empty"=>"","files"=>"", "and"=>"", "one"=>"",
	"subdir" => {
	    "wow" => "this is fun!\n\n",
	    "symlink" => \ "../empty",
	},
    },
    "array" => [], # this is invalid. Any ideas?
    "progs" => {
	"magic" => wrap(sub {return "42\n"; }, "MAGIC"),
	"time"  => wrap(
	    sub {return         "the time is ".time()."\n";  }, "TIME"
	),
	"timenc"  => wrap(
	    sub {return nocache("the time is ".time()."\n"); }, "TIMENC"
	),
	"var"   => wrap(accessor(\$var), "VAR ACCESSOR"),
	"var-dup" => wrap(accessor(\$var), "VAR-DUP ACCESSOR"),
	"var2"  => wrap(accessor(\ my $tmp2), "VAR2 ACCESSOR"),
	"var3"  => wrap(accessor(\ "unwritable value\n"), "VAR3 ACCESSOR"),
	
	"nasty" => wrap(sub {die "die sucker!"}, "NASTY"),
	"nastync" => wrap(sub {die nocache "die sucker!\n"}, "NASTYNC"),
	"dirsub" => wrap(sub { return {"1"=>"one", "2"=>"two"}}, "DIRSUB"),
	"odd-err-on-write" => wrap(
	    sub {
		die fserr(75) if defined shift; # EOVERFLOW
		return "write to me\n"
	    }, "odd-err-on-write"
	),
	"die-sub" => wrap( sub { die { "1"=>"one", "2"=>"two" }}),
    },
    "link_to_a" => \ "a",
    "link_to_d" => \ "d",
    "link_to_wow" => \ "d/subdir/wow",
    "link_to_magic" => \ "./progs/magic",
    "link_to_me" => \ "link_to_me",
    "link_to_nofile" => \ "this-file-does-not-exist",
    "undef" => undef,
    "quotes" => {
	"q"  => q{a single-quoted string\n},
	"qq" => qq{a double-quoted string\n},
	"qr" => qr{a regular expression\n},
    },
);

######################################################################
# Main fuse loop
######################################################################

main(
    "/"     => \%fs,
#    "debug" => 1,
    "mountopts" => "",
);
