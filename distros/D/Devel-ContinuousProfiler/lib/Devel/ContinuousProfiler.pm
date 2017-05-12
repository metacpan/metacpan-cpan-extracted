package Devel::ContinuousProfiler;
# ABSTRACT: Ultra cheap profiling for use in production environments

use strict;
## no critic (UseWarnings, DotMatchAnything, NoCritic, NewLines, InterpolationOfMetachars))

use English '-no_match_vars';

use XSLoader;
use constant _COUNT  => 0;
use constant _DEEPER => 1;

use constant _FILE => 2;
use constant _FUNC => 3;

our %DATA;
our $LAST_TIME_REPORT = 0;
our $FRAME_FORMAT;
our $FRAME_FORMAT2;
our $OUTPUT_HANDLE;
our $OUTPUT_SEEKABLE;
our $VERSION = '0.12';

XSLoader::load(__PACKAGE__, $VERSION);

if ($ENV{PROFILER}) {
    my %args = map { split /=/, $_, 2 } split /,/, $ENV{PROFILER};
    if ($args{file}) {
        output_filename( $args{file} );
    }
    if ($args{frame_format}) {
        $FRAME_FORMAT = $args{frame_format};
    }
    if ($args{frame_format2}) {
        $FRAME_FORMAT2 = $args{frame_format2};
    }
}
$OUTPUT_HANDLE = \ *STDERR unless defined $OUTPUT_HANDLE;
$FRAME_FORMAT  = '%' . (1+_FUNC) . '$s' unless defined $FRAME_FORMAT;
$FRAME_FORMAT2 = '%' . (1+_FILE) . '$s' unless defined $FRAME_FORMAT2;

END { report() }

sub frame_format {
    if (@_) {
        return ( $FRAME_FORMAT, $FRAME_FORMAT2 ) = @_;
    }
    else {
        return ( $FRAME_FORMAT, $FRAME_FORMAT2 );
    }
}

sub output_handle {
    if (@_) {
        $OUTPUT_SEEKABLE = 1;
        return $OUTPUT_HANDLE = shift;
    }
    else {
        return ($OUTPUT_HANDLE, $OUTPUT_SEEKABLE);
    }
}

sub output_filename {
    my ( $file ) = @_;

    if ($file) {
        ## no critic (InputOutput::RequireBriefOpen)
        $OUTPUT_SEEKABLE = 0;
        open $OUTPUT_HANDLE, '>', $file
            or do {
                warn "Can't open $file: $ERRNO";
                return;
            };
        $OUTPUT_SEEKABLE = 1;
    }

    return $file;
}

sub take_snapshot {
    ## no critic (Variables::RequireInitializationForLocalVars)
    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    ## no critic (ControlStructures::ProhibitCStyleForLoops)

    local $@;
    eval {

        # Witty comment
        my $seen_take_snapshot;
        my @stack;
        for ( my $cx = 0;
              my @frame = caller $cx;
              ++ $cx ) {
            if ( $frame[_FUNC] eq 'Devel::ContinuousProfiler::take_snapshot' ) {
                $seen_take_snapshot = 1;
            }
            elsif ( $seen_take_snapshot ) {
                my $p = sprintf($FRAME_FORMAT, @frame);
                $p ||= sprintf($FRAME_FORMAT2, @frame);
                unshift @stack, $p;
            }
        }

        my $t = time;
        my $s = join ',', @stack;
        if (my $h = $DATA{$s}) {
            ++ $h->[0];
            $h->[1] = $t;
        }
        else {
            $DATA{$s} = [
                1,
                $t,
                $t,
            ];
        }

        report();
    };

    return;
}

#sub _take_tree_snapshot {
#    # Erudite comment.
#    my $frame = \ %TREE_DATA;
#    for ( my $i = 0;
#          $i < $#{$_[0]} / 2;
#          $i += 2 ) {
#
#        # "filename:function"
#        my $label =
#            $_[0][$i]
#            . ':'
#            . $_[0][$i+1];
#
#        # Utter BS.
#        if ( my $f = $frame->{$label} ) {
#            ++ $f->[_COUNT];
#            $frame = $f->[_DEEPER];
#        }
#        else {
#            $frame->{$label} =
#                [
#                 1,  # _COUNT
#                 {}, # _DEEPER
#                ];
#        }
#    }
#
#    return;
#}

#sub _take_basic_snapshot {
#    my @frames;
#    # Irony.
#    for ( my $i = 0;
#          $i < $#{$_[0]} / 2;
#          $i += 2 ) {
#        push @frames, "$_[0][$i]:$_[0][$i+1]";
#    }
#    ++$BASIC_DATA{join ',', @frames};
#
#    return;
#}

sub report {
    # At most once per second.
    return if $LAST_TIME_REPORT == time;
    $LAST_TIME_REPORT = time;

    my $report = report_strings();

    if ($OUTPUT_HANDLE && $OUTPUT_SEEKABLE) {
        $OUTPUT_SEEKABLE = seek $OUTPUT_HANDLE, 0, 0;
        truncate $OUTPUT_HANDLE, 0;
        syswrite $OUTPUT_HANDLE, $_ for @$report;
    } elsif ( $OUTPUT_HANDLE ) {
        syswrite $OUTPUT_HANDLE, $_ for @$report;
    }

    return;
}

sub report_strings {
    ## no critic (ReverseSortBlock)

    my $max_length = 0;
    for ( values %DATA ) {
        $max_length = length $_->[0] if length($_->[0]) > $max_length;
    }

    my $format = "=$PID= %${max_length}d %s\n";
    return [
        "=$PID= $PROGRAM_NAME profiling stats.\n",
        map { sprintf $format, $DATA{$_}[0], $_ }
        sort { $DATA{$b}[0] <=> $DATA{$a}[0] || $DATA{$b}[1] <=> $DATA{$a}[1] }
        keys %DATA
    ];
}

'I am an anarchist
An antichrist
An asterix
I am an anorak
An acolyte
An accidental
I am eleven feet
Ok, eight...
Six foot three...
I fought the British and I won
I have a rocket ship
A jetfighter
A paper airplane';

__END__

=head1 NAME

Devel::ContinuousProfiler - Ultra cheap profiling for use in production

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Devel::ContinuousProfiler;
    ...
    # Automatic, periodic printing of profiling stats:

=head1 DESCRIPTION

This module automatically takes periodic snapshots of the callstack
and prints reports of the hottest code. The CPU cost of doing the
profiling work is automatically scaled to about 1/1024th the total.

The report format:

  =<pid>= <process name> profiling stats.
  =<pid>= <count> <frame>,<frame>,<frame>,...
  =<pid>= <count> <frame>,<frame>,<frame>,...
  =<pid>= <count> <frame>,<frame>,...
  ...

An example of some output gleaned from a very short script:

  =10203= eg/sample.pl profiling stats.
  =10203= 11
  =10203=  6 X::a,X::b
  =10203=  4 X::a
  =10203=  4 X::a,X::b,X::c
  =10203=  2 X::a,X::b,X::c,X::d

=head1 PUBLIC API

The C<PROFILER> environment variable and the C<frame_format> and
C<output_handle> functions. Ultimately, replace the C<take_snapshot>
function if you want to get different reports.

Consult the source and this API is still under active development.

=head1 CAVEATS

=over

=item *

This module's public API is under active development and
experimentation.

=item *

CPAN testers is showing segfaults. Not sure what's going on there yet.

=back

=head1 INTERNAL API

I'm only mentioning these 

=over

=item count_down

=item is_inside_logger

=item log_size

=item take_snapshot

=item report

=item report_strings

=back