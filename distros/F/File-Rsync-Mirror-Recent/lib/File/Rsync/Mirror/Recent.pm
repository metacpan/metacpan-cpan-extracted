package File::Rsync::Mirror::Recent;

# use warnings;
use strict;
use File::Rsync::Mirror::Recentfile;

=encoding utf-8

=head1 NAME

File::Rsync::Mirror::Recent - mirroring via rsync made efficient

=cut

package File::Rsync::Mirror::Recent;

use File::Basename qw(basename dirname fileparse);
use File::Copy qw(cp);
use File::Path qw(mkpath);
use File::Rsync;
use File::Rsync::Mirror::Recentfile::Done (); # at least needed by thaw()
use File::Rsync::Mirror::Recentfile::FakeBigFloat qw(:all);
use File::Temp;
use List::Pairwise qw(mapp grepp);
use List::Util qw(first max);
use Scalar::Util qw(blessed reftype);
use Storable;
use Time::HiRes qw();
use YAML::Syck;

use version; our $VERSION = qv('0.4.3');

=head1 SYNOPSIS

The documentation in here is normally not needed because the code is
considered to be run from several standalone programs. For a quick
overview, see the file README.mirrorcpan and the bin/ directory of the
distribution. For the architectural ideas see the section THE
ARCHITECTURE OF A COLLECTION OF RECENTFILES below.

File::Rsync::Mirror::Recent establishes a view on a collection of
File::Rsync::Mirror::Recentfile objects and provides abstractions
spanning multiple time intervals associated with those.

=head1 EXPORT

No exports.

=head1 CONSTRUCTORS

=head2 my $obj = CLASS->new(%hash)

Constructor. On every argument pair the key is a method name and the
value is an argument to that method name.

=cut

sub new {
    my($class, @args) = @_;
    my $self = bless {}, $class;
    while (@args) {
        my($method,$arg) = splice @args, 0, 2;
        $self->$method($arg);
    }
    return $self;
}

=head2 my $obj = CLASS->thaw($statusfile)

Constructor from a statusfile left over from a previous
rmirror run. See also C<runstatusfile>.

=cut

sub _thaw_without_pathdb {
    my($self,$file) = @_;
    open my $fh, $file or die "Can't open '$file': $!";
    local $/ = "\n";
    my $in_pathdb = 0;
    my $tfile = File::Temp->new
        (
         TEMPLATE => "Recent-thaw-XXXX",
         TMPDIR => 1,
         UNLINK => 0,
         CLEANUP => 0,
         SUFFIX => '.dat',
        );
    my $template_for_eop;
    while (<$fh>) {
        if ($in_pathdb) {
            if (/$template_for_eop/) {
                $in_pathdb = 0;
            }
        } elsif (/(\s+)-\s*__pathdb\s*:/) {
            $in_pathdb = 1;
            my $next_attr = sprintf "^%s\\S", " ?" x length($1);
            $template_for_eop = qr{$next_attr};
        }
        print $tfile $_ unless $in_pathdb;
    }
    close $tfile or die "Could not close: $!";
    my $return = $self->thaw($tfile->filename);
    $return->_havelostpathdb(1);
    unlink $tfile->filename;
    return $return;
}
sub thaw {
    my($self, $file) = @_;
    die "thaw called without statusfile argument" unless defined $file;
    unless (-e $file){
        require Carp;
        Carp::confess("Alert: statusfile '$file' not found");
    }
    require YAML::Syck;
    my $start = time;
    my $sleeptime = 0.02;
    while (not mkdir "$file.lock") {
        my $err = $!;
        Time::HiRes::sleep $sleeptime;
        my $waiting = time - $start;
        if ($waiting >= 3){
            warn "*** waiting ($waiting) for lock ($err) ***";
            $sleeptime = 1;
        }
    }
    my $size = -s $file;
    my $serialized = YAML::Syck::LoadFile($file);
    rmdir "$file.lock" or die "Could not rmdir lockfile: $!";
    my $charged_self = $serialized->{reduced_self};
    my $class = blessed $self;
    bless $charged_self, $class;
    my $rfs = $serialized->{reduced_rfs};
    my $rfclass = $class . "file"; # "Recent" . "file"
    my $pathdb = $charged_self->_pathdb;
    for my $rf (@$rfs) {
        bless $rf, $rfclass;
        $rf->_pathdb($pathdb);
    }
    $charged_self->_recentfiles($rfs);
    $charged_self->_principal_recentfile($rfs->[0]);
    # die "FIXME: thaw all recentfiles from reduced_rfs into _recentfiles as well, watch out for pathdb and rsync";
    return $charged_self;
}

=head1 ACCESSORS

=cut

my @accessors;

BEGIN {
    @accessors =
        (
         "__pathdb",
         "_dirtymark",            # keeps track of the dirtymark of the recentfiles
         "_havelostpathdb",       # boolean
         "_have_written_statusfile", # boolean
         "_logfilefordone",       # turns on _logfile on all DONE
                                  # systems (disk intensive)
         "_max_one_state",        # when we have no time left but want
                                  # at least get one file per
                                  # iteration to avoid procrastination
         "_principal_recentfile",
         "_recentfiles",
         "_rsync",
         "_runstatusfile",        # occasionally dumps all rfs
         "_verbose",              # internal variable for verbose setter/getter
         "_verboselog",           # internal variable for verboselog setter/getter
        );

    my @pod_lines =
        split /\n/, <<'=cut'; push @accessors, grep {s/^=item\s+//} @pod_lines; }

=over 4

=item ignore_link_stat_errors

as in F:R:M:Recentfile

=item local

Option to specify the local principal file for operations with a local
collection of recentfiles.

=item localroot

as in F:R:M:Recentfile

=item max_files_per_connection

as in F:R:M:Recentfile

=item remote

The remote principal recentfile in rsync notation. E.g.

  pause.perl.org::authors/RECENT.recent

=item remoteroot

as in F:R:M:Recentfile

=item remote_recentfile

Rsync address of the remote C<RECENT.recent> symlink or whichever name
the principal remote recentfile has.

=item rsync_options

Things like compress, links, times or checksums. Passed in to the
File::Rsync object used to run the mirror. Can be a hashref or an
arrayref. Depending on the version of File::Rsync it is passed on as a
hashref or as a flat list.

=item tempdir

as in F:R:M:Recentfile

=item ttl

Minimum time before fetching the principal recentfile again.

=back

=cut

use accessors @accessors;

=head1 METHODS

=head2 $arrayref = $obj->news ( %options )

Test this with:

  perl -Ilib bin/rrr-news \
       -after 1217200539 \
       -max 12 \
       -local /home/ftp/pub/PAUSE/authors/RECENT.recent

  perl -Ilib bin/rrr-news \
       -after 1217200539 \
       -rsync=compress=1 \
       -rsync=links=1 \
       -localroot /home/ftp/pub/PAUSE/authors/ \
       -remote pause.perl.org::authors/RECENT.recent
       -verbose

All parameters that can be passed to
File:Rsync:Mirror:Recentfile::recent_events() can also be specified
here.

One additional option is supported. If C<$Options{callback}> is
specified, it must be a subref. This sub is called whenever one chunk
of events is found. The first argument to the callback is a reference
to the currently accumulated array of events.

Note: all data are kept in memory.

=cut

sub news {
    my($self, %opt) = @_;
    my $local = $self->local;
    unless ($local) {
        if (my $remote = $self->remote) {
            my $localroot;
            if ($localroot = $self->localroot) {
                # nice, they know what they are doing
            } else {
                die "FIXME: remote called without localroot should trigger File::Temp.... TBD, sorry";
            }
        } else {
            die "Alert: neither local nor remote specified, cannot continue";
        }
    }
    my $rfs = $self->recentfiles;
    my $ret = [];
    my $before;
    for my $rf (@$rfs) {
        my %locopt = %opt;
        $locopt{before} = $before;
        if ($opt{max}) {
            $locopt{max} -= scalar @$ret;
            last if $locopt{max} <= 0;
        }
        $locopt{info} = {};
        my $res = $rf->recent_events(%locopt);
        if (@$res){
            push @$ret, @$res;
        }
        if ($opt{max} && scalar @$ret > $opt{max}) {
            last;
        }
        if ($opt{after}){
            if ( $locopt{info}{last} && _bigfloatlt($locopt{info}{last}{epoch},$opt{after}) ) {
                last;
            }
            if ( _bigfloatgt($opt{after},$locopt{info}{first}{epoch}) ) {
                last;
            }
        }
        if (!@$res){
            next;
        }
        $before = $res->[-1]{epoch};
        $before = $opt{before} if $opt{before} && _bigfloatlt($opt{before},$before);
        if (my $sub = $opt{callback}) {
            $sub->($ret);
        }
    }
    $ret;
}

=head2 overview ( %options )

returns a small table that summarizes the state of all recentfiles
collected in this Recent object.

$options{verbose}=1 increases the number of columns displayed.

Here is an example output:

 Ival   Cnt           Max           Min       Span   Util          Cloud
   1h    47 1225053014.38 1225049650.91    3363.47  93.4% ^  ^
   6h   324 1225052939.66 1225033394.84   19544.82  90.5%  ^   ^
   1d   437 1225049651.53 1224966402.53   83248.99  96.4%   ^    ^
   1W  1585 1225039015.75 1224435339.46  603676.29  99.8%     ^    ^
   1M  5855 1225017376.65 1222428503.57 2588873.08  99.9%       ^    ^
   1Q 17066 1224578930.40 1216803512.90 7775417.50 100.0%         ^   ^
   1Y 15901 1223966162.56 1216766820.67 7199341.89  22.8%           ^  ^
    Z  9909 1223966162.56 1216766820.67 7199341.89      -           ^  ^

I<Max> is the name of the interval.

I<Cnt> is the number of entries in this recentfile.

I<Max> is the highest(first) epoch in this recentfile, rounded.

I<Min> is the lowest(last) epoch in this recentfile, rounded.

I<Span> is the timespan currently covered, rounded.

I<Util> is I<Span> devided by the designated timespan of this
recentfile.

I<Cloud> is ascii art illustrating the sequence of the Max and Min
timestamps.

=cut
sub overview {
    my($self,%options) = @_;
    my $rfs = $self->recentfiles;
    my(@s,%rank);
  RECENTFILE: for my $rf (@$rfs) {
        my $re=$rf->recent_events;
        my $rfsummary;
        if (@$re) {
            my $span = $re->[0]{epoch}-$re->[-1]{epoch};
            my $merged = $rf->merged;
            $rfsummary =
                [
                 "Ival",
                 $rf->interval,
                 "Cnt",
                 scalar @$re,
                 "Dirtymark",
                 $rf->dirtymark ? sprintf("%.2f",$rf->dirtymark) : "-",
                 "Produced",
                 sprintf ("%.2f", $rf->{ORIG}{Producers}{time}||0),
                 "Merged",
                 ($rf->interval eq "Z"
                  ?
                  "-"
                  :
                  sprintf ("%.2f", $merged->{epoch} || 0)),
                 "Max",
                 sprintf ("%.2f", $re->[0]{epoch}),
                 "Min",
                 sprintf ("%.2f", $re->[-1]{epoch}),
                 "Span",
                 sprintf ("%.2f", $span),
                 "Util", # u9n:)
                 ($rf->interval eq "Z"
                  ?
                  "-"
                  :
                  sprintf ("%5.1f%%", 100 * $span / $rf->interval_secs)
                 ),
                ];
            @rank{mapp {$b} grepp {$a =~ /^(Max|Min)$/} @$rfsummary} = ();
        } else {
            next RECENTFILE;
        }
        push @s, $rfsummary;
    }
    @rank{sort {$b <=> $a} keys %rank} = 1..keys %rank;
    my $maxrank = max values %rank;
    for my $rfsummary (@s) {
        my $string = " " x $maxrank;
        my @borders;
        for my $ele (qw(Max Min)) {
            my($r) = mapp {$b} grepp {$a eq $ele} @$rfsummary;
            push @borders, $rank{$r}-1;
        }
        for ($borders[0],$borders[1]) {
            substr($string,$_,1) = "^";
        }
        push @$rfsummary, "Cloud", $string;
    }
    unless ($options{verbose}) {
        my %filter = map {($_=>1)} qw(Ival Cnt Max Min Span Util Cloud);
        for (@s) {
            $_ = [mapp {($a,$b)} grepp {!!$filter{$a}} @$_];
        }
    }
    my @sprintf;
    for  (my $i = 0; $i <= $#{$s[0]}; $i+=2) {
        my $maxlength = max ((map { length $_->[$i+1] } @s), length $s[0][$i]);
        push @sprintf, "%" . $maxlength . "s";
    }
    my $sprintf = join " ", @sprintf;
    $sprintf .= "\n";
    my $headline = sprintf $sprintf, mapp {$a} @{$s[0]};
    join "", $headline, map { sprintf $sprintf, mapp {$b} @$_ } @s;
}

=head2 _pathdb

Keeping track of already handled files. Currently it is a hash, will
probably become a database with its own accessors.

=cut

sub _pathdb {
    my($self, $set) = @_;
    if ($set) {
        $self->__pathdb ($set);
    }
    my $pathdb = $self->__pathdb;
    unless (defined $pathdb) {
        $self->__pathdb(+{});
    }
    return $self->__pathdb;
}

=head2 $recentfile = $obj->principal_recentfile ()

returns the principal recentfile object of this tree.

=cut
# mirrors the recentfile and instantiates the recentfile object
sub _principal_recentfile_fromremote {
    my($self) = @_;
    # get the remote recentfile
    my $rrfile = $self->remote or die "Alert: cannot construct a recentfile object without the 'remote' attribute";
    my $splitter = qr{(.+)/([^/]*)};
    my($remoteroot,$rfilename) = $rrfile =~ $splitter;
    $self->remoteroot($remoteroot);
    my($abslfile, $fh);
    if (!defined $rfilename) {
        die "Alert: Cannot resolve '$rrfile', does not match $splitter";
    } elsif (not length $rfilename or $rfilename eq "RECENT.recent") {
        ($abslfile,$rfilename,$fh) = $self->_principal_recentfile_fromremote_resosymlink($rfilename);
    }
    my @need_args =
        (
         "ignore_link_stat_errors",
         "localroot",
         "max_files_per_connection",
         "remoteroot",
         "rsync_options",
         "tempdir",
         "ttl",
         "verbose",
         "verboselog",
        );
    my $rf0;
    unless ($abslfile) {
        $rf0 = File::Rsync::Mirror::Recentfile->new (map {($_ => $self->$_)} @need_args);
        $rf0->split_rfilename($rfilename);
        $abslfile = $rf0->get_remote_recentfile_as_tempfile ();
    }
    $rf0 = File::Rsync::Mirror::Recentfile->new_from_file ( $abslfile );
    $rf0->_current_tempfile ( $abslfile );
    $rf0->_current_tempfile_fh ( $fh );
    $rf0->_use_tempfile (1);
    for my $override (@need_args) {
        $rf0->$override ( $self->$override );
    }
    $rf0->is_slave (1);
    return $rf0;
}
sub principal_recentfile {
    my($self) = @_;
    my $rf0 = $self->_principal_recentfile;
    return $rf0 if defined $rf0;
    my $local = $self->local;
    if ($local) {
        $rf0 = File::Rsync::Mirror::Recentfile->new_from_file ($local);
    } else {
        if (my $remote = $self->remote) {
            my $localroot;
            if ($localroot = $self->localroot) {
                # nice, they know what they are doing
            } else {
                die "FIXME: remote called without localroot should trigger File::Temp.... TBD, sorry";
            }
            $rf0 = $self->_principal_recentfile_fromremote;
        } else {
            die "Alert: neither local nor remote specified, cannot continue";
        }
    }
    $self->_principal_recentfile($rf0);
    return $rf0;
}

=head2 $recentfiles_arrayref = $obj->recentfiles ()

returns a reference to the complete list of recentfile objects that
describe this tree. No guarantee is given that the represented
recentfiles exist or have been read. They are just bare objects.

=cut

sub recentfiles {
    my($self) = @_;
    my $rfs        = $self->_recentfiles;
    return $rfs if defined $rfs;
    my $rf0        = $self->principal_recentfile;
    my $pathdb     = $self->_pathdb;
    $rf0->_pathdb ($pathdb);
    my $aggregator = $rf0->aggregator;
    my @rf         = $rf0;
    for my $agg (@$aggregator) {
        my $nrf = $rf0->_sparse_clone;
        $nrf->interval      ( $agg );
        $nrf->have_mirrored ( 0    );
        $nrf->_pathdb       ( $pathdb  );
        push @rf, $nrf;
    }
    $self->_recentfiles(\@rf);
    return \@rf;
}

=head2 $success = $obj->rmirror ( %options )

Mirrors all recentfiles of the I<remote> address working through all
of them, mirroring their contents.

Test this with:

  use File::Rsync::Mirror::Recent;
  my $rrr = File::Rsync::Mirror::Recent->new(
         ignore_link_stat_errors => 1,
         localroot => "/home/ftp/pub/PAUSE/authors",
         remote => "pause.perl.org::authors/RECENT.recent",
         max_files_per_connection => 5000,
         rsync_options => {
                           compress => 1,
                           links => 1,
                           times => 1,
                           checksum => 0,
                          },
         verbose => 1,
         _runstatusfile => "recent-rmirror-state.yml",
         _logfilefordone => "recent-rmirror-donelog.log",
  );
  $rrr->rmirror ( "skip-deletes" => 1, loop => 1 );

Or try without the loop parameter and write the loop yourself:

  use File::Rsync::Mirror::Recent;
  my @rrr;
  for my $t ("authors","modules"){
      my $rrr = File::Rsync::Mirror::Recent->new(
         ignore_link_stat_errors => 1,
         localroot => "/home/ftp/pub/PAUSE/$t",
         remote => "pause.perl.org::$t/RECENT.recent",
         max_files_per_connection => 512,
         rsync_options => {
                           compress => 1,
                           links => 1,
                           times => 1,
                           checksum => 0,
                          },
         verbose => 1,
         _runstatusfile => "recent-rmirror-state-$t.yml",
         _logfilefordone => "recent-rmirror-donelog-$t.log",
         ttl => 5,
      );
      push @rrr, $rrr;
  }
  while (){
    for my $rrr (@rrr){
      $rrr->rmirror ( "skip-deletes" => 1 );
    }
    warn "sleeping 23\n"; sleep 23;
  }


=cut
# _alluptodate is unused but at least it worked last time I needed it,
# so let us keep it around
sub _alluptodate {
    my($self) = @_;
    my $sdm = $self->_dirtymark;
    return unless defined $sdm;
    for my $rf (@{$self->recentfiles}) {
        return if $rf->seeded;
        my $rfdm = $rf->dirtymark;
        return unless defined $rfdm;
        return unless $rfdm eq $sdm;
        my $done = $rf->done;
        return unless defined $done;
        my $done_intervals = $done->_intervals;
        return if !defined $done_intervals;
        # nonono, may be more than one, only covered it must be:
        # return if @$done_intervals > 1;
        my $minmax = $rf->minmax;
        return unless defined $minmax;
        return unless $done->covered(@$minmax{qw(max min)});
    }
    # $DB::single++;
    return 1;
}
sub _fullseed {
    my($self) = @_;
    for ( @{$self->recentfiles} ) { $_->seed(1) }
}
sub rmirror {
    my($self, %options) = @_;

    my $rfs = $self->recentfiles;

    $self->principal_recentfile->seed;
    my $_sigint = sub {
        # XXX exit gracefully (reminder)
    };

    # XXX needs accessor: warning, if set too low, we do nothing but
    # mirror the principal!
    my $minimum_time_per_loop = 20;

    if (my $logfile = $self->_logfilefordone) {
        for my $i (0..$#$rfs) {
            $rfs->[$i]->done->_logfile($logfile);
        }
    }
    if (my $dirtymark = $self->principal_recentfile->dirtymark) {
        my $mydm = $self->_dirtymark;
        if (!defined $mydm){
            $self->_dirtymark($dirtymark);
        } elsif ($dirtymark ne $mydm) {
            if ($self->verbose) {
                my $fh;
                if (my $vl = $self->verboselog) {
                    open $fh, ">>", $vl or die "Could not open >> '$vl': $!";
                } else {
                    $fh = \*STDERR;
                }
                print $fh "NewDirtymark: old[$mydm] new[$dirtymark]\n";
            }
            $self->_dirtymark($dirtymark);
        }
    }
    my $rstfile = $self->runstatusfile;
    unless ($self->_have_written_statusfile) {
        $self->_rmirror_runstatusfile_write ($rstfile, \%options);
        $self->_have_written_statusfile(1);
    }
    $self->_rmirror_loop($minimum_time_per_loop,\%options);
}

sub _rmirror_loop {
    my($self,$minimum_time_per_loop,$options) = @_;
  LOOP: while () {
        my $ttleave = time + $minimum_time_per_loop;
        my $rstfile = $self->runstatusfile;
        my $otherproc = $self->_thaw_without_pathdb ($rstfile);
        my $pid = fork;
        if (! defined $pid) {
            warn "Contention: $!";
            sleep 0.25;
            next LOOP;
        } elsif ($pid) {
            waitpid($pid,0);
        } else {
            $self = $self->thaw ($rstfile);
            my $rfs = $self->recentfiles;
            $self->principal_recentfile->seed;
        RECENTFILE: for my $i (0..$#$rfs) {
                my $rf = $rfs->[$i];
                if (time > $ttleave) {
                    # Must make sure that one file can get fetched in any case
                    $self->_max_one_state(1);
                }
                if ($rf->seeded) {
                    $self->_rmirror_mirror ($i, $options);
                } elsif ($rf->uptodate) {
                    if ($i < $#$rfs) {
                        $rfs->[$i+1]->done->merge($rf->done);
                    }
                    # no further seed necessary because "periodic" does it
                    next RECENTFILE;
                }
            WORKUNIT: while (time < $ttleave) {
                    if ($rf->uptodate) {
                        $self->_rmirror_sleep_per_connection ($i);
                        next RECENTFILE;
                    } else {
                        $self->_rmirror_mirror ($i, $options);
                    }
                }
                if ($self->_max_one_state) {
                    last RECENTFILE;
                }
            }
            $self->_max_one_state(0);
            my $exit = 0;
            if ($rfs->[-1]->uptodate) {
                $self->_rmirror_cleanup;
            }
            unless ($options->{loop}) {
                $exit = 1;
            }
            $self->_rmirror_runstatusfile_write ($rstfile, $options);
            exit if $exit;
            last LOOP;
        }

        $otherproc = $self->_thaw_without_pathdb ($rstfile);
        if (!$options->{loop} && $otherproc && $otherproc->recentfiles->[-1]->uptodate) {
            last LOOP;
        }
        my $sleep = $ttleave - time;
        if ($sleep > 0.01) {
            $self->_rmirror_endofloop_sleep ($sleep);
        } else {
            # negative time not invented yet:)
        }
    }
}

sub _rmirror_mirror {
    my($self, $i, $options) = @_;
    my $rfs = $self->recentfiles;
    my $rf = $rfs->[$i];
    my %locopt = %$options;
    if ($self->_max_one_state) {
        $locopt{max} = 1;
    }
    $locopt{piecemeal} = 1;
    $rf->mirror (%locopt);
    if ($i==0) {
        # we limit to 0 for the case that upstream is broken and has
        # more than one timestamp (happened on PAUSE 200903)
        if (my $dirtymark = $rf->dirtymark) {
            my $mydm = $self->_dirtymark;
            if (!defined $mydm or $dirtymark ne $mydm) {
                $self->_dirtymark($dirtymark);
                $self->_fullseed;
            }
        }
    }
}

sub _rmirror_sleep_per_connection {
    my($self, $i) = @_;
    my $rfs = $self->recentfiles;
    my $rf = $rfs->[$i];
    my $sleep = $rf->sleep_per_connection;
    $sleep = 0.42 unless defined $sleep;
    Time::HiRes::sleep $sleep;
    $rfs->[$i+1]->done->merge($rf->done) if $i < $#$rfs;
}

sub _rmirror_cleanup {
    my($self) = @_;
    my $pathdb = $self->_pathdb();
    for my $k (keys %$pathdb) {
        delete $pathdb->{$k};
    }
    my $rfs = $self->recentfiles;
    for my $i (0..$#$rfs-1) {
        my $thismerged = $rfs->[$i]->merged;
        my $next = $rfs->[$i+1];
        my $nextminmax = $next->minmax;
        if (not defined $thismerged->{epoch} or _bigfloatlt($nextminmax->{max},$thismerged->{epoch})){
            $next->seed;
        }
    }
}

=head2 $file = $obj->runstatusfile ($set)

Getter/setter for C<_runstatusfile> attribute. Defaults to a temporary
file created by C<File::Temp>. A status file is required for
C<rmirror> working. Since it may be interesting for debugging
purposes, you may want to specify a permanent file for this.

=cut
sub runstatusfile {
    my($self,$set) = @_;
    if (defined $set) {
        $self->_runstatusfile ($set);
    }
    my $x = $self->_runstatusfile;
    unless (defined $x) {
        require File::Temp;
        my $tfile = File::Temp->new
            (
             TEMPLATE => "Recent-XXXX",
             TMPDIR => 1,
             UNLINK => 0,
             CLEANUP => 0,
             SUFFIX => '.dat',
            );
        $self->_runstatusfile($tfile->filename);
    }
    return $self->_runstatusfile;
}

# unused code.... it was an oops, discovered the thaw() method too
# late, and starting writing this here....
sub _rmirror_runstatusfile_read {
    my($self, $file) = @_;

    require YAML::Syck;
    my $start = time;
    # XXX is locking useful here?
    while (not mkdir "$file.lock") {
        Time::HiRes::sleep 0.2;
        warn "*** waiting for lock ***" if time - $start >= 3;
    }
    my $yml = YAML::Syck::LoadFile $file;
    rmdir "$file.lock" or die "Could not rmdir lockfile: $!";
    my $rself = $yml->{reduced_self};
    my $rfs = $yml->{reduced_rfs};
    # XXX bring them into self
}

sub _rmirror_runstatusfile_write {
    my($self, $file, $options) = @_;
    my $rself;
    while (my($k,$v) = each %$self) {
        next if $k =~ /^-(_principal_recentfile|_recentfiles)$/;
        $rself->{$k} = $v;
    }
    my $rfs = $self->recentfiles;
    my $rrfs;
    for my $i (0..$#$rfs) {
        my $rf = $rfs->[$i];
        while (my($k,$v) = each %$rf) {
            next if $k =~ /^-(_current_tempfile_fh|_pathdb|_rsync)$/;
            $rrfs->[$i]{$k} = $rfs->[$i]{$k};
        }
    }
    require YAML::Syck;
    my $start = time;
    while (not mkdir "$file.lock") {
        Time::HiRes::sleep 0.15;
        warn "*** waiting for lock directory '$file.lock' ***" if time - $start >= 3;
    }
    YAML::Syck::DumpFile
          (
           "$file.new",
           {
            options => $options,
            time => time,
            reduced_rfs => $rrfs,
            reduced_self => $rself,
           });
    rename "$file.new", $file or die "Could not rename: $!";
    rmdir "$file.lock" or die "Could not rmdir lockfile: $!";
}

sub _rmirror_endofloop_sleep {
    my($self, $sleep) = @_;
    if ($self->verbose) {
        my $fh;
        if (my $vl = $self->verboselog) {
            open $fh, ">>", $vl or die "Could not open >> '$vl': $!";
        } else {
            $fh = \*STDERR;
        }
        printf $fh
            (
             "Dorm %d (%s secs)\n",
             time,
             $sleep,
            );
    }
    sleep $sleep;
}

# it returns two things: abslfile and rfilename. But the abslfile is
# undef when the rfilename ends in .recent. A weird interface, my
# friend.
sub _principal_recentfile_fromremote_resosymlink {
    my($self, $rfilename) = @_;
    $rfilename = "RECENT.recent" unless length $rfilename;
    my $abslfile = undef;
    my $fh;
    if ($rfilename =~ /\.recent$/) {
        # may be a file *or* a symlink, 
        ($abslfile,$fh) = $self->_fetch_as_tempfile ($rfilename);
        while (-l $abslfile) {
            my $symlink = readlink $abslfile;
            if ($symlink =~ m|/|) {
                die "FIXME: filenames containing '/' not supported, got '$symlink'";
            }
            my $localrfile = File::Spec->catfile($self->localroot, $rfilename);
            if (-e $localrfile) {
                my $old_symlink = readlink $localrfile;
                if ($old_symlink eq $symlink) {
                    unlink $abslfile or die "Cannot unlink '$abslfile': $!";
                } else {
                    unlink $localrfile; # may fail
                    rename $abslfile, $localrfile or die "Cannot rename to '$localrfile': $!";
                }
            } else {
                rename $abslfile, $localrfile or die "Cannot rename to '$localrfile': $!";
            }
            ($abslfile,$fh) = $self->_fetch_as_tempfile ($symlink);
        }
    }
    return ($abslfile, $rfilename, $fh);
}

# takes a basename, returns an absolute name, does not delete the
# file, throws the $fh away. Caller must rename or unlink

# XXX needs to activate the fh in the rf0 so that it is able to unlink
# the file. I would like that the file is used immediately by $rf0
sub _fetch_as_tempfile {
    my($self, $rfile) = @_;
    my($suffix) = $rfile =~ /(\.[^\.]+)$/;
    $suffix = "" unless defined $suffix;
    my $fh = File::Temp->new
        (TEMPLATE => sprintf(".FRMRecent-%s-XXXX",
                             $rfile,
                            ),
         DIR => $self->tempdir || $self->localroot,
         SUFFIX => $suffix,
         UNLINK => 0,
        );
    my $rsync;
    my @rsync_options;
    if (my $rso = $self->rsync_options) {
        if (ref $rso eq "HASH") {
            @rsync_options = %$rso;
        } elsif (ref $rso eq "ARRAY") {
            @rsync_options = @$rso;
        }
    } else {
        @rsync_options = ();
    }
    if ($File::Rsync::VERSION <= 0.45) {
        $rsync = File::Rsync->new({@rsync_options});
    } else {
        $rsync = File::Rsync->new(@rsync_options);
    }
    unless ($rsync) {
        require Carp;
        Carp::confess(YAML::Syck::Dump($self->rsync_options));
    }
    my $dst = $fh->filename;
    local($ENV{LANG}) = "C";
    $rsync->exec
        (
         src => join("/",$self->remoteroot,$rfile),
         dst => $dst,
        ) or die "Could not mirror '$rfile' to $fh\: ".join(" ",$rsync->err);
    unless (-l $dst) {
        my $mode = 0644;
        chmod $mode, $dst or die "Could not chmod $mode '$dst': $!";
    }
    return($dst,$fh);
}

=head2 $verbose = $obj->verbose ( $set )

Getter/setter method to set verbosity for this F:R:M:Recent object and
all associated Recentfile objects.

=cut
sub verbose {
    my($self,$set) = @_;
    if (defined $set) {
        for ( @{$self->recentfiles} ) { $_->verbose($set) }
        $self->_verbose ($set);
    }
    my $x = $self->_verbose;
    unless (defined $x) {
        $x = 0;
        $self->_verbose ($x);
    }
    return $x;
    
}

=head2 my $vl = $obj->verboselog ( $set )

Getter/setter method for the path to the logfile to write verbose
progress information to.

Note: This is a primitive stop gap solution to get simple verbose
logging working. The program still sends error messages to STDERR.
Switching to Log4perl or similar is probably the way to go. TBD.

=cut
sub verboselog {
    my($self,$set) = @_;
    if (defined $set) {
        for ( @{$self->recentfiles} ) { $_->verboselog($set) }
        $self->_verboselog ($set);
    }
    my $x = $self->_verboselog;
    unless (defined $x) {
        $x = 0;
        $self->_verboselog ($x);
    }
    return $x;
}

=head1 THE ARCHITECTURE OF A COLLECTION OF RECENTFILES

The idea is that we want to have a short file that records really
recent changes. So that a fresh mirror can be kept fresh as long as
the connectivity is given. Then we want longer files that record the
history before. So when the mirror falls behind the update period
reflected in the shortest file, it can complement the list of recent
file events with the next one. And if this is not long enough we want
another one, again a bit longer. And we want one that completes the
history back to the oldest file. The index files together do contain
the complete list of current files. The longer a period covered by an
index file is gone the less often the index file is updated. For
practical reasons adjacent files will often overlap a bit but this is
neither necessary nor enforced. Enforced is only that there must not
ever be a gap between two adjacent index files that would have to
contain a file reference. That's the basic idea. The following example
represents a tree that has a few updates every day:

 RECENT.recent -> RECENT-1h.yaml
 RECENT-1h.yaml
 RECENT-6h.yaml
 RECENT-1d.yaml
 RECENT-1M.yaml
 RECENT-1W.yaml
 RECENT-1Q.yaml
 RECENT-1Y.yaml
 RECENT-Z.yaml

Each of these files represents a contract to hold a record for every
filesystem event within the period indicated in the filename.

The first file is the principal file, in so far it is the one that is
written first after a filesystem change. Usually a symlink links to it
with a filename that has the same filenameroot and the suffix
C<.recent>. On systems that do not support symlinks there is a plain
copy maintained instead.

The last file, the Z file, contains the complementary files that are
in none of the other files. It may contain C<delete> events but often
C<delete> events are discarded at the transition to the Z file.

=head2 SITE SEEING TOUR

This section illustrates the operation of a server-client couple in a
fictious installation that has to deal with a long time of inactivity.
I think such an edge case installation demonstrates the economic
behaviour of our model of overlapping time slices best.

The sleeping beauty (http://en.wikipedia.org/wiki/Sleeping_Beauty) is
a classic fairytale of a princess sleeping for a hundred years. The
story inspired the test case 02-aurora.t.

Given an upstream server where the people stop feeding new files for
one hundred years. That upstream server has no driving energy to do
major changes to its RECENT files. Cronjobs will continue to shift
things towards the Z file but soon will stop doing so since all of
them have to keep their promise to record files covering a certain
period. Soon all RECENT files will cover exactly their native period.

Downstream servers will stubbornly ask their question to the rsync
server whether there is a newer RECENT.recent. As soon as the smallest
RECENT file has reached the state of maximum possible merge with the
second smallest RECENT file, the answer of the rsync server will
always be: nothing new. And downstream servers that were uptodate on
the previous request will be satisfied and do nothing. Never will they
request a download. The answer that there is no change is sufficient
to determine that there is no change in the whole tree.

Let's presume the smallest RECENT file on this castle is a 1h file and
downstream decides to ask every 30 minutes. Now the hundred years are
over and upstream starts producing files again. One file every minute.
After one minute it will move old files over to the, say, 1d file. In
the next sixty minutes it will not be allowed to move any other file
over to the 1d file. At some point in time downstream will ask the
obligatory question "anything new?" and it will get the current 1h
file. It will recognize in the meta part of the current file which
timestamps have been moved to the 1d file, it will recognize that it
has all those. It will have no need to download the 1d file, it will
download the missing files and be done. No second RECENT file needs to
be downloaded.

Downstream only decides to download another RECENT file when not doing
so would result in a gap between two recent files. Such that
consistency checks would become impossible. Or for potentially
interested third parties, like down-down-stream servers.

Downloads of RECENT files are subject to rsync optimizations in that
rsync does some level of blockwise checksumming that is considered
efficient to avoid copying blocks of data that have not changed. Our
format is that of an ordered array, so that large blocks stay constant
when elements are prepended to the array. This means we usually do not
have to rsync full RECENT files. Only if they are really small, the
rsync algorithm will not come into play but that's OK for small files.

Upstream servers are extremely lazy in writing the larger files. See
File::Rsync::Mirror::Recentfile::aggregate() for the specs. Long
before the one hundred years are over, the upstream server will stop
changing files. Slowly everything that existed before upstream fell
asleep trickles into the Z file. Say, the second-largest RECENT file
is a 1Y file and the third-largest RECENT file is a 1Q file, then it
will take at least one quarter of a year that the 1Y file will be
merged into the Z file. From that point in time everything will have
been merged into the Z file and the server's job to call C<aggregate>
regularly will become a noop. Consequently downstream will never again
download anything. Just the obligatory question: anything new?

=head2 THE INDIVIDUAL RECENTFILE

A I<recentfile> consists of a hash that has two keys: C<meta> and
C<recent>. The C<meta> part has metadata and the C<recent> part has a
list of fileobjects.

=head2 THE META PART

Here we find things that are pretty much self explaining: all
lowercase attributes are accessors and as such explained in the
manpages. The uppercase attribute C<Producers> contains version
information about involved software components.

Even though the lowercase attributes are documented in the
F:R:M:Recentfile manpage, let's focus on the important stuff to make
sure nothing goes by unnoticed: meta contains the aggregator levels in
use in this installation, in other words the names of the RECENT
files, eg:

  aggregator:
    - 3s
    - 8s
    - 21s
    - 55s
    - Z

It contains a dirtymark telling us the timestamp of the last protocol
violation of the upstream server:

  dirtymark: '1325093856.49272'

Plus a few things convenient in a situation where we need to do some
debugging.

And it contains information about which timestamp is the maximum
timestamp in the neighboring file. This is probably the most important
data in meta:

  merged:
    epoch: 1307159461.94575

This keeps track of the highest epoch we would find if we looked into
the next RECENT file.

Another entry is the minmax, eg:

  minmax:
    max: 1307161441.97444
    min: 1307140103.70322

The merged/epoch and minmax examples above illustrate one case of an
overlap (130715... is between 130716... and 130714...). The syncing
strategy for the client is in general the imperative: if the interval
covered by a recentfile (minmax) and the interval covered by the next
higher recentfile (merged/epoch) do not overlap anymore, then it is
time to refresh the next recentfile.

=head2 THE RECENT PART

This is the interesting part. Every entry refers to some filesystem
change (with path, epoch, type).

The I<epoch> value is the point in time when some change was
I<registered> but can be set to arbitrary values. Do not be tempted to
believe that the entry has a direct relation to something like
modification time or change time on the filesystem level. They are not
reflecting release dates. (If you want exact release dates: Barbie is
providing a database of them. See
http://use.perl.org/~barbie/journal/37907).

All these entries can be devided into two types (denoted by the
I<type> attribute): C<new>s and C<delete>s. Changes and creations are
C<new>s. Deletes are C<delete>s.

Besides an I<epoch> and a I<type> attribute we find a third one:
I<path>. This path is relative to the directory we find the
I<recentfile> in.

The order of the entries in the I<recentfile> is by decreasing epoch
attribute. These are unique floating point numbers. When the server
has ntp running correctly, then the timestamps are usually reflecting
a real epoch. If time is running backwards, we trump the system epoch
with strictly monotonically increasing floating point timestamps and
guarantee they are unique.

=head1 CORRUPTION AND RECOVERY

If the origin host breaks the promise to deliver consistent and
complete I<recentfiles> then it must update its C<dirtymark> and all
slaves must discard what they cosider the truth.

In the worst case that something goes wrong despite the dirtymark
mechanism the way back to sanity can be achieved through traditional
rsyncing between the hosts. But please be wary doing that: mixing
traditional rsync and the F:R:M:R technique can lead to gratuitous
extra errors. If you're the last host in a chain, there's nobody you
can disturb, but if you have downstream clients, it is possible that
rsync copies a RECENT file before the contained files are actually
available.

=head1 BACKGROUND

This is about speeding up rsync operation on large trees. Uses a small
metadata cocktail and pull technology.

rersyncrecent solves this problem with a couple of (usually 2-10)
lightweight index files which cover different overlapping time
intervals. The master writes these files and the clients/slaves can
construct the full tree from the information contained in them. The
most recent index file usually covers the last seconds or minutes or
hours of the tree and depending on the needs, slaves can rsync every
few seconds or minutes and then bring their trees in full sync.

The rersyncrecent model was developed for CPAN but as it is both
convenient and economic it is also a general purpose solution. I'm
looking forward to see a CPAN backbone that is only a few seconds
behind PAUSE.

=head2 NON-COMPETITORS

 File::Mirror        JWU/File-Mirror/File-Mirror-0.10.tar.gz only local trees
 Mirror::YAML        ADAMK/Mirror-YAML-0.03.tar.gz           some sort of inner circle
 Net::DownloadMirror KNORR/Net-DownloadMirror-0.04.tar.gz    FTP sites and stuff
 Net::MirrorDir      KNORR/Net-MirrorDir-0.05.tar.gz         dito
 Net::UploadMirror   KNORR/Net-UploadMirror-0.06.tar.gz      dito
 Pushmi::Mirror      CLKAO/Pushmi-v1.0.0.tar.gz              something SVK

 rsnapshot           www.rsnapshot.org                       focus on backup
 csync               www.csync.org                           more like unison
 multi-rsync         sourceforge 167893                      lan push to many
 chasm               chasmd.org                              per-directory manifests

=head2 COMPETITORS

The problem to solve which clusters and ftp mirrors and otherwise
replicated datasets like CPAN share: how to transfer only a minimum
amount of data to determine the diff between two hosts.

Normally it takes a long time to determine the diff itself before it
can be transferred. Known solutions at the time of this writing are
csync2, and rsync 3 batch mode.

For many years the best solution was B<csync2> which solves the
problem by maintaining a sqlite database on both ends and talking a
highly sophisticated protocol to quickly determine which files to send
and which to delete at any given point in time. Csync2 is often
inconvenient because it is push technology and the act of syncing
demands quite an intimate relationship between the sender and the
receiver. This is hard to achieve in an environment of loosely coupled
sites where the number of sites is large or connections are unreliable
or network topology is changing.

B<Rsync 3 batch mode> works around these problems by providing
rsync-able batch files which allow receiving nodes to replay the
history of the other nodes. This reduces the need to have an
incestuous relation but it has the disadvantage that these batch files
replicate the contents of the involved files. This seems inappropriate
when the nodes already have a means of communicating over rsync.

=head2 HONORABLE MENTION

B<instantmirror> at https://fedorahosted.org/InstantMirror/ is an
ambitious project that tries to combine various technologies (squid,
bittorrent) to overcome the current slowness with the main focus on
fedora. It's been founded in 2009-03 and at the time of this writing
it is still a bit early to comment on.

=head1 LIMITATIONS

If the tree of the master server is changing faster than the bandwidth
permits to mirror then additional protocols may need to be deployed.
Certainly p2p/bittorrent can help in such situations because
downloading sites help each other and bittorrent chunks large files
into pieces.

=head1 INOTIFY

Currently the origin server has two options. The traditional one is to
strictly keep track of injected and removed files through all involved
processes and call C<update> on every file system event. The other
option is to let data come in and use the assistance of inotify. PAUSE
is running the former, the cpan master site is running the latter.
Both work equally well for CPAN because CPAN has not yet had any
problem with upload storms. On installations that have to deal with
more uploaded data than inotify+rrr can handle it's better to use the
traditional method such that the relevant processes can build up some
backpressure to throttle writing processes until we're ready to accept
the next data chunk.

=head1 FUTURE DIRECTIONS

Convince other users outside the CPAN like
http://fedoraproject.org/wiki/Infrastructure/Mirroring

=head1 SEE ALSO

L<File::Rsync::Mirror::Recentfile>,
L<File::Rsync::Mirror::Recentfile::Done>,
L<File::Rsync::Mirror::Recentfile::FakeBigFloat>

=head1 BUGS

Please report any bugs or feature requests through the web interface
at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Rsync-Mirror-Recent>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Rsync::Mirror::Recent

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Rsync-Mirror-Recent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Rsync-Mirror-Recent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Rsync-Mirror-Recent>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Rsync-Mirror-Recent>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to RJBS for module-starter.

=head1 AUTHOR

Andreas König

=head1 COPYRIGHT & LICENSE

Copyright 2008, 2009 Andreas König.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of File::Rsync::Mirror::Recent
