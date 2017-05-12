use Data::Dumper;
use File::Copy qw(cp);
use File::Path qw(mkpath rmtree);
use File::Rsync::Mirror::Recentfile;
use File::Rsync::Mirror::Recentfile::Done;
use List::Util qw(sum);
use Storable qw(dclone);
use Test::More;
our $HAVE_YAML_SYCK;
BEGIN { $HAVE_YAML_SYCK = eval { require YAML::Syck; 1; }; }
use strict;
my $tests;
BEGIN { $tests = 0 }
use lib "lib";

my @recent_events = map { +{ epoch => $_ } }
    (
     "1216706557.63601",
     "1216706557.5279",
     "1216706557.23439",
     "1216706555.44193",
     "1216706555.17699",
     "1216706554.23419",
     "1216706554.12319",
     "1216706553.47884",
     "1216706552.9627",
     "1216706552.661",
    );

# lm = long mantissa
my @recent_events_lm = map { +{ epoch => $_ } }
    (
     "100.0000000000000001116606557906601",
     "100.0000000000000001116606557806690",
     "100.0000000000000001116606557706639",
     "100.0000000000000001116606557606693",
     "100.0000000000000001116606557506699",
      "99.9999999999999991116606557406619",
      "99.9999999999999991116606557306619",
      "99.9999999999999991116606557206684",
      "99.9999999999999991116606557106670",
      "99.9999999999999991116606557006600",
    );

my @snapshots;

{
    my @t;
    BEGIN {
        @t =
            (
             [[0,1,2],[3,4,5],[6,7,8,9]],
             [[9,8],[7,6,5],[4,3,2,1,0]],
             [[0,1,5],[3,4],[2,6,7,8,9]],
             [[1,5],[3,4,5,7],[2,0,6,7,9,8]],
            );
        my $sum = sum map { my @cnt = @$_; scalar @cnt; } @t;
        $tests += 2 * $sum;
    }
    for my $t (@t) {
        my $done = File::Rsync::Mirror::Recentfile::Done->new;
        my $done_lm = File::Rsync::Mirror::Recentfile::Done->new;
        my @sessions = @$t;
        for my $i (0..$#sessions) {
            my $session = $sessions[$i];

            $done->register ( \@recent_events, $session );
            my $boolean = $done->covered ( map {$_->{epoch}} @recent_events[0,-1] );
            is 0+$boolean, $i==$#sessions ? 1 : 0, $recent_events[$session->[0]]{epoch} or
                die Dumper({boolean=>$boolean,i=>$i,done=>$done});

            $done_lm->register ( \@recent_events_lm, $session );
            my $boolean_lm = $done_lm->covered ( map {$_->{epoch}} @recent_events_lm[0,-1] );
            is 0+$boolean_lm, $i==$#sessions ? 1 : 0, $recent_events_lm[$session->[0]]{epoch}  or
                die Dumper({boolean_lm=>$boolean_lm,i=>$i,done_lm=>$done_lm});

            push @snapshots, dclone $done, dclone $done_lm;
        }
    }
}

{
    BEGIN {
        $tests += 1;
        if ($HAVE_YAML_SYCK) {
            $tests += 1;
        }
    }
    my $snapshots = scalar @snapshots;
    ok $snapshots>=24, "enough snapshots[$snapshots]";
    my $ok = 0;
    for my $i (0..$#snapshots) {
        my($a) = [@snapshots[$i-1,$i]];
        my $b = dclone $a;
        $a->[0]->merge($a->[1]);
        $b->[1]->merge($b->[0]);
        if ($HAVE_YAML_SYCK) {
            $ok++ if YAML::Syck::Dump($a->[0]) eq YAML::Syck::Dump($b->[1]);
        }
    }
    if ($HAVE_YAML_SYCK) {
        is $ok, $snapshots, "all merge operations OK";
    }
}

{
    BEGIN {
        $tests += 4;
    }
    mkpath "t/ta";
    cp "t/RECENT-1h.yaml", "t/ta/RECENT-Z.yaml";
    my $rf = bless( {
    '-aggregator' => [
      '1d',
      '1W',
      '1M',
      '1Q',
      '1Y',
      'Z'
    ],
    '-_localroot' => "t/ta",
    '-filenameroot' => 'RECENT',
    '-serializer_suffix' => '.yaml',
    '-minmax' => {
      'mtime' => '1223270942',
      'min' => '1223269222.00701',
      'max' => '1223270911.76639'
    },
    '-verbose' => '1',
    '-_done' => bless( {
      '-__intervals' => [
        [
          '1223270911.76639',
          '1223256470.41935'
        ]
      ]
    }, 'File::Rsync::Mirror::Recentfile::Done' ),
    '-have_mirrored' => '1223271134.78303',
    '-_interval' => 'Z',
    '-protocol' => '1'
  }, 'File::Rsync::Mirror::Recentfile' );
    my $rfile = $rf->_my_current_rfile ();
    ok $rfile, "Could determine the current rfile[$rfile]";
    my $re = $rf->recent_events;
    my $cnt = scalar @$re;
    ok $cnt, "re have more than one[$cnt] elements";
    my $done = $rf->done;
    ok $done->covered ($re->[0]{epoch},$re->[-1]{epoch}), "covered I";
    $rf->update("t/ta/id/M/MS/MSIMERSON/Mail-Toaster-5.12_01.tar.gz","new");
    $rf->update("t/ta/id/M/MS/MSIMERSON/Mail-Toaster-5.12_01.readme","new");
    my $re2 = $rf->recent_events;
    $done->register($re2, [0,1]);
    ok $done->covered ($re2->[0]{epoch},$re2->[-1]{epoch}), "covered II";
}

{
    my @lines;
    BEGIN {
        @lines = split /\n/, <<EOL;
40:        [45,40],        [40,35]
40:        [45,40],[42,37],[40,35]
40:        [45,40],[42,37],[40,35],[2,1]
40:[99,98],[45,40],[42,37],[40,35],[2,1]
45:        [45,40],        [45,35]
45:        [45,40],[42,37],[45,35]
45:        [45,40],[42,37],[45,35],[2,1]
45:[99,98],[45,40],[42,37],[45,35],[2,1]
35:        [45,35],        [40,35]
35:        [45,35],[42,37],[40,35]
35:        [45,35],[42,37],[40,35],[2,1]
35:[99,98],[45,35],[42,37],[40,35],[2,1]
EOL
        $tests += 3*@lines;
    }
    for my $line (@lines) {
        my($epoch,$perl) = $line =~ /^(\d+):(.+)/;
        my @intervals = eval $perl;
        my $done = File::Rsync::Mirror::Recentfile::Done->new;
        $done->_register_one_fold2(\@intervals,$epoch);
        my($n,$i) = (1,0);
        if ($intervals[-1][0]==2) {
            $n++;
        }
        if ($intervals[0][0]==99) {
            $n++;
            $i++;
        }
        ok $n==@intervals, "n $n line $line";
        ok 45==$intervals[$i][0], "i $i line $line => $intervals[$i][0]";
        ok 35==$intervals[$i][1], "i $i line $line => $intervals[$i][1]";
    }
}

rmtree ( "t/ta" );

BEGIN { plan tests => $tests }

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:
