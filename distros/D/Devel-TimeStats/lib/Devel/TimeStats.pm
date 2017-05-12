package Devel::TimeStats;

our $VERSION = '0.04';

use Moo;
use namespace::autoclean;
use Time::HiRes qw/gettimeofday tv_interval/;
use Text::UnicodeTable::Simple;
use Term::ExtendedColor qw(:all);
use Tree::Simple qw/use_weak_refs/;
use Tree::Simple::Visitor::FindByUID;

has enable => (is => 'rw', required => 1, default => sub{ 1 });

has tree => (
             is => 'ro',
             required => 1,
             default => sub{ Tree::Simple->new({t => [gettimeofday]}) },
             handles => [qw/ accept traverse /],
            );
has stack => (
              is => 'ro',
              required => 1,
              lazy => 1,
              default => sub { [ shift->tree ] }
             );

has color_map => (
    is => 'ro',
    isa => sub{ ref $_ eq 'HASH' },
    default => sub{{
        '0.01' => 'yellow3',
        '0.05' => 'yellow1',
        '0.1'  => 'red3',
        '0.5'  => 'red1',
    }}
);

has percentage_decimal_precision => (is => 'ro', required => 1, default => sub { 0 } );


sub profile {
    my $self = shift;

    return unless $self->enable;

    my %params;
    if (@_ <= 1) {
        $params{comment} = shift || "";
    }
    elsif (@_ % 2 != 0) {
        die "profile() requires a single comment parameter or a list of name-value pairs; found "
            . (scalar @_) . " values: " . join(", ", @_);
    }
    else {
        (%params) = @_;
        $params{comment} ||= "";
    }

    my $parent;
    my $prev;
    my $t = [ gettimeofday ];
    my $stack = $self->stack;

    if ($params{end}) {
        # parent is on stack; search for matching block and splice out
        for (my $i = $#{$stack}; $i > 0; $i--) {
            if ($stack->[$i]->getNodeValue->{action} eq $params{end}) {
                my ($node) = splice(@{$stack}, $i, 1);
                # Adjust elapsed on partner node
                my $v = $node->getNodeValue;
                $v->{elapsed} =  tv_interval($v->{t}, $t);
                return $node->getUID;
            }
        }
    # if partner not found, fall through to treat as non-closing call
    }
    if ($params{parent}) {
        # parent is explicitly defined
        $prev = $parent = $self->_get_uid($params{parent});
    }
    if (!$parent) {
        # Find previous node, which is either previous sibling or parent, for ref time.
        $prev = $parent = $stack->[-1] or return undef;
        my $n = $parent->getChildCount;
        $prev = $parent->getChild($n - 1) if $n > 0;
    }

    my $node = Tree::Simple->new({
        action  => $params{begin} || "",
        t => $t,
        elapsed => tv_interval($prev->getNodeValue->{t}, $t),
        comment => $params{comment},
    });
    $node->setUID($params{uid}) if $params{uid};

    $parent->addChild($node);
    push(@{$stack}, $node) if $params{begin};

    return $node->getUID;
}

sub created {
    return @{ shift->{tree}->getNodeValue->{t} };
}

sub elapsed {
    return tv_interval(shift->{tree}->getNodeValue->{t});
}

sub report {
    my $self = shift;
    
    my $total_duration = 0;
    $total_duration += $_->getNodeValue->{elapsed} for $self->tree->getAllChildren;

    my $t = Text::UnicodeTable::Simple->new(ansi_color => 1);
    $t->set_header(qw/ Action Time % /);

    my @results;
    $self->traverse(
                sub {
                my $action = shift;
                my $stat   = $action->getNodeValue;
                my @r = ( $action->getDepth,
                      ($stat->{action} || "") .
                      ($stat->{action} && $stat->{comment} ? " " : "") . ($stat->{comment} ? '- ' . $stat->{comment} : ""),
                      $stat->{elapsed},
                      $stat->{action} ? 1 : 0,
                      ($stat->{elapsed} * 100) / $total_duration
                      );
                # Trim down any times >= 10 to avoid ugly Text::Simple line wrapping
                my $elapsed = substr(sprintf("%f", $stat->{elapsed}), 0, 8) . "s";
                
                my $color = '';
                foreach my $key (sort { $a <=> $b } keys %{$self->color_map}) {
                    $color = $self->color_map->{$key} if $stat->{elapsed} >= $key;                    
                }
                
                # format %
                my $share = sprintf "%2.".$self->percentage_decimal_precision."f%%", $r[4];
                
                my @rows;
                for my $value (( q{ } x $r[0] ) . $r[1], defined $r[2] ? $elapsed : '??', $share) {
                    push @rows, fg('bold', fg($color, $value));
                }
                $t->add_row(@rows);

                push(@results, \@r);
                }
            );
    return wantarray ? @results : $t->draw;
}

sub _get_uid {
    my ($self, $uid) = @_;

    my $visitor = Tree::Simple::Visitor::FindByUID->new;
    $visitor->searchForUID($uid);
    $self->accept($visitor);
    return $visitor->getResult;
}

sub addChild {
    my $self = shift;
    my $node = $_[ 0 ];

    my $stat = $node->getNodeValue;

    # do we need to fake $stat->{ t } ?
    if( $stat->{ elapsed } ) {
        # remove the "s" from elapsed time
        $stat->{ elapsed } =~ s{s$}{};
    }

    $self->tree->addChild( @_ );
}

sub setNodeValue {
    my $self = shift;
    my $stat = $_[ 0 ];

    # do we need to fake $stat->{ t } ?
    if( $stat->{ elapsed } ) {
        # remove the "s" from elapsed time
        $stat->{ elapsed } =~ s{s$}{};
    }

    $self->tree->setNodeValue( @_ );
}

sub getNodeValue {
    my $self = shift;
    $self->tree->getNodeValue( @_ )->{ t };
}




1;


__END__

=for stopwords addChild getNodeValue mysub rollup setNodeValue

=head1 NAME

Devel::TimeStats - Timing Statistics Class (Catalyst::Stats fork)

=head1 SYNOPSIS

    use Devel::TimeStats;

    my $stats = Devel::TimeStats->new;

    $stats->enable(1);
    $stats->profile($comment);
    $stats->profile(begin => $block_name, comment =>$comment);
    $stats->profile(end => $block_name);
    $elapsed = $stats->elapsed;
    $report = $stats->report;
    @report = $stats->report;

=head1 DESCRIPTION

This module is a fork of Catalyst::Stats, a timing statistics module.
Tracks elapsed time between profiling points and (possibly nested) blocks.

Typical usage might be like this:

    my $stats = Devel::TimeStats->new;
        
    $stats->profile( begin => 'interesting task' );
    
    run_step_1();
    $stats->profile( 'completed step 1' );
    
    run_step_2();
    $stats->profile( 'completed step 2' );
    
    run_step_3();
    $stats->profile( 'completed step 3' );
    
    run_step_4();
    $stats->profile( 'completed step 4' );
    
    run_step_5();
    $stats->profile( 'completed step 5' );
    
    # ... time spent here also accounted in the 'interesting task' block
    
    $stats->profile( end => 'interesting task' );
    
    print scalar $stats->report;

example report:

    .---------------------+-----------+------.
    | Action              |   Time    | %    |   # percentage helps blaming 
    +---------------------+-----------+------+
    | interesting task    | 0.661000s | 100% |   
    |  - completed step 1 | 0.001000s |  0%  |
    |  - completed step 2 | 0.010000s |  2%  |   # took >= 10ms, yellow (by default)
    |  - completed step 3 | 0.050000s |  8%  |   # took >= 50ms, bright yellow (by default)
    |  - completed step 4 | 0.100000s | 15%  |   # took >= 100ms, red (by default)
    |  - completed step 5 | 0.500000s | 76%  |   # took >= 500ms, bright red (by default)
    `---------------------+-----------+------'

You can configure the L</color_map> and L</percentage_decimal_precision>.

=head1 METHODS

=head2 new

Constructor.

    $stats = Catalyst::Stats->new(%options);

Valid options:

=over 4

=item C<enable>

Default C<1>

=item C<color_map>

A hashref mapping a duration threshold (in seconds) to a color. 
Default:

    {
        '0.01' => 'yellow3',
        '0.05' => 'yellow1',
        '0.1'  => 'red3',
        '0.5'  => 'red1',
    }    

See L<Term::ExtendedColor/"COLORS AND ATTRIBUTES">.

=item C<percentage_decimal_precision>

How many decimal places for the percentage column. 
Default C<0>.

=back

=head2 enable

    $stats->enable(0);
    $stats->enable(1);

Enable or disable stats collection.  By default, stats are enabled after object creation.

=head2 profile

    $stats->profile($comment);
    $stats->profile(begin => $block_name, comment =>$comment);
    $stats->profile(end => $block_name);

Marks a profiling point.  These can appear in pairs, to time the block of code
between the begin/end pairs, or by themselves, in which case the time of
execution to the previous profiling point will be reported.

The argument may be either a single comment string or a list of name-value
pairs.  Thus the following are equivalent:

    $stats->profile($comment);
    $stats->profile(comment => $comment);

The following key names/values may be used:

=over 4

=item * begin => ACTION

Marks the beginning of a block.  The value is used in the description in the
timing report.

=item * end => ACTION

Marks the end of the block.  The name given must match a previous 'begin'.
Correct nesting is recommended, although this module is tolerant of blocks that
are not correctly nested, and the reported timings should accurately reflect the
time taken to execute the block whether properly nested or not.

=item * comment => COMMENT

Comment string; use this to describe the profiling point.  It is combined with
the block action (if any) in the timing report description field.

=item * uid => UID

Assign a predefined unique ID.  This is useful if, for whatever reason, you wish
to relate a profiling point to a different parent than in the natural execution
sequence.

=item * parent => UID

Explicitly relate the profiling point back to the parent with the specified UID.
The profiling point will be ignored if the UID has not been previously defined.

=back

Returns the UID of the current point in the profile tree.  The UID is
automatically assigned if not explicitly given.

=head2 created

    ($seconds, $microseconds) = $stats->created;

Returns the time the object was created, in C<gettimeofday> format, with
Unix epoch seconds followed by microseconds.

=head2 elapsed

    $elapsed = $stats->elapsed

Get the total elapsed time (in seconds) since the object was created.

=head2 report

    print $stats->report ."\n";
    $report = $stats->report;
    @report = $stats->report;

In scalar context, generates a textual report.  In array context, returns the
array of results where each row comprises:

    [ depth, description, time, rollup, percentage ]

The depth is the calling stack level of the profiling point.

The description is a combination of the block name and comment.

The time reported for each block is the total execution time for the block, and
the time associated with each intermediate profiling point is the elapsed time
from the previous profiling point.

The 'rollup' flag indicates whether the reported time is the rolled up time for
the block, or the elapsed time from the previous profiling point.

The percentage of total time (floating-point number).

=head1 COMPATIBILITY METHODS

Some components might expect the stats object to be a regular Tree::Simple object.
We've added some compatibility methods to handle this scenario:

=head2 accept

=head2 addChild

=head2 setNodeValue

=head2 getNodeValue

=head2 traverse

=head1 SEE ALSO

L<Catalyst::Stats>

=head1 THANKS TO

Catalyst Contributors

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@q1software.comE<gt>

=cut

