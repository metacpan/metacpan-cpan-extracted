#!/usr/bin/perl

use ExtUtils::MakeMaker;
use strict;
use warnings;

print "This tool will try to remove old NATools instalation files.\n";
print "Note that depending on where you have your old NATools files, you might need\nto execute this script as superuser.\n";

print "\n";

my @todelete = ();
my @ftodelete = ();

# 1. Libraries

print "Will try to find libnatools in the standard locations...\n";
my @libfolders = qw(/usr/lib /usr/local/lib /opt/local/lib /sw/lib /opt/local/lib);
for my $f (@libfolders) {
    if (-f "$f/libnatools.a") {
        push @todelete, glob("$f/libnatools*");
    }
}
if (@todelete) {
    print "\nfound these files:\n";
    print join("", map { " - $_\n" } @todelete);
    my $ans = prompt("Can I delete these files? (y/n)", "N");
    if ($ans eq "y" || $ans eq "Y") {
        print "\n";
        for (@todelete) {
            print "Deleting $_\n";
            unlink $_;
        }
    }
} else { print "\nNone found...\n"; }
print "\n";

# 2. pm files
@todelete = ();
@ftodelete = ();
print "Now, I'll try to find the perl module files. I'll look into your \@INC for them.\n";
for my $f (@INC) {
    if (-d "$f/NAT") {
        push @todelete, glob("$f/NAT/*");
        push @ftodelete, "$f/NAT";
    }
    if (-d "$f/auto/NAT") {
        push @todelete, glob("$f/auto/NAT/*");
        push @ftodelete, "$f/auto/NAT";
    }
}

my $prefix = "";
if (@todelete) {
    $prefix = $todelete[0];
    if ($prefix =~ m!/lib!) {
        $prefix =~ s!/lib.*!!;
    } else {
        $prefix = undef;
    }

    print "\nfound these files:\n";
    print join("", map { " - $_\n" } @todelete);
    my $ans = prompt("Can I delete these files? (y/n)", "N");
    if ($ans eq "y" || $ans eq "Y") {
        print "\n";
        for (@todelete) {
            print "Deleting $_\n";
            unlink $_;
        }
        for (@ftodelete) {
            print "Deleting empty folder $_\n";
            rmdir $_;
        }
    }
} else { print "\nNone found...\n"; }
print "\n";

@todelete = ();
@ftodelete = ();

if (!$prefix) {
    print "I could not detect a prefix. Will not try to delete man pages.\n"
} else {
    print "Now trying to find application manpages...\n";
    for my $f ("$prefix/man/man1", "$prefix/man1",
               "$prefix/share/man/man1", "$prefix/share/man1") {
        if (-d $f) {
            push @todelete, glob("$f/nat-*.1");
        }
    }
    if (@todelete) {
        print "\nfound these files:\n";
        print join("", map { " - $_\n" } @todelete);
        my $ans = prompt("Can I delete these files? (y/n)", "N");
        if ($ans eq "y" || $ans eq "Y") {
            print "\n";
            for (@todelete) {
                print "Deleting $_\n";
                unlink $_;
            }
        }
    } else { print "\nNone found...\n"; }
    print "\n";

    @todelete = ();
    print "Now trying to find module manpages...\n";
    for my $f ("$prefix/man/man3", "$prefix/man3",
               "$prefix/share/man/man3", "$prefix/share/man3") {
        if (-d $f) {
            push @todelete, glob("$f/NAT::*.3pm");
        }
    }
    if (@todelete) {
        print "\nfound these files:\n";
        print join("", map { " - $_\n" } @todelete);
        my $ans = prompt("Can I delete these files? (y/n)", "N");
        if ($ans eq "y" || $ans eq "Y") {
            print "\n";
            for (@todelete) {
                print "Deleting $_\n";
                unlink $_;
            }
        }
    } else { print "\nNone found...\n"; }
    print "\n";

}

@todelete = ();

if (-d "$prefix/share/NATools") {
    print "The NATools data folder exists [$prefix/share/NATools].\n";
    my $ans = prompt("Can I remove it? (y/n)", "N");
    if ($ans eq "y" || $ans eq "Y") {
        print "\n";
        for (glob("$prefix/share/NATools/*")) {
            print "Deleting $_\n";
            unlink $_;
        }
        print "Deleting empty directory $prefix/share/NATools\n";
        rmdir "$prefix/share/NATools"
    }
}

print "\n";
@todelete = ();

my @apps = qw( nat-samplea nat-ptd nat-postbin nat-mkRealDict nat-translate-shell nat-mergeidx nat-sentence-align nat-create nat-grep nat-shell nat-codify nat-dict nat-ntd-add nat-CheckPTD nat-substDict nat-addDict nat-lex2perl nat-ipfp nat-compareDicts nat-css nat-ngrams nat-ntd-dump nat-pre nat-ngramsIdx nat-rank nat-mkMakefile nat-mat2dic nat-sentalign nat-server nat-mkntd nat-StarDict nat-initmat nat-sampleb nat-examplesExtractor nat-pair2tmx nat-words2id nat-makeCWB nat-tmx2pair nat-dumpDicts );

my @path = split /:/, $ENV{PATH};
print "Looking up for NATools executables...\n";
for my $path (@path) {
    for my $app (@apps) {
        push @todelete, "$path/$app" if -f "$path/$app";
    }
}
if (@todelete) {
    print "\nfound these files:\n";
    print join("", map { " - $_\n" } @todelete);
    my $ans = prompt("Can I delete these files? (y/n)", "N");
    if ($ans eq "y" || $ans eq "Y") {
        print "\n";
        for (@todelete) {
            print "Deleting $_\n";
            unlink $_;
        }
    }
} else { print "\nNone found...\n"; }
print "\n";

print "Your system should be clear. Good luck.\n\n";


__END__


