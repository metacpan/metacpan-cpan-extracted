package Games::Solitaire::BlackHole::Solver::App::Base;
$Games::Solitaire::BlackHole::Solver::App::Base::VERSION = '0.12.0';
use Moo;
use Getopt::Long     qw/ GetOptions /;
use Pod::Usage       qw/ pod2usage /;
use Math::Random::MT ();
use List::Util 1.34  qw/ any first max /;

extends('Exporter');

# These attributes should remain constant during a solver's run.
has '_num_foundations' => ( default => 1, is => 'rw', );

my $solver_const_attrs = [
    '_bits_offset',        '_display_boards',
    '_init_tasks_configs', '_is_good_diff',
    '_max_iters_limit',    '_prelude',
    '_prelude_string',     '_talon_cards',
    '_quiet',              '_output_handle',
    '_output_fn',          '_should_show_maximal_num_played_cards',
];

my $board_const_attrs = [
    '_board_cards',           '_board_lines',
    '_board_values',          '_init_foundation',
    '_init_foundation_cards', '_init_queue',
];

my $CHECK_SET_ONLY_ONCE_KEY = "BLACK_HOLE_SOLVER_RUNTIME_CHECKS";
my $CHECK_SET_ONLY_ONCE     = $ENV{$CHECK_SET_ONLY_ONCE_KEY};
if ( not $CHECK_SET_ONLY_ONCE )
{
    has [ @$board_const_attrs, @$solver_const_attrs ] => ( is => 'rw', );
}
else
{
    foreach my $const_attr (@$solver_const_attrs)
    {
        has $const_attr => (
            is => 'rw',
            (
                $CHECK_SET_ONLY_ONCE
                ? (
                    trigger => sub {
                        my ( $self, $newval ) = @_;
                        die "self=$self const_attr=$const_attr"
                            if ( $self->{_SOLVER_CTR}->{$const_attr}++ );
                        return;
                    }
                    )
                : ()
            )
        );
    }
    foreach my $const_attr (@$board_const_attrs)
    {
        has $const_attr => (
            is => 'rw',
            (
                $CHECK_SET_ONLY_ONCE
                ? (
                    trigger => sub {
                        my ( $self, $newval ) = @_;
                        die "self=$self const_attr=$const_attr"
                            if ( $self->{_BOARD_CTR}->{$const_attr}++ );
                        return;
                    }
                    )
                : ()
            )
        );
    }
}

# These attributes mutate during a solver's run.
has [
    '_active_record', '_active_task',
    '_maximal_num_played_cards__from_all_tasks',
    '_prelude_iter', '_positions', '_tasks', '_task_idx',
] => ( is => 'rw' );

our %EXPORT_TAGS = ( 'all' => [qw($card_re)] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );

my @ranks      = ( "A", 2 .. 9, qw(T J Q K) );
my %ranks_to_n = ( map { $ranks[$_] => $_ } 0 .. $#ranks );

sub _RANK_KING
{
    return $ranks_to_n{'K'};
}

my $card_re_str = '[' . join( "", @ranks ) . '][HSCD]';
our $card_re = qr{$card_re_str};

sub _get_rank
{
    shift;
    return $ranks_to_n{ substr( shift(), 0, 1 ) };
}

sub _calc_lines
{
    my $self     = shift;
    my $filename = shift;

    my @lines;
    if ( $filename eq "-" )
    {
        @lines = <STDIN>;
    }
    else
    {
        open my $in, "<", $filename
            or die
            "Could not open $filename for inputting the board lines - $!";
        @lines = <$in>;
        close($in);
    }
    chomp @lines;
    $self->_board_lines( \@lines );
    return;
}

sub _update_max_num_played_cards
{
    my $self = shift;

    foreach my $task ( @{ $self->_tasks } )
    {
        $self->_update_max_reached_depths_stack_len($task);
    }

    return;
}

sub _output_board
{
    my (
        $self,               $prev_state, $moves,
        $changed_foundation, $col_idx,    $foundation_str_ref
    ) = @_;
    if ( not $self->_display_boards )
    {
        return;
    }
    my $_num_foundations = $self->_num_foundations();
    my $offset           = $self->_bits_offset();
    my $ret              = '';
    my $foundation_val;
    while ( my ( $i, $col ) = each( @{ $self->_board_cards } ) )
    {
        my $prevlen = vec( $prev_state, $offset + $i, 4 );
        my $height  = $prevlen - 1;
        my $iscurr  = ( $col_idx == $i );
        my @c       = @$col[ 0 .. $height ];
        if ($iscurr)
        {
            $foundation_val = $self->_board_values->[$col_idx][$height];
            foreach my $x ( $c[-1] )
            {
                $$foundation_str_ref = $x;
                $x                   = "[ $x -> ]";
            }
        }
        $ret .= join( " ", ":", @c ) . "\n";
    }

    push @$moves,
        +{
        type               => "board",
        str                => $ret,
        foundation_str     => $$foundation_str_ref,
        foundation_val     => $foundation_val,
        changed_foundation => $changed_foundation,
        };
    return;
}

sub _trace_solution
{
    my ( $self, $final_state ) = @_;

    my $_num_foundations = $self->_num_foundations();
    my $offset           = $self->_bits_offset();

    $self->_update_max_num_played_cards();
    my $output_handle = $self->_output_handle;
    $output_handle->print("Solved!\n");

    return if $self->_quiet;

    my $state = $final_state;

    my @moves;
LOOP:
    while ( my ( $prev_state, $col_idx ) = @{ $self->_positions->{$state} } )
    {
        last LOOP if not defined $prev_state;
        my $changed_foundation =
            first { vec( $state, $_, 8 ) ne vec( $prev_state, $_, 8 ) }
            ( 0 .. $_num_foundations - 1 );
        if ( not defined($changed_foundation) )
        {
            die
"ERROR! Could not find changed_foundation. It must not have happened!";
        }
        my $foundation_str;
        $self->_output_board(
            $prev_state, \@moves, $changed_foundation,
            $col_idx,    \$foundation_str
        );
        push @moves,
            +{
            type => "card",
            str  => scalar(
                ( $col_idx == @{ $self->_board_cards } ) ? "Deal talon "
                    . $self->_talon_cards->[ vec( $prev_state, 1, 8 ) ]
                : $self->_display_boards
                ? sprintf( "Move %s from stack %d to foundations %d",
                    $foundation_str, $col_idx, $changed_foundation, )
                : $self->_board_cards->[$col_idx]
                    [ vec( $prev_state, $offset + $col_idx, 4 ) - 1 ]
            ),
            };
    }
    continue
    {
        $state = $prev_state;
    }

    my @foundation_cards = @{ $self->_init_foundation_cards() };
    foreach my $move_rec ( reverse(@moves) )
    {
        my $type = $move_rec->{"type"};
        my $str;
        if ( $type eq "card" )
        {
            $str = "";
            $str .= $move_rec->{"str"};
        }
        elsif ( $type eq "board" )
        {
            if ( not $self->_display_boards )
            {
                die;
            }
            my $i     = $move_rec->{"changed_foundation"};
            my $new   = $move_rec->{"foundation_str"};
            my @shown = @foundation_cards;
            foreach my $x ( $shown[$i] )
            {
                $x = "[ $x -> $new ]";
            }
            $str = "";
            $str .= "\n";
            $str .= join( " ", "Foundations:", @shown ) . "\n";
            $str .= $move_rec->{"str"};
            $foundation_cards[$i] = $new;
        }
        else
        {
            die;
        }
        print {$output_handle} "$str\n";
    }

    return;
}

sub get_max_num_played_cards
{
    my $self = shift;

    $self->_update_max_num_played_cards();

    return $self->_maximal_num_played_cards__from_all_tasks() - 1;
}

sub _end_report
{
    my ( $self, $verdict, ) = @_;
    my $output_handle = $self->_output_handle;

    if ( !$verdict )
    {
        $output_handle->print("Unsolved!\n");
    }
    if ( $self->_should_show_maximal_num_played_cards() )
    {
        $output_handle->printf(
            "At most %u cards could be played.\n",
            $self->get_max_num_played_cards()
        );
    }

    return;
}

sub _my_exit
{
    my ( $self, $verdict, ) = @_;

    if ( defined( $self->_output_fn ) )
    {
        close( $self->_output_handle );
    }

    exit( !$verdict );
}

sub _parse_board
{
    my ($self) = @_;
    my $lines = $self->_board_lines;

    my $found_line = shift(@$lines);

    my $init_foundation;
    my @init_foundation_cards;
    my $_num_foundations = $self->_num_foundations();
    if ( my ($card) =
        $found_line =~ m{\AFoundations:((?: $card_re){$_num_foundations})\z} )
    {
        $card =~ s#\A ## or die "no whitespace";
        @init_foundation_cards = split /\s+/, $card;
        $init_foundation =
            [ map { $self->_get_rank($_) } @init_foundation_cards ];
    }
    else
    {
        die "Could not match first foundation line!";
    }
    $self->_init_foundation_cards( \@init_foundation_cards );
    $self->_init_foundation($init_foundation);

    $self->_board_cards( [ map { [ split /\s+/, $_ ] } @$lines ] );
    $self->_board_values(
        [
            map {
                [ map { $self->_get_rank($_) } @$_ ]
            } @{ $self->_board_cards }
        ]
    );
    return;
}

sub _set_up_initial_position
{
    my ( $self, $talon_ptr ) = @_;

    my $init_state = "";

    my $offset = $self->_bits_offset();
    my $o      = 0;
    foreach my $x ( @{ $self->_init_foundation } )
    {
        vec( $init_state, $o++, 8 ) = $x;
    }
    vec( $init_state, $o, 8 ) = $talon_ptr;

    my $board_values = $self->_board_values;
    foreach my $col_idx ( keys @$board_values )
    {
        vec( $init_state, $offset + $col_idx, 4 ) =
            scalar( @{ $board_values->[$col_idx] } );
    }

    # The values of $positions is an array reference with the 0th key being the
    # previous state, and the 1th key being the column of the move.
    $self->_positions( +{ $init_state => [ undef, undef, 1, 0, ], } );

    $self->_init_queue( [$init_state] );

    return;
}

sub _shuffle
{
    my ( $self, $gen, $arr ) = @_;

    my $i = $#$arr;
    while ( $i > 0 )
    {
        my $j = int( $gen->rand( $i + 1 ) );
        if ( $i != $j )
        {
            @$arr[ $i, $j ] = @$arr[ $j, $i ];
        }
        --$i;
    }
    return;
}

sub _set_bits_offset
{
    my $self = shift;

    my $_num_foundations = $self->_num_foundations();
    my $offset           = 2 + 2 * $_num_foundations;
    $self->_bits_offset($offset);

    return;
}

my $TASK_NAME_RE  = qr/[A-Za-z0-9_]+/;
my $TASK_ALLOC_RE = qr/[0-9]+\@$TASK_NAME_RE/;

sub _process_cmd_line
{
    my ( $self, $args ) = @_;

    my $_max_iters_limit = ( 1 << 31 );
    my $_num_foundations = 1;
    my $_prelude_string;
    my $_should_show_maximal_num_played_cards = 0;
    my $display_boards                        = '';
    my $quiet                                 = '';
    my $output_fn;
    my ( $help, $man, $version );
    my @tasks;

    my $push_task = sub {
        push @tasks,
            +{
            name => undef(),
            seed => 0,
            };
        return;
    };
    $push_task->();
    GetOptions(
        "display-boards!" => \$display_boards,
        "o|output=s"      => \$output_fn,
        "quiet!"          => \$quiet,
        "next-task"       => sub {
            $push_task->();
            return;
        },
        "num-foundations=i" => sub {
            my ( undef, $val ) = @_;
            if ( not( ( $val eq "1" ) or ( $val eq "2" ) ) )
            {
                die;
            }
            $_num_foundations = $val;
            return;
        },
        "prelude=s" => sub {
            my ( undef, $val ) = @_;
            if ( $val !~ /\A$TASK_ALLOC_RE(?:,$TASK_ALLOC_RE)*\z/ )
            {
                die "Invalid prelude string '$val' !";
            }
            $_prelude_string = $val;
            return;
        },
        "task-name=s" => sub {
            my ( undef, $val ) = @_;
            if ( $val !~ /\A$TASK_NAME_RE\z/ )
            {
                die "Invalid task name '$val' - must be alphanumeric!";
            }
            $tasks[-1]->{name} = $val;
            return;
        },
        "seed=i" => sub {
            my ( undef, $val ) = @_;
            $tasks[-1]->{seed} = $val;
            return;
        },
        "show-max-num-played-cards!" => sub {
            my ( undef, $val ) = @_;
            $_should_show_maximal_num_played_cards = $val;
            return;
        },
        "max-iters=i" => sub {
            my ( undef, $val ) = @_;
            $_max_iters_limit = $val;
            return;
        },
        'help|h|?' => \$help,
        'man'      => \$man,
        'version'  => \$version,
        %{ $args->{extra_flags} },
    ) or pod2usage(2);
    if ( @tasks == 1 )
    {
        $tasks[-1]{name} = 'default';
    }
    if ( any { !defined $_->{name} } @tasks )
    {
        die "You did not specify the task-names for some tasks";
    }
    $self->_init_tasks_configs( \@tasks );

    pod2usage(1)                                 if $help;
    pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

    if ($version)
    {
        print
"black-hole-solve version $Games::Solitaire::BlackHole::Solver::App::Base::VERSION\n";
        exit(0);
    }

    $self->_display_boards($display_boards);
    $self->_max_iters_limit($_max_iters_limit);
    $self->_num_foundations($_num_foundations);
    if ( defined($_prelude_string) )
    {
        $self->_prelude_string($_prelude_string);
    }
    $self->_quiet($quiet);
    $self->_should_show_maximal_num_played_cards(
        $_should_show_maximal_num_played_cards);
    $self->_set_bits_offset();

    my $output_handle;

    if ( defined($output_fn) )
    {
        open( $output_handle, ">", $output_fn )
            or die "Could not open '$output_fn' for writing";
    }
    else
    {
        ## no critic
        # open( $output_handle, ">&STDOUT" );
        $output_handle = \*STDOUT;
        ## use critic
        # die $output_handle;"applj";
    }
    $self->_output_fn($output_fn);
    $self->_output_handle($output_handle);

    # $self->_calc_lines( shift(@ARGV) );

    return;
}

sub _set_up_tasks
{
    my ($self) = @_;
    $self->_maximal_num_played_cards__from_all_tasks(0);

    my @tasks;
    my %tasks_by_names;
    foreach my $task_rec ( @{ $self->_init_tasks_configs } )
    {
        my $iseed     = $task_rec->{seed};
        my $name      = $task_rec->{name};
        my $_task_idx = @tasks;
        my $task_obj =
            Games::Solitaire::BlackHole::Solver::App::Base::Task->new(
            {
                _name            => $name,
                _seed            => $iseed,
                _gen             => Math::Random::MT->new( $iseed || 1 ),
                _remaining_iters => 100,
                _task_idx        => $_task_idx,
            }
            );
        $task_obj->_push_to_queue( $self->_init_queue );
        push @tasks, $task_obj;
        if ( exists $tasks_by_names{$name} )
        {
            die "Duplicate task-name '$name'!";
        }
        $tasks_by_names{$name} = $task_obj;
    }
    $self->_task_idx(0);
    $self->_tasks( \@tasks );
    if ( not $self->_prelude )
    {
        my @prelude;
        my $process_item = sub {
            my $s = shift;
            if ( my ( $quota, $name ) = $s =~ /\A([0-9]+)\@($TASK_NAME_RE)\z/ )
            {
                if ( not exists $self->_tasks_by_names->{$name} )
                {
                    die "Unknown task name $name in prelude!";
                }
                my $task_obj = $self->_tasks_by_names->{$name};
                return
                    Games::Solitaire::BlackHole::Solver::App::Base::PreludeItem
                    ->new(
                    {
                        _quota     => $quota,
                        _task      => $task_obj,
                        _task_idx  => $task_obj->_task_idx,
                        _task_name => $task_obj->_name,
                    }
                    );
            }
            else
            {
                die "foo";
            }
        };
        if ( my $_prelude_string = $self->_prelude_string )
        {
            push @prelude,
                (
                map { $process_item->($_) }
                    split /,/, $_prelude_string
                );
        }
        $self->_prelude( \@prelude );
    }
    $self->_prelude_iter(0);
    if ( @{ $self->_prelude } )
    {
        $self->_next_task;
    }
    return;
}

sub _update_max_reached_depths_stack_len
{
    my ( $self, $task ) = @_;

    $self->_maximal_num_played_cards__from_all_tasks(
        max(
            $self->_maximal_num_played_cards__from_all_tasks,
            $task->_max_reached_depths_stack_len
        )
    );

    return;
}

sub _next_task
{
    my ($self) = @_;
    if ( $self->_prelude_iter < @{ $self->_prelude } )
    {
        my $alloc = $self->_prelude->[ $self->{_prelude_iter}++ ];
        my $task  = $alloc->_task;
        if ( !@{ $task->_queue } )
        {
            $self->_update_max_reached_depths_stack_len($task);
            return $self->_next_task;
        }
        $task->_remaining_iters( $alloc->_quota );
        $self->_active_task($task);
        return 1;
    }
    my $tasks = $self->_tasks;
    return if !@$tasks;
    if ( !@{ $tasks->[ $self->_task_idx ]->_queue } )
    {
        splice @$tasks, $self->_task_idx, 1;
        return $self->_next_task;
    }
    my $task = $tasks->[ $self->_task_idx ];
    $self->_task_idx( ( $self->_task_idx + 1 ) % @$tasks );
    $task->_remaining_iters(100);
    $self->_active_task($task);

    return 1;
}

sub _get_next_state
{
    my ($self) = @_;

    my $l     = @{ $self->_active_task->_queue };
    my $ret   = pop( @{ $self->_active_task->_queue } );
    my $stack = $self->_active_task->_depths_stack;
    while ( @$stack and ( $stack->[-1] == $l ) )
    {
        pop @$stack;
    }
    push @$stack, ( $l - 1 );
    return $ret;
}

sub _get_next_state_wrapper
{
    my ($self) = @_;

    my $positions = $self->_positions;

    while ( my $state = $self->_get_next_state )
    {
        my $rec = $positions->{$state};
        $self->_active_record($rec);
        return $state if $rec->[2];
    }
    return;
}

sub _process_pending_items
{
    my ( $self, $_pending, $state ) = @_;

    my $rec  = $self->_active_record;
    my $task = $self->_active_task;

    if (@$_pending)
    {
        $self->_shuffle( $task->_gen, $_pending ) if $task->_seed;
        $task->_push_to_queue( [ map { $_->[0] } @$_pending ] );
        $rec->[3] += ( scalar grep { !$_->[1] } @$_pending );
    }
    else
    {
        my $parent     = $state;
        my $parent_rec = $rec;
        my $positions  = $self->_positions;

    PARENT:
        while ( ( !$parent_rec->[3] ) or ( ! --$parent_rec->[3] ) )
        {
            $parent_rec->[2] = 0;
            $parent = $parent_rec->[0];
            last PARENT if not defined $parent;
            $parent_rec = $positions->{$parent};
        }
    }
    if ( not --$task->{_remaining_iters} )
    {
        return $self->_next_task;
    }
    return 1;
}

sub _find_moves
{
    my ( $self, $_pending, $state, $no_cards ) = @_;
    my $board_values     = $self->_board_values;
    my $_num_foundations = $self->_num_foundations();
    my $offset           = $self->_bits_offset();
    my $used             = '';
    my @fnd;
    foreach my $i ( 0 .. $_num_foundations - 1 )
    {
        my $v = vec( $state, $i, 8 );
        if ( not vec( $used, $v, 1 ) )
        {
            vec( $used, $v, 1 ) = 1;
            push @fnd, [ $i, $v ];
        }
    }
    my $max_iters_limit = $self->_max_iters_limit;
    my $positions       = $self->_positions;
    my $_is_good_diff   = $self->_is_good_diff;
    foreach my $col_idx ( keys @$board_values )
    {
        my $pos = vec( $state, $offset + $col_idx, 4 );

        if ($pos)
        {
            $$no_cards = 0;

            my $card = $board_values->[$col_idx][ $pos - 1 ];
            die if not defined $card;
            foreach my $x (@fnd)
            {
                my ( $i, $v ) = @$x;
                if ( exists( $_is_good_diff->{ $card - $v } ) )
                {
                    my $next_s = $state;
                    vec( $next_s, $i, 8 ) = $card;
                    --vec( $next_s, $offset + $col_idx, 4 );
                    my $exists = exists( $positions->{$next_s} );
                    my $to_add = 0;
                    if ( !$exists )
                    {
                        $positions->{$next_s} = [ $state, $col_idx, 1, 0 ];
                        if ( keys(%$positions) > $max_iters_limit )
                        {
                            die "Exceeded max_iters_limit !";
                        }
                        $to_add = 1;
                    }
                    elsif ( $positions->{$next_s}->[2] )
                    {
                        $to_add = 1;
                    }
                    if ($to_add)
                    {
                        push( @$_pending, [ $next_s, $exists ] );
                    }
                }
            }
        }
    }

    return;
}

sub _set_up_solver
{
    my ( $self, $talon_ptr, $diffs ) = @_;

    $self->_parse_board;
    $self->_set_up_initial_position($talon_ptr);
    $self->_set_up_tasks;
    if ( not $self->_is_good_diff )
    {
        $self->_is_good_diff( +{ map { $_ => 1 } map { $_, -$_ } @$diffs, } );
    }

    return;
}

package Games::Solitaire::BlackHole::Solver::App::Base::Task;
$Games::Solitaire::BlackHole::Solver::App::Base::Task::VERSION = '0.12.0';
use Moo;

has '_queue'        => ( is => 'ro', default => sub { return []; }, );
has '_depths_stack' => ( is => 'ro', default => sub { return []; }, );
has '_max_reached_depths_stack_len' => ( is => 'rw', default => 0 );
has [ '_gen', '_task_idx', '_name', '_remaining_iters', '_seed', ] =>
    ( is => 'rw' );

sub _push_to_queue
{
    my ( $self, $items ) = @_;
    die if not @$items;
    push @{ $self->_queue },        @$items;
    push @{ $self->_depths_stack }, scalar( @{ $self->_queue } );
    my $l = @{ $self->_depths_stack };
    if ( $l > $self->_max_reached_depths_stack_len() )
    {
        $self->_max_reached_depths_stack_len($l);
    }

    return;
}

package Games::Solitaire::BlackHole::Solver::App::Base::PreludeItem;
$Games::Solitaire::BlackHole::Solver::App::Base::PreludeItem::VERSION = '0.12.0';
use Moo;

has [ '_quota', '_task', '_task_idx', '_task_name', ] => ( is => 'rw' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::BlackHole::Solver::App::Base - base class.

=head1 VERSION

version 0.12.0

=head1 METHODS

=head2 new

For internal use.

=head2 get_max_num_played_cards

Returns the maximal number of played cards.

Added in version 0.6.0.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Games-Solitaire-BlackHole-Solver>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Solitaire-BlackHole-Solver>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Games-Solitaire-BlackHole-Solver>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/G/Games-Solitaire-BlackHole-Solver>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Games-Solitaire-BlackHole-Solver>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Games::Solitaire::BlackHole::Solver>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-games-solitaire-blackhole-solver at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Games-Solitaire-BlackHole-Solver>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/black-hole-solitaire>

  git clone https://github.com/shlomif/black-hole-solitaire

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/black-hole-solitaire/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
