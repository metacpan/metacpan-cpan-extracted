package Games::Solitaire::Verify::HorneAutomovePrune;
$Games::Solitaire::Verify::HorneAutomovePrune::VERSION = '0.2202';
use strict;
use warnings;

sub _calc_foundation_to_put_card_on
{
    my ( $running_state, $card ) = @_;

DECKS_LOOP:
    for my $deck ( 0 .. $running_state->num_decks() - 1 )
    {
        if ( $running_state->get_foundation_value( $card->suit(), $deck ) ==
            $card->rank() - 1 )
        {
            for my $other_deck_idx (
                0 .. ( ( $running_state->num_decks() << 2 ) - 1 ) )
            {
                if (
                    $running_state->get_foundation_value(
                        $card->get_suits_seq->[ $other_deck_idx % 4 ],
                        ( $other_deck_idx >> 2 ),
                    ) < $card->rank() - 2 - (
                        (
                            $card->color_for_suit(
                                $card->get_suits_seq->[ $other_deck_idx % 4 ]
                            ) eq $card->color()
                        ) ? 1 : 0
                    )
                    )
                {
                    next DECKS_LOOP;
                }
            }
            return [ $card->suit(), $deck ];
        }
    }
    return;
}

sub perform_and_output_move
{
    my ($args)            = @_;
    my $running_state     = $args->{state};
    my $out_running_state = $args->{output_state};
    my $out_move          = $args->{output_move};
    my $move_s            = $args->{move_string};
    $out_move->($move_s);
    $running_state->verify_and_perform_move(
        Games::Solitaire::Verify::Move->new(
            {
                fcs_string => $move_s,
                game       => $running_state->_variant(),
            },
        )
    );
    $out_running_state->($running_state);

    return;
}

sub _check_for_prune_move
{
    my ( $running_state, $card, $prune_move, $out_running_state, $out_move ) =
        @_;

    if ( defined($card) )
    {
        my $f = _calc_foundation_to_put_card_on( $running_state, $card );

        if ( defined($f) )
        {
            perform_and_output_move(
                {
                    state        => $running_state,
                    move_string  => $prune_move,
                    output_state => $out_running_state,
                    output_move  => $out_move
                }
            );
            return 1;
        }
    }

    return 0;
}

sub do_prune
{
    my ($args)            = @_;
    my $running_state     = $args->{state};
    my $out_running_state = $args->{output_state};
    my $out_move          = $args->{output_move};
PRUNE:
    while (1)
    {
        my $num_moved = 0;
        foreach my $idx ( 0 .. ( $running_state->num_columns() - 1 ) )
        {
            my $col = $running_state->get_column($idx);

            $num_moved += _check_for_prune_move(
                $running_state,
                scalar( $col->len() ? $col->top() : undef() ),
                "Move a card from stack $idx to the foundations",
                $out_running_state,
                $out_move,
            );
        }

        foreach my $idx ( 0 .. ( $running_state->num_freecells() - 1 ) )
        {
            $num_moved += _check_for_prune_move(
                $running_state,
                $running_state->get_freecell($idx),
                "Move a card from freecell $idx to the foundations",
                $out_running_state,
                $out_move,
            );
        }
        last PRUNE if $num_moved == 0;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::HorneAutomovePrune - perform Horne Autoplay
on a Freecell layout

=head1 VERSION

version 0.2202

=head1 DESCRIPTION

See L<https://groups.yahoo.com/neo/groups/fc-solve-discuss/search/messages?query=horne%20autoplay> .

=head1 SUBROUTINES

=head2 do_prune({%args})

Perform a Horne prune on the state and mutate it, while emitting intermediate
states and moves.

=head2 perform_and_output_move({%args})

Perform and output the move on the state.

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

  perldoc Games::Solitaire::Verify::HorneAutomovePrune

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
