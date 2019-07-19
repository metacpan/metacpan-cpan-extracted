package Games::Solitaire::Verify::Golf;
$Games::Solitaire::Verify::Golf::VERSION = '0.2202';
use strict;
use warnings;
use autodie;


use Carp ();
use List::Util qw/ sum /;

use Games::Solitaire::Verify::Card      ();
use Games::Solitaire::Verify::Column    ();
use Games::Solitaire::Verify::Freecells ();

use parent 'Games::Solitaire::Verify::Base';

__PACKAGE__->mk_acc_ref(
    [
        qw(
            _columns
            _foundation
            _place_queens_on_kings
            _talon
            _variant
            _wrap_ranks
            )
    ]
);

my $MAX_RANK  = 13;
my $NUM_SUITS = 4;

sub _is_golf
{
    my $self = shift;

    return $self->_variant eq 'golf';
}

sub _init
{
    my ( $self, $args ) = @_;

    my $variant = $self->_variant( $args->{variant} );
    if (
        not
        exists { golf => 1, all_in_a_row => 1, black_hole => 1, }->{$variant} )
    {
        Carp::confess("Unknown variant '$variant'!");
    }
    $self->_place_queens_on_kings( $args->{queens_on_kings} // '' );
    $self->_wrap_ranks( $args->{wrap_ranks}                 // '' );
    $self->_foundation(
        Games::Solitaire::Verify::Freecells->new( { count => 1 } ) );
    my $board_string = $args->{board_string};

    my @lines = split( /\n/, $board_string );

    my $_set_found_line = sub {
        my $foundation_str = shift;
        if ( my ($card_s) = $foundation_str =~ m#\AFoundations: (\S{2})\z# )
        {
            $self->_set_found(
                Games::Solitaire::Verify::Card->new( { string => $card_s } ) );
        }
        else
        {
            Carp::confess("Foundations str is '$foundation_str'");
        }
        return;
    };
    my $foundation_str = shift(@lines);
    if ( $self->_variant eq 'golf' )
    {
        if ( $foundation_str !~ s#\ATalon: ((?:\S{2} ){15}\S{2})#$1# )
        {
            die "improper talon line <$foundation_str>!";
        }
        $self->_talon(
            [
                map { Games::Solitaire::Verify::Card->new( { string => $_ } ) }
                    split / /,
                $foundation_str
            ]
        );

        $foundation_str = shift(@lines);
        $_set_found_line->($foundation_str);

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
            $_set_found_line->($foundation_str);
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
    my ( $self, $card ) = @_;
    $self->_foundation->assign( 0, $card );
    return;
}

sub process_solution
{
    my ( $self, $next_line_iter ) = @_;
    my $columns         = $self->_columns;
    my $NUM_COLUMNS     = @$columns;
    my $line_num        = 0;
    my $remaining_cards = sum( map { $_->len } @$columns );

    my $get_line = sub {
        my $ret = $next_line_iter->();
        return ( $ret, ++$line_num );
    };

    my $assert_empty_line = sub {
        my ( $s, $line_idx ) = $get_line->();

        if ( $s ne '' )
        {
            die "Line '$line_idx' is not empty, but '$s'";
        }

        return;
    };

    my ( $l, $first_l ) = $get_line->();

    if ( $l ne "Solved!" )
    {
        die "First line is '$l' instead of 'Solved!'";
    }
    my $IS_GOLF     = $self->_is_golf;
    my $CHECK_EMPTY = ( $IS_GOLF or $self->_variant eq "black_hole" );

    # As many moves as the number of cards.
MOVES:
    for my $move_idx ( 0 .. ( $MAX_RANK * $NUM_SUITS - 1 ) )
    {
        my ( $move_line, $move_line_idx ) = $get_line->();

        my $card;
        if (    $IS_GOLF
            and $move_line =~ m/\ADeal talon\z/ )
        {
            if ( !@{ $self->_talon } )
            {
                die "Talon is empty on line no. $move_line_idx";
            }
            $card = shift @{ $self->_talon };
        }
        elsif ( $move_line !~
            m/\AMove a card from stack ([0-9]+) to the foundations\z/ )
        {
            die
"Incorrect format for move line no. $move_line_idx - '$move_line'";
        }

        my $col_idx = $1;

        if ( !defined $card )
        {
            if ( ( $col_idx < 0 ) or ( $col_idx >= $NUM_COLUMNS ) )
            {
                die "Invalid column index '$col_idx' at $move_line_idx";
            }
        }

        $assert_empty_line->();

        my ( $info_line, $info_line_idx ) = $get_line->();

        if ( $info_line !~ m/\AInfo: Card moved is ([A23456789TJQK][HCDS])\z/ )
        {
            die
"Invalid format for info line no. $info_line_idx - '$info_line'";
        }

        my $moved_card_str = $1;

        $assert_empty_line->();
        $assert_empty_line->();

        my ( $sep_line, $sep_line_idx ) = $get_line->();

        if ( $sep_line !~ m/\A=+\z/ )
        {
            die
"Invalid format for separator line no. $sep_line_idx - '$sep_line'";
        }

        $assert_empty_line->();

        if ( defined $card )
        {
            my $top_card_moved_str = $card->to_string();
            if ( $top_card_moved_str ne $moved_card_str )
            {
                die
"Card moved should be '$top_card_moved_str', but the info says it is '$moved_card_str' at line $info_line_idx";
            }
        }
        else
        {
            my $col                = $columns->[$col_idx];
            my $top_card           = $col->top();
            my $top_card_moved_str = $top_card->to_string();

            if ( $top_card_moved_str ne $moved_card_str )
            {
                die
"Card moved should be '$top_card_moved_str', but the info says it is '$moved_card_str' at line $info_line_idx";
            }

            my $found_card = $self->_foundation->cell(0);
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
                    die
"Cannot put $top_card_moved_str in the foundations that contain "
                        . $found_card->to_string();
                }
            }
            $card = $col->pop;
            --$remaining_cards;
        }

        $self->_set_found($card);
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

version 0.2202

=head1 SYNOPSIS

    my ( $board_fn, $solution_fn ) = @ARGV;
    my $verifier = Games::Solitaire::Verify::Golf->new(
        {
            board_string => path($board_fn)->slurp_raw(),
            variant => "all_in_a_row",
        }
    );

    open my $fh, '<', $solution_fn;
    $verifier->process_solution( sub { my $l = <$fh>; chomp $l; return $l; } );
    print "Solution is OK.\n";
    exit(0);

=head1 METHODS

=head2 Games::Solitaire::Verify::Golf->new({board_string=>$str, variant =>"golf"|"all_in_a_row"|"black_hole"})

Construct a new validator / verifier for the variant and the initial board string.

For golf one can specify:

=over 4

=item * wrap_ranks

=item * queens_on_kings

=back

=head2 $obj->process_solution($line_iter_cb)

Process the solution with the line iterator. Throws an exception if there is an error in it.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/fc-solve/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Games::Solitaire::Verify::Golf

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Games-Solitaire-Verify>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Games-Solitaire-Verify>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Solitaire-Verify>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Games-Solitaire-Verify>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Games-Solitaire-Verify>

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

=cut
