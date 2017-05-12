#!/usr/bin/perl
#+##############################################################################
#                                                                              #
# File: dqt.perl                                                               #
#                                                                              #
# Description: Directory::Queue test program                                   #
#                                                                              #
#-##############################################################################

# $Id: dqt.perl,v 1.27 2013/04/24 08:05:25 c0ns Exp $

#
# used modules
#

use strict;
use warnings qw(FATAL all);
use Directory::Queue qw();
use Getopt::Long qw(GetOptions);
use No::Worries::Die qw(handler dief);
use No::Worries::Dir qw(dir_read);
use No::Worries::Log qw(log_debug log_filter);
use No::Worries::Proc qw(proc_run);
use Pod::Usage qw(pod2usage);
use Time::HiRes qw();

#
# global variables
#

our(%Option, %Test);

#
# create a new directory queue
#

sub dirq ($) {
    my($schema) = @_;
    my(%newopt, $umask);

    $newopt{path} = $Option{path};
    if ($schema and $Option{type} eq "normal") {
        $newopt{schema} = {
            body   => $Option{string} ? "string" : "binary",
            header => "table?",
        };
        $newopt{schema}{body} .= "*" if $Option{reference};
    }
    $newopt{granularity} = $Option{granularity} if $Option{granularity};
    $newopt{maxelts} = $Option{maxelts} if $Option{maxelts};
    $newopt{rndhex} = $Option{rndhex} if defined($Option{rndhex});
    $umask = $Option{umask};
    $umask = oct($umask) if defined($umask) and $umask =~ /^0/;
    $newopt{umask} = $umask if defined($umask);
    $newopt{type} = ucfirst($Option{type});
    return(Directory::Queue->new(%newopt));
}

#
# generate a random string
#

sub rndstr ($$) {
    my($size, $random) = @_;
    my($rnd, $str);

    if ($random) {
        # see Irwin-Hall in http://en.wikipedia.org/wiki/Normal_distribution
        $rnd = rand(1) + rand(1) + rand(1) + rand(1) + rand(1) + rand(1) +
               rand(1) + rand(1) + rand(1) + rand(1) + rand(1) + rand(1);
        $rnd -= 6;
        $rnd *= $size / 6;
        $size += int($rnd);
    }
    if ($size < 1) {
        $str = "";
    } else {
        $str = ("A" x ($size - 1)) . "\n";
    }
    return(\$str);
}

#
# version test
#

sub test_version () {
    printf("\$Directory::Queue::VERSION = %s\n",
           $Directory::Queue::VERSION  || "<unknown>");
    printf("\$Directory::Queue::REVISION = %s\n",
           $Directory::Queue::REVISION || "<unknown>");
};

#
# size test
#

sub test_size () {
    my($dirq, $output, $status);

    $output = "";
    $status = proc_run(
        command => [ "du", "-ks", $Option{path} ],
        stdout => \$output,
    );
    dief("du failed: %d", $status) if $status;
    if ($output =~ /^(\d+)\s+\Q$Option{path}\E$/) {
        log_debug("queue uses %d kB", $1);
    } else {
        dief("unexpected du output: %s", $output);
    }
};

#
# count test
#

sub test_count () {
    my($dirq, $count);

    $dirq = dirq(0);
    $count = $dirq->count();
    log_debug("queue has %d elements", $count);
};

#
# purge test
#

sub test_purge () {
    my($dirq, %puropt);

    $dirq = dirq(0);
    $puropt{maxtemp} = $Option{maxtemp} if defined($Option{maxtemp});
    $puropt{maxlock} = $Option{maxlock} if defined($Option{maxlock});
    log_debug("purging the queue...");
    $dirq->purge(%puropt);
};

#
# iterate test (only lock+unlock)
#

sub test_iterate () {
    my($dirq, $name, $count);

    log_debug("iterating all elements in the queue (one pass)...");
    $dirq = dirq(0);
    $count = 0;
    for ($name = $dirq->first(); $name; $name = $dirq->next()) {
        $dirq->lock($name) or next;
        $count++;
        $dirq->unlock($name);
    }
    log_debug("iterated %d elements", $count);
};

#
# get test (lock+get+unlock)
#

sub test_get () {
    my($dirq, $name, $count, $tmp);

    log_debug("getting all elements in the queue (one pass)...");
    $dirq = dirq(1);
    $count = 0;
    for ($name = $dirq->first(); $name; $name = $dirq->next()) {
        $dirq->lock($name) or next;
        if ($Option{reference}) {
            if ($Option{type} eq "simple") {
                $dirq->get_ref($name);
            } else {
                $tmp = $dirq->get($name);
            }
        } else {
            ($tmp) = $dirq->get($name);
        }
        $count++;
        $dirq->unlock($name);
    }
    log_debug("got %d elements", $count);
};

#
# remove test (lock+remove)
#

sub test_remove () {
    my($dirq, $name, $count);

    if ($Option{count}) {
        log_debug("removing %d elements from the queue...", $Option{count});
    } else {
        log_debug("removing all elements from the queue (one pass)...");
    }
    $dirq = dirq(0);
    $count = 0;
    if ($Option{count}) {
        # loop to iterate until we are done
        while ($count < $Option{count}) {
            for ($name = $dirq->first(); $name; $name = $dirq->next()) {
                $dirq->lock($name) or next;
                $count++;
                $dirq->remove($name);
                last unless $count < $Option{count};
            }
        }
    } else {
        # one pass only
        for ($name = $dirq->first(); $name; $name = $dirq->next()) {
            $dirq->lock($name) or next;
            $count++;
            $dirq->remove($name);
        }
    }
    log_debug("removed %d elements", $count);
};

#
# add test
#

sub test_add () {
    my($dirq, $name, $count, %addopt, $strref, $ref);

    if ($Option{count}) {
        log_debug("adding %d elements to the queue...", $Option{count});
    } else {
        log_debug("adding elements to the queue forever...");
    }
    $addopt{header} = \%ENV if $Option{header};
    $strref = rndstr($Option{size}, 0)
        if $Option{size} and not $Option{random};
    $dirq = dirq(1);
    $count = 0;
    while (not $Option{count} or $count < $Option{count}) {
        if ($Option{size}) {
            $ref = $Option{random} ? rndstr($Option{size}, 1) : $strref;
        } elsif ($Option{string} and $Option{type} eq "normal") {
            $ref = \ "\xc9l\xe9ment $count \x{263A}\n";
        } else {
            $ref = \ "Element $count ;-)\n";
        }
        if ($Option{reference}) {
            if ($Option{type} eq "simple") {
                $name = $dirq->add_ref($ref);
            } else {
                $addopt{body} = $ref;
                $name = $dirq->add(\%addopt);
            }
        } else {
            if ($Option{type} eq "simple") {
                $name = $dirq->add(${ $ref });
            } else {
                $addopt{body} = ${ $ref };
                $name = $dirq->add(%addopt);
            }
        }
        $count++;
    }
    log_debug("added %d elements", $count);
};

#
# simple test (only on non-existing path!)
#
# this can be used for benchmarking:
#  $ perl -d:DProf dqt.perl -d -p /new/path -c 10000 simple
#  $ dprofpp -u
#

sub test_simple () {
    my(@list);

    dief("missing option: --count") unless $Option{count};
    dief("directory exists: %s", $Option{path}) if -e $Option{path};
    foreach my $name (qw(add count size purge get remove purge)) {
        $Test{$name}->();
    }
    @list = dir_read($Option{path});
    dief("unexpected subdirs: %s", "@list")
        unless @list == ($Option{type} eq "simple" ? 1 : 3);
    foreach my $name (map("$Option{path}/$_", @list), $Option{path}) {
        rmdir($name) or dief("cannot rmdir(%s): %s", $name, $!);
    }
};

#
# testing
#

sub test () {
    my($time1, $time2);

    dief("unknown test: %s", $ARGV[0]) unless $Test{$ARGV[0]};
    Time::HiRes::sleep($Option{sleep}) if $Option{sleep};
    $time1 = Time::HiRes::gettimeofday();
    $Test{$ARGV[0]}->();
    $time2 = Time::HiRes::gettimeofday();
    log_debug("done in %.4f seconds", $time2 - $time1);
}

#
# initialization
#

sub init () {
    $| = 1;
    $Option{debug} = 0;
    $Option{type} = "simple";
    Getopt::Long::Configure(qw(posix_default no_ignore_case));
    GetOptions(\%Option,
        "count|c=i",
        "debug|d+",
        "granularity=i",
        "header",
        "help|h|?",
        "list|l",
        "manual|m",
        "maxelts=i",
        "maxlock=i",
        "maxtemp=i",
        "path|p=s",
        "random",
        "reference",
        "rndhex=i",
        "size=i",
        "sleep=f",
        "string",
        "type=s",
        "umask=s",
    ) or pod2usage(2);
    pod2usage(1) if $Option{help};
    pod2usage(exitstatus => 0, verbose => 2) if $Option{manual};
    $Test{version} = \&test_version;
    $Test{size}    = \&test_size;
    $Test{count}   = \&test_count;
    $Test{purge}   = \&test_purge;
    $Test{iterate} = \&test_iterate;
    $Test{get}     = \&test_get;
    $Test{remove}  = \&test_remove;
    $Test{add}     = \&test_add;
    $Test{simple}  = \&test_simple;
    if ($Option{list}) {
        printf("Available tests: %s\n", join(" ", sort(keys(%Test))));
        exit(0);
    }
    dief("unsupported type: %s", $Option{type})
        unless $Option{type} =~ /^(normal|simple)$/;
    pod2usage(2) unless @ARGV == 1;
    log_filter("debug") if $Option{debug};
    dief("missing option: --path\n")
        unless $Option{path} or $ARGV[0] eq "version";
}

#
# just do it ;-)
#

init();
test();

__END__

=head1 NAME

dqt.perl - Directory::Queue test program

=head1 SYNOPSIS

B<dqt.perl> [I<OPTIONS>] [I<NAME>]

=head1 DESCRIPTION

This program exercises the Directory::Queue modules by adding, removing,
etc. elements in a directory queue. Read the source code if you want to know
more...

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2013
