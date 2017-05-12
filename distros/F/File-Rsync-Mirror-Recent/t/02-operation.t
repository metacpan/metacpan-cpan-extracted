use Getopt::Long;
use Test::More;
use strict;
my $tests;
BEGIN { $tests = 0 }
use lib "lib";

my %Opt;
GetOptions(
           "verbose!",
          ) or die;
$Opt{verbose} ||= $ENV{PERL_RERSYNCRECENT_TEST_VERBOSE};

my $HAVE;
BEGIN {
    # neither LibMagic nor MMagic tell them apart
    for my $package (
                     # "File::LibMagic",
                     "File::MMagic",
                    ) {
        $HAVE->{$package} = eval qq{ require $package; };
    }
}

use Dumpvalue;
use File::Basename qw(dirname);
use File::Copy qw(cp);
use File::Path qw(mkpath rmtree);
use File::Rsync::Mirror::Recent;
use File::Rsync::Mirror::Recentfile;
use List::MoreUtils qw(uniq);
use Storable;
use Time::HiRes qw(time sleep);
use YAML::Syck;

my $root_from = "t/ta";
my $root_to = "t/tb";
my $statusfile = "t/recent-rmirror-state.yml";
rmtree [$root_from, $root_to];

{
    my @serializers;
    my $test_counter;
    BEGIN {
        $test_counter = $tests;
        @serializers = (
                        [".yaml","YAML::Syck"],
                        [".json","JSON"],
                        [".sto","Storable"],
                        [".dd","Data::Dumper"],
                       );
        $tests += @serializers;
        if ($HAVE->{"File::LibMagic"}||$HAVE->{"File::MMagic"}) {
            $tests += @serializers;
        }
    }
    printf "#test_counter[%d]\n", $test_counter;
    mkpath $root_from;
    my $ttt = "$root_from/ttt";
    open my $fh, ">", $ttt or die "Could not open: $!";
    print $fh time;
    close $fh or die "Could not close: $!";
    my $fm;
    if ($HAVE->{"File::LibMagic"}) {
        $fm = File::LibMagic->new();
    } elsif ($HAVE->{"File::MMagic"}) {
        $fm = File::MMagic->new();
    }
    for my $serializer (@serializers) {
        my($s,$module) = @$serializer;
        unless (eval "require $module; 1") {
            ok(1, "Skipping because $module not installed");
            if ($fm) {
                ok(1, "Skipping the magic test for same reason");
            }
            next;
        }
        my $rf = File::Rsync::Mirror::Recentfile->new
            (
             filenameroot   => "RECENT",
             interval       => q(1m),
             localroot      => $root_from,
             serializer_suffix => $s,
            );
        $rf->update($ttt,"new");
        if ($fm) {
            my $magic = $fm->checktype_filename("$root_from/RECENT-1m$s");
            ok($magic, sprintf
               ("Got a magic[%s] for s[%s]: [%s]",
                ref $fm,
                $s,
                $magic,
               ));
        }
        my $content = do {open my $fh, "$root_from/RECENT-1m$s";local $/;<$fh>};
        $content = Dumpvalue->new()->stringify($content);
        my $want_length = 42; # or maybe 3 more
        substr($content,$want_length) = "..." if length $content > 3+$want_length;
        ok($content, "Got a substr for s[$s]: [$content]");
    }
}

rmtree [$root_from, $root_to];

{
    # very small tree, aggregate it
    my @intervals;
    my $test_counter;
    BEGIN {
        $test_counter = $tests;
        @intervals = qw( 2s 4s 8s 16s 32s Z );
        $tests += 2 + 2 * (10 + 14 * @intervals); # test_counter
    }
    printf "#test_counter[%d]\n", $test_counter;
    ok(1, "starting smalltree block");
    is 6, scalar @intervals, "array has 6 elements: @intervals";
    printf "#test_counter[%d]\n", $test_counter+=2;
    for my $pass (0,1) {
        my $rf0 = File::Rsync::Mirror::Recentfile->new
            (
             aggregator     => [@intervals[1..$#intervals]],
             interval       => $intervals[0],
             localroot      => $root_from,
             rsync_options  => [
                                compress          => 0,
                                links             => 1,
                                times             => 1,
                                checksum          => 0,
                               ],
            );
        my $timestampfutured = 0;
        for my $iv (@intervals) {
            for my $i (0..3) {
                my $file = sprintf
                    (
                     "%s/A%s-%02d",
                     $root_from,
                     $iv,
                     $i,
                    );
                mkpath dirname $file;
                open my $fh, ">", $file or die "Could not open '$file': $!";
                print $fh time, ":", $file, "\n";
                close $fh or die "Could not close '$file': $!";
                $rf0->update($file,"new");
                if ($pass==1 && !$timestampfutured) {
                    my $recent_events = $rf0->recent_events;
                    $recent_events->[0]{epoch} += 987654321;
                    $rf0->write_recent($recent_events);
                    $timestampfutured++;
                }
            }
        }
        my $recent_events = $rf0->recent_events;
        # faking internals as if the contents were wide-spread in time
        for my $evi (0..$#$recent_events) {
            my $ev = $recent_events->[$evi];
            $ev->{epoch} -= 2**($evi*.25);
        }
        $rf0->write_recent($recent_events);
        $rf0->aggregate;
        my $filesize_threshold = 1750; # XXX may be system dependent
        my %size_before;
        for my $iv (@intervals) {
            my $rf = "$root_from/RECENT-$iv.yaml";
            my $filesize = -s $rf;
            $size_before{$iv} = $filesize;
            # now they have $filesize_threshold+ bytes because they were merged for the
            # first time ever and could not be truncated for this reason.
            ok( $filesize > $filesize_threshold, "file $iv (before merging) has good size[$filesize]");
            utime 0, 0, $rf; # so that the next aggregate isn't skipped
        }
        printf "#test_counter[%d]\n", $test_counter+=6;
        open my $fh, ">", "$root_from/finissage" or die "Could not open: $!";
        print $fh "fin";
        close $fh or die "Could not close: $!";
        $rf0->update("$root_from/finissage","new");
        $rf0 = File::Rsync::Mirror::Recentfile->new_from_file("$root_from/RECENT-2s.yaml");
        $rf0->aggregate;
        for my $iv (@intervals) {
            my $filesize = -s "$root_from/RECENT-$iv.yaml";
            # now they have <$filesize_threshold bytes because the second aggregate could
            # truncate them
            ok($iv eq "Z" || $filesize<$size_before{$iv}, "file $iv (after merging) has good size[$filesize<$size_before{$iv}]");
        }
        printf "#test_counter[%d]\n", $test_counter+=6;
        my $dagg1 = $rf0->_debug_aggregate;
        Time::HiRes::sleep 1.2;
        $rf0->aggregate;
        my $dagg2 = $rf0->_debug_aggregate;
        {
            my $recc = File::Rsync::Mirror::Recent->new
                (
                 local => "$root_from/RECENT-2s.yaml",
                );
            ok $recc->overview, "overview created";
            # diag $recc->overview;
        }
        printf "#test_counter[%d]\n", $test_counter+=1;
        for my $dirti (0,1,2) {
            open my $fh2, ">", "$root_from/dirty$dirti" or die "Could not open: $!";
            print $fh2 "dirty$dirti";
            close $fh2 or die "Could not close: $!";
            my $timestamp = $dirti <= 1 ? "999.999" : "1999.999";
            my $becomes_i = $dirti <= 1 ? -1 : -3;
            $rf0->update("$root_from/dirty$dirti","new",$timestamp);
            $recent_events = $rf0->recent_events;
            is $recent_events->[-1]{epoch}, $timestamp, "found the dirty timestamp during dirti[$dirti]";
            printf "#test_counter[%d]\n", $test_counter+=1;
            $rf0->aggregate(force => 1);
            my $recc = File::Rsync::Mirror::Recent->new
                (
                 localroot => $root_from,
                 local => "$root_from/RECENT.recent",
                );
            my %seen;
            for my $rf (@{$recc->recentfiles}) {
                my $isec = $rf->interval_secs;
                my $re = $rf->recent_events;
                like $re->[-1]{epoch}, qr/999\.999/, "found some dirty timestamp[$re->[-1]{epoch}] in isec[$isec]";
                my $dirtymark = $rf->dirtymark;
                ok $dirtymark, "dirtymark[$dirtymark]";
                $seen{ $rf->dirtymark }++;
            }
            printf "#test_counter[%d]\n", $test_counter+=12;
            is scalar keys %seen, 1, "all recentfiles have the same dirtymark";
            printf "#test_counter[%d]\n", $test_counter+=1;
            sleep 0.2;
            $rf0->aggregate(force => 1);
            my $rfs = $recc->recentfiles;
            for my $i (0..$#$rfs) {
                my $rf = $rfs->[$i];
                my $re = $rf->recent_events;
                if ($i == 0) {
                    unlike $re->[-1]{epoch}, qr/999\.999/, "dirty file events already moved up i[$i]";
                } elsif ($i == $#$rfs) {
                    is $re->[$becomes_i]{epoch}, $timestamp, "found the dirty timestamp on i[$i]";
                } else {
                    isnt $re->[-1]{epoch}, $timestamp, "dirty timestamp gone on i[$i]";
                }
                my $dirtymark = $rf->dirtymark;
                ok $dirtymark, "dirtymark[$dirtymark]";
                $seen{ $rf->dirtymark }++;
            }
            printf "#test_counter[%d]\n", $test_counter+=12;
            is scalar keys %seen, 1, "all recentfiles have the same dirtymark";
            printf "#test_counter[%d]\n", $test_counter+=1;
        }
        # $DB::single++;
        rmtree [$root_from];
    }
}

rmtree [$root_from, $root_to];

{
    # replay a short history, run aggregate on it, add files, aggregate again
    my $test_counter;
    BEGIN {
        $test_counter = $tests;
        $tests += 208;
    }
    printf "#test_counter[%d]\n", $test_counter;
    ok(1, "starting short history block");
    my $rf = File::Rsync::Mirror::Recentfile->new_from_file("t/RECENT-6h.yaml");
    my $recent_events = $rf->recent_events;
    my $recent_events_cnt = scalar @$recent_events;
    is (
        92,
        $recent_events_cnt,
        "found $recent_events_cnt events",
       );
    $rf->interval("5s");
    $rf->localroot($root_from);
    $rf->comment("produced during the test 02-operation.t");
    $rf->aggregator([qw(10s 30s 1m 1h Z)]);
    $rf->verbose(0);
    my $start = Time::HiRes::time;
    for my $e (@$recent_events) {
        for my $pass (0,1) {
            my $file = sprintf
                (
                 "%s/%s",
                 $pass==0 ? $root_from : $root_to,
                 $e->{path},
                );
            mkpath dirname $file;
            open my $fh, ">", $file or die "Could not open '$file': $!";
            print $fh time, ":", $file, "\n";
            close $fh or die "Could not close '$file': $!";
            if ($pass==0) {
                $rf->update($file,$e->{type});
            }
        }
    }
    $rf->aggregate;
    my $took = Time::HiRes::time - $start;
    ok $took > 0, "creating the tree and aggregate took $took seconds";
    my $dagg1 = $rf->_debug_aggregate;
    for my $i (1..5) {
        my $file_from = "$root_from/anotherfilefromtesting$i";
        open my $fh, ">", $file_from or die "Could not open: $!";
        print $fh time, ":", $file_from;
        close $fh or die "Could not close: $!";
        $rf->update($file_from,"new");
    }
    $rf->aggregate;
    my $dagg2 = $rf->_debug_aggregate;
    undef $rf;
    ok($dagg1->[0]{size} < $dagg2->[0]{size}, "The second 5s file size larger: $dagg1->[0]{size} < $dagg2->[0]{size}");
    ok($dagg1->[1]{mtime} <= $dagg2->[1]{mtime}, "The second 30s file timestamp larger: $dagg1->[1]{mtime} <= $dagg2->[1]{mtime}");
    is $dagg1->[2]{size}, $dagg2->[2]{size}, "The 1m file size unchanged";
    is $dagg1->[3]{mtime}, $dagg2->[3]{mtime}, "The 1h file timestamp unchanged";
    ok -l "t/ta/RECENT.recent", "found the symlink";
    my $have_slept = my $have_worked = 0;
    $start = Time::HiRes::time;
    my $debug = +[];
    for my $i (0..99) {
        my $file = sprintf
            (
             "%s/secscnt%03d",
             $root_from,
             ($i<25) ? ($i%12) : $i,
            );
        open my $fh, ">", $file or die "Could not open '$file': $!";
        print $fh time, ":", $file, "\n";
        close $fh or die "Could not close '$file': $!";
        my $another_rf = File::Rsync::Mirror::Recentfile->new
            (
             interval => "5s",
             localroot => $root_from,
             aggregator => [qw(10s 30s 1m Z)],
            );
        $another_rf->update($file,"new");
        my $should_have = 97 + (($i<25) ? ($i < 12 ? ($i+1) : 12) : ($i-12));
        my($news,$filtered_news);
        if ($i < 50) {
            $another_rf->aggregate;
        }
        {
            my $recc = File::Rsync::Mirror::Recent->new
                (
                 local => "$root_from/RECENT-5s.yaml",
                );
            $news = $recc->news ();
            $filtered_news = [ uniq map { $_->{path} } @$news ];
        }
        is scalar @$filtered_news, $should_have, "should_have[$should_have]" or die;
        $debug->[$i] = $news;
        my $rf2 = File::Rsync::Mirror::Recentfile->new_from_file("$root_from/RECENT-5s.yaml");
        my $rece = $rf2->recent_events;
        my $rececnt = @$rece;
        my $span = $rece->[0]{epoch} - $rece->[-1]{epoch};
        $have_worked = Time::HiRes::time - $start - $have_slept;
        ok($rececnt > 0
           && ($i<50 ? $span <= 5 # we have run aggregate, so it guaranteed(*)
               : $i < 90 ? 1      # we have not yet spent 5 seconds, so cannot predict
               : $span > 5        # we have certainly written enough files now, must happen
              ),
           sprintf
           ("i[%s]cnt[%s]span[%s]worked[%6.4f]",
            $i,
            $rececnt,
            $span,
            $have_worked,
           ));
        $have_slept += Time::HiRes::sleep 0.2;
    }
    # (*) "<=" instead of "<" because of rounding errors
}

{
    # running mirror
    my $test_counter;
    BEGIN {
        $test_counter = $tests;
        $tests += 3;
    }
    printf "#test_counter[%d]\n", $test_counter;
    my $rf = File::Rsync::Mirror::Recentfile->new
        (
         filenameroot              => "RECENT",
         interval                  => q(30s),
         localroot                 => $root_to,
         max_rsync_errors          => 0,
         remote_dir                => $root_from,
         # verbose                 => 1,
         max_files_per_connection  => 65,
         rsync_options  => {
                            compress          => 0,
                            links             => 1,
                            times             => 1,
                            # not available in rsync 3.0.3: 'omit-dir-times'  => 1,
                            checksum          => 0,
                           },
        );
    my $somefile_epoch;
    for my $pass (0,1) {
        my $success;
        if (0 == $pass) {
            $success = $rf->mirror;
            my $re = $rf->recent_events;
            $somefile_epoch = $re->[24]{epoch};
        } elsif (1 == $pass) {
            $success = $rf->mirror(after => $somefile_epoch);
        }
        ok($success, "mirrored pass[$pass] without dying");
    }
    {
        my $recc = File::Rsync::Mirror::Recent->new
            (  # ($root_from, $root_to)
             local => "$root_from/RECENT-5s.yaml",
            );
        diag "\n" if $Opt{verbose};
        diag $recc->overview if $Opt{verbose};
    }
    {
        my $recc = File::Rsync::Mirror::Recent->new
            (
             # ignore_link_stat_errors => 1,
             localroot => $root_to,
             remote => "$root_from/RECENT-5s.yaml",
             # verbose => 1,
             max_files_per_connection => 512,
             rsync_options => {
                               links => 1,
                               times => 1,
                               compress => 1,
                               checksum => 1,
                              },
            );
        $recc->rmirror;
    }
    {
        my $recc = File::Rsync::Mirror::Recent->new
            (  # ($root_from, $root_to)
             local => "$root_to/RECENT-5s.yaml",
            );
        diag "\n" if $Opt{verbose};
        diag $recc->overview if $Opt{verbose};
    }
    {
        BEGIN {
            $tests += 2;
        }
        my $recc = File::Rsync::Mirror::Recent->new
            (
             # order matters!
             # ignore_link_stat_errors => 1,
             localroot                   => $root_to,
             remote                      => "$root_from/RECENT.recent",
             max_files_per_connection    => 65,
             rsync_options               =>
             {
              links     => 1,
              times     => 1,
              compress  => 1,
              checksum  => 1,
             },
             _runstatusfile              => $statusfile,
             verbose                     => $Opt{verbose},
            );
        $recc->rmirror;
        my $rf2 = File::Rsync::Mirror::Recentfile->new_from_file("$root_from/RECENT-5s.yaml");
        my $file = "$root_from/about-re-mirroring.txt";
        open my $fh, ">", $file or die "Could not open '$file': $!";
        print $fh time;
        close $fh or die "Could not close '$file': $!";
        $rf2->update($file, "new");
        $recc->rmirror;
        ok -e "$root_to/about-re-mirroring.txt", "picked up the update";
        $file = "$root_from/about-re2-mirroring.txt";
        undef $fh;
        open $fh, ">", $file or die "Could not open '$file': $!";
        print $fh time;
        close $fh or die "Could not close '$file': $!";
        $rf2->update($file, "new", 123456789);
        $rf2->aggregate(force => 1);
        $rf2->aggregate(force => 1);
        $recc->verbose(1) if $Opt{verbose};

        # { no warnings 'once'; $DB::single++; }
        # x map { $_->dirtymark } @{$self->recentfiles}
        # x map { $_->_seeded } @{$self->recentfiles}
        # x sort keys %$rf
        # $recc->verbose(1)

        $recc->rmirror;
        ok -e "$root_to/about-re2-mirroring.txt", "picked up a dirty update";
    }
    {
        my $recc = File::Rsync::Mirror::Recent->new
            (  # ($root_from, $root_to)
             local => "$root_to/RECENT-5s.yaml",
            );
        diag "\n" if $Opt{verbose};
        diag $recc->overview if $Opt{verbose};
    }
    {
        my $recc = File::Rsync::Mirror::Recent->new
            (
             # ignore_link_stat_errors => 1,
             localroot => $root_to,
             local => "$root_to/RECENT.recent",
            );
        my %seen;
        for my $rf (@{$recc->recentfiles}) {
            my $dirtymark = $rf->dirtymark or next;
            $seen{ $dirtymark }++;
        }
        is scalar keys %seen, 1, "all recentfiles have the same dirtymark or we don't know it";
    }
}

rmtree [$root_from, $root_to, $statusfile] unless $Opt{verbose};

BEGIN {
    plan tests => $tests
}

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:
