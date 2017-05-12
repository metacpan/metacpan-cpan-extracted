#!/usr/bin/perl

# use 5.010;
use strict;
use warnings;

=head1 NAME



=head1 SYNOPSIS



=head1 OPTIONS

=over 8

=cut

my @opt = <<'=back' =~ /B<--(\S+)>/g;

=item B<--cleanup!>

Defaults to true. Negate with --nocleanup. If true, all generated
files are removed at the end of the test run.

=item B<--files=i>

Number of files to run through the experiment. Default is 15.

=item B<--help|h!>

This help

=item B<--sleep1=f>

Defaults to 0.2. Seconds to sleep between the cration of the initial
files.

=item B<--sleep2=f>

Defaults to 0.1. Seconds to sleep between the iterations of the second
phase.

=item B<--iterations=i>

Defaults to 30. Number of iterations in the second phase.

=back

=head1 DESCRIPTION

In the first phase the test creates a couple of files and injects them
into the tree, one after the other. There are tunable C<sleep1> pauses
between each file creation. In the second phase the test runs
alternating C<aggregate> commands on the server and C<rmirror>
commands on the client. After each iteration both directories are
checksummed and stored in a separate yaml file for later inspection.

If you want to inspect the yaml files, be sure to set --nocleanup.

=head2 Interpretation of the output

Output may look like this:

  # 17.1575 new state reached in t/serv-5c59696a590715c20f2b7f55c281c667.yaml
  # 18.0686 new state reached in t/mirr-b9b903e62f31249d2d5836eede1d0420.yaml
  # 19.2339 new state reached in t/serv-9a9df7f3c8d2fc501c27490696ba1c88.yaml
  # 33.2662 new state reached in t/serv-7ad22e96a3ecf527e1fa934425ec7516.yaml
  # 55.2330 new state reached in t/serv-ce628a7ee14eb32054f6744ab9772b2c.yaml

This means that the RECENT files on the server have changed 4 times
due to calls to C<aggregate> but the RECENT files on the mirror have
only changed once.

=cut


use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN {
    push @INC, qw(       );
}

use Getopt::Long;
use Hash::Util qw(lock_keys);

our %Opt;
lock_keys %Opt, map { /([^=!]+)/ } @opt;
GetOptions(\%Opt,
           @opt,
          ) or pod2usage(1);

$Opt{cleanup}    = 1   unless defined $Opt{cleanup};
$Opt{sleep1}     = 0.2 unless defined $Opt{sleep1};
$Opt{sleep2}     = 0.1 unless defined $Opt{sleep2};
$Opt{iterations} = 30  unless defined $Opt{iterations};
$Opt{files}      = 15  unless defined $Opt{files};


use File::Basename qw(dirname);
use File::Find;
use File::Path qw(mkpath rmtree);
use Time::HiRes qw(time sleep);
$^T = time; # force it to float
use YAML::Syck;

use Test::More;
my $tests;
BEGIN {
    $tests = 0;
}

use lib "lib";

my $root_from = "t/serv";
my $root_to = "t/mirr";
my $statusfile = "t/recent-rmirror-state.yml";
my @unlink = map { "t/$_-ttt.yaml" } qw(serv mirr);
rmtree [$root_from, $root_to];

my @cast =
    qw(
          princess
          king
          queen
          household
          horses
          dogs
          pidgeons
          flies
          fire
          roast
          cook
          scullion
          wind
          trees
          leaves
     );

while (@cast > $Opt{files}) {
    pop @cast;
}
{
    my $i = 2;
    while (@cast < $Opt{files}) {
        push @cast, "leaves ($i)";
        $i++;
    }
}
{
    my @intervals;
    my $test_counter;
    BEGIN {
        @intervals = qw( 2s 3s 5s 8s 13s 21s 34s 55s Z );
        # @intervals = qw( 89s 144s 233s 377s 610s 987s 1597s 2584s 4181s 6765s Z );
        # @intervals = qw( 2s 5s 13s 34s 89s 233s 610s 1597s 4181s Z );
        # @intervals = qw( 2s 5s 13s 34s 89s 233s 610s Z );
        $tests += 1;
    }
    my $rf0 = File::Rsync::Mirror::Recentfile->new
        (
         aggregator     => [@intervals[1..$#intervals]],
         interval       => $intervals[0],
         localroot      => $root_from,
         rsync_options  => {
                            compress          => 0,
                            links             => 1,
                            times             => 1,
                            checksum          => 0,
                           },
        );
    mkpath $root_from;
    mkpath $root_to;
    mkpath "t/tmp";
    my $cwd = Cwd::cwd;
    my $rrr = File::Rsync::Mirror::Recent->new
        (
         ignore_link_stat_errors => 1,
         localroot        => $root_to,
         remote           => "$root_from/RECENT.recent",
         rsync_options    => {
                              compress          => 0,
                              links             => 1,
                              times             => 1,
                              # not available in rsync 3.0.3: 'omit-dir-times'  => 1,
                              checksum          => 0,
                              'temp-dir'        => "$cwd/t/tmp",
                             },
        );
    my $latest_timestamp = 0;
    sub archive {
        for my $r ($root_from,$root_to) {
            next unless -d $r;
            my $tfile = "$r-ttt.yaml";
            my $ctx = Digest::MD5->new;
            my $y;
            File::Find::find
                    (
                     {
                      wanted => sub {
                          return unless -f $_;
                          my $content = do { open my $fh, $File::Find::name or die "Could not open '$File::Find::name': $!"; local $/; <$fh>};
                          $y->{substr($File::Find::name,1+length($r))} = $content;
                      },
                      no_chdir => 1,
                     },
                     $r
                    );
            while () {
                YAML::Syck::DumpFile $tfile, $y;
                my @stat = stat $tfile;
                if ($stat[9] == $latest_timestamp) {
                    # for a better overview over the results, never
                    # let two timestamps be the same
                    sleep 0.1;
                } else {
                    $latest_timestamp = $stat[9];
                    last;
                }
            }
            open my $fh, $tfile or die $!;
            $ctx->addfile($fh);
            my $digest = $ctx->hexdigest;
            my $pfile = "$r-$digest.yaml";
            next if -e $pfile;
            my $t = sprintf "%6.4f", time - $^T;
            diag "$t new state reached in $pfile";
            rename $tfile, $pfile or die $!;
            push @unlink, $pfile;
        }
    }
    sub ts {
        my($file, $message) = @_;
        my $t = sprintf "%6.4f", time - $^T;
        mkpath dirname $file;
        open my $fh, ">", $file or die "Could not open '$file': $!";
        print $fh "$message\n";
        $rf0->update($file,"new");
        $rf0->aggregate;
        diag "$t $message";
    }
    sub superevent {
        my($event) = @_;
        for my $i (0..$#cast) {
            my $actor = $cast[$i];
            my $file = sprintf "%s/%02d%s", $root_from, $i, $actor;
            my $message = "$actor $event";
            ts $file, $message;
            sleep $Opt{"sleep1"};
        }
    }
    # speeding up the process a little bit:
    superevent("sleeping");
    my $rfs = $rrr->recentfiles;
    for my $rf (@$rfs) {
        $rf->sleep_per_connection(0);
    }
    $rrr->_rmirror_sleep_per_connection(0.001);
    for (my $t=0; $t < $Opt{iterations}; $t++) {
        $rf0->aggregate;
        $rrr->rmirror;
        archive;
        sleep $Opt{sleep2};
    }
    ok(1);
}

if ($Opt{cleanup}) {
    rmtree [$root_from, $root_to, "t/tmp"];
    unlink @unlink;
}

BEGIN {
    if ($ENV{AUTHOR_TEST}) {
        plan tests => $tests
    } else {
        plan( skip_all => "tunable! To run, set env AUTHOR_TEST and tune" );
        eval "require POSIX; 1" and POSIX::_exit(0);
    }
}

use Cwd ();
use Digest::MD5 ();
use File::Rsync::Mirror::Recent;
use File::Rsync::Mirror::Recentfile;

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:
