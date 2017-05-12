package File::Rsync::Mirror::Recentfile::Done;

# use warnings;
use strict;

use File::Rsync::Mirror::Recentfile::FakeBigFloat qw(:all);

=encoding utf-8

=head1 NAME

File::Rsync::Mirror::Recentfile::Done - intervals of already rsynced timespans

=cut

use version; our $VERSION = qv('0.0.8');

=head1 SYNOPSIS

 my $done = File::Rsync::Mirror::Recentfile::Done->new;
 $done->register ( $recent_events, [3,4,5,9] ); # registers elements 3-5 and 9
 my $boolean = $done->covered ( $epoch );

=head1 DESCRIPTION

Keeping track of already rsynced timespans.

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

=head1 ACCESSORS

=cut

my @accessors;

BEGIN {
    @accessors = (
                  "__intervals",
                  "_logfile", # undocced: a small yaml dump appended on every change
                  "_rfinterval", # undocced: the interval of the holding rf
                 );

    my @pod_lines =
        split /\n/, <<'=cut'; push @accessors, grep {s/^=item\s+//} @pod_lines; }

=over 4

=item verbose

Boolean to turn on a bit verbosity.

=back

=cut

use accessors @accessors;

=head1 METHODS

=head2 $boolean = $obj->covered ( $epoch1, $epoch2 )

=head2 $boolean = $obj->covered ( $epoch )

The first form returns true if both timestamps $epoch1 and $epoch2 in
floating point notation have been registered within one interval,
otherwise false.

The second form returns true if this timestamp has been registered.

=cut
sub _is_sorted {
    my($self,$ivs) = @_;
    my $Lup;
    my $is_sorted = 1;
    for my $i (0..$#$ivs) {
        if (defined $Lup) {
            if (_bigfloatge ($ivs->[$i][0],$Lup)) {
                warn "Warning (may be harmless): F:R:M:R:Done object contains unsorted internal data";
                $DB::single++;
                return 0;
            }
        }
        $Lup = $ivs->[$i][0];
    }
    return $is_sorted;
}
sub covered {
    my($self, $epoch_high, $epoch_low) = @_;
    die "Alert: covered() called without or with undefined first argument" unless defined $epoch_high;
    my $intervals = $self->_intervals;
    return unless @$intervals;
    if (defined $epoch_low) {
        ($epoch_high,$epoch_low) = ($epoch_low,$epoch_high) if _bigfloatgt($epoch_low,$epoch_high);
    }
    my $is_sorted = $self->_is_sorted($intervals);
    for my $iv (@$intervals) {
        my($upper,$lower) = @$iv; # may be the same
        if (defined $epoch_low) {
            my $goodbound = 0;
            for my $e ($epoch_high,$epoch_low) {
                $goodbound++ if
                    $e eq $upper || $e eq $lower || (_bigfloatlt($e,$upper) && _bigfloatgt($e,$lower));
            }
            return 1 if $goodbound > 1;
        } else {
            if ( _bigfloatle ( $epoch_high, $upper ) ) {
                if ( _bigfloatge ( $epoch_high, $lower )) {
                    return 1; # "between"
                }
            } elsif ($is_sorted) {
                return 0; # no chance anymore
            }
        }
    }
    return 0;
}

=head2 (void) $obj1->merge ( $obj2 )

Integrates all intervals in $obj2 into $obj1. Overlapping intervals
are conflated/folded/consolidated. Sort order is preserved as decreasing.

=cut
sub merge {
    my($self, $other) = @_;
    my $intervals = $self->_intervals;
    my $ointervals = $other->_intervals;
  OTHER: for my $oiv (@$ointervals) {
        my $splicepos;
        if (@$intervals) {
          SELF: for my $i (0..$#$intervals) {
                my $iv = $intervals->[$i];
                if ( _bigfloatlt ($oiv->[0],$iv->[1]) ) {
                    # both oiv lower than iv => next
                    next SELF;
                }
                if ( _bigfloatgt ($oiv->[1],$iv->[0]) ) {
                    # both oiv greater than iv => insert
                    $splicepos = $i;
                    last SELF;
                }
                # larger(left-iv,left-oiv) becomes left, smaller(right-iv,right-oiv) becomes right
                $iv->[0] = _bigfloatmax ($oiv->[0],$iv->[0]);
                $iv->[1] = _bigfloatmin ($oiv->[1],$iv->[1]);
                next OTHER;
            }
            unless (defined $splicepos) {
                if ( _bigfloatlt ($oiv->[0], $intervals->[-1][1]) ) {
                    $splicepos = @$intervals;
                } else {
                    die "Panic: left-oiv[$oiv->[0]] should be smaller than smallest[$intervals->[-1][1]]";
                }
            }
            splice @$intervals, $splicepos, 0, [@$oiv];
        } else {
            $intervals->[0] = [@$oiv];
        }
    }
}

=head2 (void) $obj->register ( $recent_events_arrayref, $register_arrayref )

=head2 (void) $obj->register ( $recent_events_arrayref )

The first arrayref is a list of hashes that contain a key called
C<epoch> which is a string looking like a number. The second arrayref
is a list if integers which point to elements in the first arrayref to
be registered.

The second form registers all events in $recent_events_arrayref.

=cut

sub register {
    my($self, $re, $reg) = @_;
    my $intervals = $self->_intervals;
    unless ($reg) {
        $reg = [0..$#$re];
    }
  REGISTRANT: for my $i (@$reg) {
        my $logfile = $self->_logfile;
        if ($logfile) {
            require YAML::Syck;
            open my $fh, ">>", $logfile or die "Could not open '$logfile': $!";
            print $fh YAML::Syck::Dump({
                                        At => "before",
                                        Brfinterval => $self->_rfinterval,
                                        Ci => $i,
                                        ($i>0 ? ("Dre-1" => $re->[$i-1]) : ()),
                                        "Dre-0" => $re->[$i],
                                        ($i<$#$re ? ("Dre+1" => $re->[$i+1]) : ()),
                                        Eintervals => $intervals,
                                       });
        }
        $self->_register_one
            ({
              i => $i,
              re => $re,
              intervals => $intervals,
             });
        if ($logfile) {
            require YAML::Syck;
            open my $fh, ">>", $logfile or die "Could not open '$logfile': $!";
            print $fh YAML::Syck::Dump({
                                        At => "after",
                                        intervals => $intervals,
                                       });
        }
    }
}

sub _register_one {
    my($self, $one) = @_;
    my($i,$re,$intervals) = @{$one}{qw(i re intervals)};
    die sprintf "Panic: illegal i[%d] larger than number of events[%d]", $i, $#$re
        if $i > $#$re;
    my $epoch = $re->[$i]{epoch};
    return if $self->covered ( $epoch );
    if (@$intervals) {
        my $registered = 0;
    IV: for my $iv (@$intervals) {
            my($ivhi,$ivlo) = @$iv; # may be the same
            if ($i > 0
                && _bigfloatge($re->[$i-1]{epoch}, $ivlo)
                && _bigfloatle($re->[$i-1]{epoch}, $ivhi)
                && _bigfloatge($iv->[1],$epoch)
               ) {
                # if left neighbor in re belongs to this interval,
                # then I belong to it too; let us lower the ivlo
                $iv->[1] = $epoch;
                $registered++;
            }
            if ($i < $#$re
                && _bigfloatle($re->[$i+1]{epoch}, $ivhi)
                && _bigfloatge($re->[$i+1]{epoch}, $ivlo)
                && _bigfloatle($iv->[0],$epoch)
               ) {
                # ditto for right neighbor; increase the ivhi
                $iv->[0] = $epoch;
                $registered++;
            }
            last IV if $registered>=2;
        }
        if ($registered == 2) {
            $self->_register_one_fold2
                (
                 $intervals,
                 $epoch,
                );
        } elsif ($registered == 1) {
            $self->_register_one_fold1 ($intervals);
        } else {
            $self->_register_one_fold0
                (
                 $intervals,
                 $epoch,
                );
        }
    } else {
        $intervals->[0] = [($epoch)x2];
    }
}

sub _register_one_fold0 {
    my($self,
       $intervals,
       $epoch,
      ) = @_;
    my $splicepos;
    for my $i (0..$#$intervals) {
        if (_bigfloatgt ($epoch, $intervals->[$i][0])) {
            $splicepos = $i;
            last;
        }
    }
    unless (defined $splicepos) {
        if (_bigfloatlt ($epoch,   $intervals->[-1][1])) {
            $splicepos = @$intervals;
        } else {
            die "Panic: epoch[$epoch] should be smaller than smallest[$intervals->[-1][1]]";
        }
    }
    splice @$intervals, $splicepos, 0, [($epoch)x2];
}

# conflate: eliminate overlapping intervals
sub _register_one_fold1 {
    my($self,$intervals) = @_;
 LOOP: while () {
        my $splicepos;
        for my $i (0..$#$intervals-1) {
            if (_bigfloatle ($intervals->[$i][1],
                             $intervals->[$i+1][0])) {
                $intervals->[$i+1][0] = $intervals->[$i][0];
                $splicepos = $i;
                last;
            }
        }
        if (defined $splicepos) {
            splice @$intervals, $splicepos, 1;
        } else {
            last LOOP;
        }
    }
}

sub _register_one_fold2 {
    my($self,
       $intervals,
       $epoch,
      ) = @_;
    # we know we have hit twice, like in
    # 40:[45,40],        [40,35]
    # 40:[45,40],[42,37],[40,35]
    # 45:[45,40],        [45,35]
    # 45:[45,40],[42,37],[45,35]
    # 35:[45,35],        [40,35]
    # 35:[45,35],[42,37],[40,35]
    my($splicepos, $splicelen, %assert_between);
 INTERVAL: for my $i (0..$#$intervals) {
        if (   $epoch eq $intervals->[$i][0]
            or $epoch eq $intervals->[$i][1]
           ) {
            for (my $j = 1; $i+$j <= $#$intervals; $j++) {
                if (   $epoch eq $intervals->[$i+$j][0]
                    or $epoch eq $intervals->[$i+$j][1]) {
                    $intervals->[$i+$j][0] = _bigfloatmax($intervals->[$i][0],$intervals->[$i+$j][0]);
                    $intervals->[$i+$j][1] = _bigfloatmin($intervals->[$i][1],$intervals->[$i+$j][1]);
                    $splicepos = $i;
                    $splicelen = $j;
                    last INTERVAL;
                } else {
                    for my $k (0,1) {
                        $assert_between{$intervals->[$i+$j][$k]}++;
                    }
                }
            }
        }
    }
    if (defined $splicepos) {
        for my $k (keys %assert_between) {
            if (_bigfloatgt($k,$intervals->[$splicepos+$splicelen][0])
                or _bigfloatlt($k,$intervals->[$splicepos+$splicelen][1])){
                $DB::single=1;
                require Data::Dumper;
                die "Panic: broken intervals:".Data::Dumper::Dumper($intervals);
            }
        }
        splice @$intervals, $splicepos, $splicelen;
    } else {
        $DB::single=1;
        die "Panic: Could not find an interval position to insert '$epoch'";
    }
}

=head2 reset

Forgets everything ever done and gives way for a new round of
mirroring. Usually called when the dirtymark on upstream has changed.

=cut

sub reset {
    my($self) = @_;
    $self->_intervals(undef);
}

=head1 PRIVATE METHODS

=head2 _intervals

=cut
sub _intervals {
    my($self,$set) = @_;
    if (@_ >= 2) {
        $self->__intervals($set);
    }
    my $x = $self->__intervals;
    unless (defined $x) {
        $x = [];
        $self->__intervals ($x);
    }
    return $x;
}

=head1 COPYRIGHT & LICENSE

Copyright 2008, 2009 Andreas König.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of File::Rsync::Mirror::Recentfile

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:
