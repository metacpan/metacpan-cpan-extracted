package Games::Solitaire::Verify::Column;
$Games::Solitaire::Verify::Column::VERSION = '0.2202';
use warnings;
use strict;


use parent 'Games::Solitaire::Verify::Base';

use Games::Solitaire::Verify::Exception;
use Games::Solitaire::Verify::Card;

__PACKAGE__->mk_acc_ref(
    [
        qw(
            _cards
            _s
            )
    ]
);


sub _from_string
{
    my ( $self, $str ) = @_;

    if ( $str !~ s{\A:(?: )?}{} )
    {
        Games::Solitaire::Verify::Exception::Parse::Column::Prefix->throw(
            error => "String does not start with \": \"", );
    }

    # Ignore trailing whitespace, so we don't have -1.
    my @cards = split( / +/, $str );

    $self->_cards(
        [
            map { Games::Solitaire::Verify::Card->new( { string => $_ } ) }
                @cards
        ]
    );

    $self->_recalc;

    return;
}

sub _init
{
    my ( $self, $args ) = @_;

    if ( exists( $args->{string} ) )
    {
        return $self->_from_string( $args->{string} );
    }
    elsif ( exists( $args->{cards} ) )
    {
        $self->_cards( $args->{cards} );

        $self->_recalc;
        return;
    }
    else
    {
        die "Cannot init - no 'string' or 'cards' specified.";
    }
}


sub len
{
    my $self = shift;

    return scalar( @{ $self->_cards() } );
}


sub pos
{
    my $self = shift;
    my $idx  = shift;

    return $self->_cards->[$idx];
}


sub top
{
    my $self = shift;

    return $self->pos(-1);
}


sub clone
{
    my $self = shift;

    my $new_col = Games::Solitaire::Verify::Column->new(
        {
            cards => [ map { $_->clone() } @{ $self->_cards() } ],
        }
    );

    return $new_col;
}


sub append_cards
{
    my ( $S, $c ) = @_;
    push @{ $S->_cards() }, @$c;
    $S->_recalc;
    return;
}


sub append
{
    my ( $self, $more_cards ) = @_;

    my $more_copy = $more_cards->clone();

    return $self->append_cards( $more_copy->_cards );
}


sub push
{
    my ( $self, $card ) = @_;

    push @{ $self->_cards() }, $card;

    $self->_recalc;

    return;
}


sub pop
{
    my $self = shift;

    my $card = pop( @{ $self->_cards() } );

    $self->_recalc;

    return $card;
}


sub popN
{
    my ( $S, $c ) = @_;

    my @r = splice( @{ $S->_cards() }, -$c );

    $S->_recalc;

    return \@r;
}


sub _recalc
{
    my $self = shift;

    $self->_s(
        join( ' ', ':', ( map { $_->fast_s() } @{ $self->_cards() } ) ) );

    return;
}

sub to_string
{
    return shift->_s;
}

1;    # End of Games::Solitaire::Verify::Column

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::Column - a class wrapper for Solitaire
columns that are composed of a sequence of cards.

=head1 VERSION

version 0.2202

=head1 SYNOPSIS

    use Games::Solitaire::Verify::Column;

    # Initialise a column
    my $column = Games::Solitaire::Verify::Column->new(
        {
            string => ": KH QS 5C",
        },
    );

    # Prints 3
    print $column->len();

    my $queen_card = $column->pos(1);

=head1 METHODS

=head2 $column->len()

Returns an integer representing the number of cards in the column.

=head2 $column->pos($idx)

Returns the card (a L<Games::Solitaire::Verify::Card> object)
at position $idx in Column. $idx starts at 0.

=head2 $column->top()

Returns the top card.

=head2 $column->clone()

Returns a clone of the column.

=head2 $base_column->append_cards(\@cards)

Appends the cards in the argument array reference to the column.

( Added in version 0.17 .)

=head2 $base_column->append($column_with_more_cards)

Appends the column $column_with_more_cards to $base_column . B<NOTE:>
append_cards() is faster.

=head2 $column->push($card)

Appends a single card to the top of the column.

=head2 my $card_at_top = $column->pop()

Pops a card from the top of the column and returns it.

=head2 my [@cards] = $column->popN($num_cards)

Pops $num_cards cards from the top of the column and returns them (as an
array reference) in their original order in the column.

( Added in version 0.17 .)

=head2 $column->to_string()

Converts to a string.

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

  perldoc Games::Solitaire::Verify::Column

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
