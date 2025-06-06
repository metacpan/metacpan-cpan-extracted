package Games::Solitaire::Verify::Golf;
$Games::Solitaire::Verify::Golf::VERSION = '0.2601';
use strict;
use warnings;
use 5.014;
use autodie;


use Carp       ();
use List::Util qw/ sum /;

use Games::Solitaire::Verify::Card      ();
use Games::Solitaire::Verify::Column    ();
use Games::Solitaire::Verify::Freecells ();
use Games::Solitaire::Verify::LinesIter ();

use parent 'Games::Solitaire::Verify::Base';

__PACKAGE__->mk_acc_ref(
    [
        qw(
            _columns
            _foundation
            _num_foundations
            _place_queens_on_kings
            _talon
            _variant
            _wrap_ranks
        )
    ]
);

my $MAX_RANK  = 13;
my $NUM_SUITS = 4;
my $CARD_RE   = qr/[A23456789TJQK][HCDS]/;

my %_VARIANTS = (
    all_in_a_row => 1,
    binary_star  => 1,
    black_hole   => 1,
    golf         => 1,
);

sub _is_binary_star
{
    my $self = shift;

    return $self->_variant eq 'binary_star';
}

sub _is_golf
{
    my $self = shift;

    return $self->_variant eq 'golf';
}

sub _read_foundation_line
{
    my ( $self, $foundation_str ) = @_;
    my $num_foundations = $self->_num_foundations();

    if ( my ($card_s) = $foundation_str =~
        m#\AFoundations:((?: $CARD_RE){$num_foundations})\z# )
    {
        $card_s =~ s/\A //ms
            or Carp::confess("_set_found_line: no leading space");
        my @c = split( / /, $card_s );
        if ( @c != $num_foundations )
        {
            Carp::confess( "num_foundations is "
                    . scalar(@c)
                    . " rather than $num_foundations" );
        }
        for my $i ( keys @c )
        {
            my $s = $c[$i];
            $self->_set_found( $i,
                Games::Solitaire::Verify::Card->new( { string => $s } ) );
        }
    }
    else
    {
        Carp::confess("Foundations str is '$foundation_str'");
    }
    return;
}

sub _init
{
    my ( $self, $args ) = @_;

    my $variant = $self->_variant( $args->{variant} );
    if ( not exists $_VARIANTS{$variant} )
    {
        Carp::confess("Unknown variant '$variant'!");
    }
    my $IS_BINARY_STAR = $self->_is_binary_star;
    $self->_place_queens_on_kings( $args->{queens_on_kings} // '' );
    $self->_wrap_ranks( $args->{wrap_ranks}                 // '' );
    my $num_foundations = ( $IS_BINARY_STAR ? 2 : 1 );
    $self->_num_foundations($num_foundations);
    $self->_foundation(
        Games::Solitaire::Verify::Freecells->new(
            { count => $num_foundations, }
        )
    );
    my $board_string = $args->{board_string};

    my @lines          = split( /\n/, $board_string );
    my $foundation_str = shift(@lines);
    if ( $self->_variant eq 'golf' )
    {
        if ( $foundation_str !~ s#\ATalon: ((?:$CARD_RE ){15}$CARD_RE)#$1# )
        {
            Carp::confess("improper talon line <$foundation_str>!");
        }
        $self->_talon(
            [
                map { Games::Solitaire::Verify::Card->new( { string => $_ } ) }
                    split / /,
                $foundation_str
            ]
        );

        $foundation_str = shift(@lines);
        $self->_read_foundation_line($foundation_str);
    }
    else
    {
        $self->_talon( [] );
        if ( $self->_variant eq "all_in_a_row" )
        {
            if ( $foundation_str ne "Foundations: -" )
            {
                Carp::confess("Foundations str is '$foundation_str'");
            }
        }
        else
        {
            $self->_read_foundation_line($foundation_str);
        }
    }

    $self->_columns(
        [
            map {
                Games::Solitaire::Verify::Column->new(
                    {
                        string => ": $_",
                    }
                )
            } @lines
        ]
    );
    if ( $self->_wrap_ranks )
    {
        $self->_place_queens_on_kings(1);
    }

    return;
}

sub _set_found
{
    my ( $self, $i, $card ) = @_;
    $self->_foundation->assign( $i, $card, );
    return;
}

sub process_solution
{
    my ( $self, $next_line_iter ) = @_;
    my $columns     = $self->_columns;
    my $NUM_COLUMNS = @$columns;
    my $it          = Games::Solitaire::Verify::LinesIter->new(
        { _get => $next_line_iter, } );
    my $remaining_cards = sum( map { $_->len } @$columns );

    $it->_compare_line( "Solved!", "First line" );

    my $IS_BINARY_STAR     = $self->_is_binary_star;
    my $IS_GOLF            = $self->_is_golf;
    my $CHECK_EMPTY        = ( $IS_GOLF or $self->_variant eq "black_hole" );
    my $IS_DETAILED_MOVE   = $IS_BINARY_STAR;
    my $IS_DISPLAYED_BOARD = $IS_BINARY_STAR;
    my $num_decks          = $self->_num_foundations();
    my $num_foundations    = $self->_num_foundations();

    # As many moves as the number of cards.
MOVES:
    for my $move_idx (
        0 .. (
            $num_decks * $MAX_RANK * $NUM_SUITS -
                $num_foundations -
                ( $num_foundations > 1 )
        )
        )
    {
        my ( $move_line, $move_line_idx ) = $it->_get_line;

        my $card;
        my $col_idx;
        my $foundation_idx = 0;
        my $moved_card_str;
        if (    $IS_GOLF
            and $move_line =~ m/\ADeal talon\z/ )
        {
            if ( !@{ $self->_talon } )
            {
                Carp::confess("Talon is empty on line no. $move_line_idx");
            }
            $card = shift @{ $self->_talon };
        }
        else
        {
            if (
                not(
                    $IS_DETAILED_MOVE
                    ? ( ( $moved_card_str, $col_idx, $foundation_idx ) =
                            $move_line =~
m/\AMove ($CARD_RE) from stack ([0-9]+) to foundations ([0-9]+)\z/
                    )
                    : ( ($col_idx) =
                            $move_line =~
m/\AMove a card from stack ([0-9]+) to the foundations\z/
                    )
                )
                )
            {
                Carp::confess(
"Incorrect format for move line no. $move_line_idx - '$move_line'"
                );
            }
        }

        if ( !defined $card )
        {
            if ( ( $col_idx < 0 ) or ( $col_idx >= $NUM_COLUMNS ) )
            {
                Carp::confess(
                    "Invalid column index '$col_idx' at line no. $move_line_idx"
                );
            }
        }

        $it->_assert_empty_line();
        my ( $info_line, $info_line_idx );
        if ( not $IS_DETAILED_MOVE )
        {
            ( $info_line, $info_line_idx ) = $it->_get_line;
            if ( $info_line !~ m/\AInfo: Card moved is ($CARD_RE)\z/ )
            {
                Carp::confess(
"Invalid format for info line no. $info_line_idx - '$info_line'"
                );
            }

            $moved_card_str = $1;

            $it->_assert_empty_line();
            $it->_assert_empty_line();

            my ( $sep_line, $sep_line_idx ) = $it->_get_line;

            if ( $sep_line !~ m/\A=+\z/ )
            {
                Carp::confess(
"Invalid format for separator line no. $sep_line_idx - '$sep_line'"
                );
            }

            $it->_assert_empty_line();
        }

        if ( defined $card )
        {
            my $top_card_moved_str = $card->to_string();
            if ( $top_card_moved_str ne $moved_card_str )
            {
                Carp::confess(
"Card moved should be '$top_card_moved_str', but the info says it is '$moved_card_str' at line $info_line_idx"
                );
            }
        }
        else
        {
            my $col                = $columns->[$col_idx];
            my $top_card           = $col->top();
            my $top_card_moved_str = $top_card->to_string();

            if ( $top_card_moved_str ne $moved_card_str )
            {
                Carp::confess(
"Card moved should be '$top_card_moved_str', but the info says it is '$moved_card_str' at line $info_line_idx"
                );
            }

            my $found_card = $self->_foundation->cell($foundation_idx);
            if ( defined($found_card) )
            {
                my $found_rank = $found_card->rank();
                my $src_rank   = $top_card->rank();

                my $delta = abs( $src_rank - $found_rank );
                if (
                    not( $delta == 1 or $delta == ( $MAX_RANK - 1 ) )
                    or (
                            $IS_GOLF
                        and ( !$self->_wrap_ranks )
                        and (
                            (
                                $self->_place_queens_on_kings
                                ? ( $found_rank == $MAX_RANK )
                                : 0
                            )
                            or $delta != 1
                        )
                    )
                    )
                {
                    Carp::confess(
"Cannot put $top_card_moved_str in the foundations that contain "
                            . $found_card->to_string() );
                }
                if ($IS_DISPLAYED_BOARD)
                {
                    my $wanted_line = $self->_foundation->to_string();
                    $wanted_line =~ s#\AFreecells:#Foundations:#
                        or Carp::confess("Unimpl!");
                    $wanted_line =~ s#  # #g;
                    my $fstr = $found_card->to_string();
                    my $tstr = $top_card->to_string();
                    $wanted_line =~
s#\AFoundations:(?: $CARD_RE){$foundation_idx} \K(\Q$fstr\E)#my$c=$1;"[ $c -> $tstr ]"#e
                        or Carp::confess(
"Failed substitute! foundation_idx=$foundation_idx wanted_line=$wanted_line fstr='$fstr'"
                        );
                    $it->_compare_line( $wanted_line, "Foundations" );
                    for my $i ( keys @$columns )
                    {
                        my $col         = $columns->[$i];
                        my $wanted_line = $col->to_string();
                        if ( $i == $col_idx )
                        {
                            $wanted_line =~
                                s# \K(\Q$tstr\E)\z#my$c=$1;"[ $c -> ]"#e
                                or Carp::confess(
"Failed column substitute! foundation_idx=$foundation_idx wanted_line=$wanted_line tstr='$tstr'"
                                );
                        }
                        $it->_compare_line( $wanted_line, "Column $i" );
                    }
                    $it->_assert_empty_line();
                }
            }
            $card = $col->pop;
            --$remaining_cards;
        }
        if ( not defined $foundation_idx )
        {
            Carp::confess("\$foundation_idx not set");
        }
        $self->_set_found( $foundation_idx, $card, );
        if ($CHECK_EMPTY)
        {
            if ( $remaining_cards == 0 )
            {
                last MOVES;
            }
        }
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::Golf - verify an entire solution
of black-hole-solve (or a similar solver)

=head1 VERSION

version 0.2601

=head1 SYNOPSIS

    my ( $board_fn, $solution_fn ) = @ARGV;
    my $verifier = Games::Solitaire::Verify::Golf->new(
        {
            board_string => path($board_fn)->slurp_raw(),
            variant => "all_in_a_row",
        }
    );

    open my $fh, '<:encoding(utf-8)', $solution_fn;
    $verifier->process_solution( sub { my $l = <$fh>; chomp $l; return $l; } );
    print "Solution is OK.\n";
    exit(0);

=head1 METHODS

=head2 Games::Solitaire::Verify::Golf->new({board_string=>$str, variant =>"golf"|"all_in_a_row"|"binary_star"|"black_hole"})

Construct a new validator / verifier for the variant and the initial board string.

For golf one can specify:

=over 4

=item * wrap_ranks

=item * queens_on_kings

=back

=head2 $obj->process_solution($line_iter_cb)

Process the solution with the line iterator. Throws an exception if there is an error in it.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Games-Solitaire-Verify>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Solitaire-Verify>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Games-Solitaire-Verify>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/G/Games-Solitaire-Verify>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Games-Solitaire-Verify>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Games::Solitaire::Verify>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-games-solitaire-verify at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Games-Solitaire-Verify>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/fc-solve>

  git clone git://github.com/shlomif/fc-solve.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/fc-solve/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
