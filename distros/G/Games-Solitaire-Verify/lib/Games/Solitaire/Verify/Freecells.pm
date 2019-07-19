package Games::Solitaire::Verify::Freecells;
$Games::Solitaire::Verify::Freecells::VERSION = '0.2202';
use warnings;
use strict;


use parent 'Games::Solitaire::Verify::Base';

use Games::Solitaire::Verify::Exception;
use Games::Solitaire::Verify::Card;

use List::Util qw(first);

# _s is the string.
__PACKAGE__->mk_acc_ref(
    [
        qw(
            _count
            _cells
            _s
            )
    ]
);


sub _input_from_string
{
    my $self = shift;
    my $str  = shift;

    if ( $str !~ m{\AFreecells:}gms )
    {
        Games::Solitaire::Verify::Exception::Parse::State::Freecells->throw(
            error => "Wrong Freecell String", );
    }

POS:
    for my $pos ( 0 .. ( $self->count() - 1 ) )
    {
        if ( $str =~ m{\G\z}cg )
        {
            last POS;
        }
        elsif ( $str =~ m{\G  (..)}gms )
        {
            my $card_s = $1;
            $self->assign( $pos, $self->_parse_freecell_card($card_s) );
        }
        else
        {
            Games::Solitaire::Verify::Exception::Parse::State::Freecells
                ->throw( error => "Wrong Freecell String", );
        }
    }
}

sub _init
{
    my ( $self, $args ) = @_;

    if ( !exists( $args->{count} ) )
    {
        die "The count was not specified for the freecells";
    }

    $self->_count( $args->{count} );

    $self->_s( 'Freecells:' . ( '    ' x $self->_count ) );

    $self->_cells( [ (undef) x $self->_count() ] );

    if ( exists( $args->{string} ) )
    {
        return $self->_input_from_string( $args->{string} );
    }

    return;
}

sub _parse_freecell_card
{
    my ( $self, $s ) = @_;

    return (
        ( $s eq q{  } )
        ? undef()
        : Games::Solitaire::Verify::Card->new(
            {
                string => $s,
            }
        )
    );
}


sub count
{
    my $self = shift;

    return $self->_count();
}


sub cell
{
    my ( $self, $idx ) = @_;

    return $self->_cells()->[$idx];
}


sub assign
{
    my ( $self, $idx, $card ) = @_;

    $self->_cells()->[$idx] = $card;
    substr(
        $self->{_s}, length('Freecells:') + ( $idx << 2 ) + 2,
        2, ( defined($card) ? $card->fast_s : '  ' )
    );

    return;
}


sub to_string
{
    ( my $r = $_[0]->{_s} ) =~ s# +\z##;
    return $r;
}


sub cell_clone
{
    my ( $self, $pos ) = @_;

    my $card = $self->cell($pos);

    return defined($card) ? $card->clone() : undef();
}


sub clear
{
    my ( $self, $pos ) = @_;

    $self->assign( $pos, undef() );

    return;
}


sub clone
{
    my $self = shift;

    my $copy = __PACKAGE__->new(
        {
            count => $self->count(),
        }
    );

    foreach my $pos ( 0 .. ( $self->count() - 1 ) )
    {
        $copy->assign( $pos, $self->cell_clone($pos) );
    }

    return $copy;
}


sub num_empty
{
    my $self = shift;

    my $count = 0;

    foreach my $fc_idx ( 0 .. ( $self->count() - 1 ) )
    {
        if ( !defined( $self->cell($fc_idx) ) )
        {
            ++$count;
        }
    }
    return $count;
}

1;    # End of Games::Solitaire::Verify::Freecells

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::Freecells - a class for representing the
Freecells in games such as Freecell, Baker's Game, or Seahaven Towers

=head1 VERSION

version 0.2202

=head1 SYNOPSIS

    use Games::Solitaire::Verify::Freecells;

    # For internal use.

=head1 METHODS

=head2 $self->count()

Returns the number of cells.

=head2 $self->cell($index)

Returns the card in the freecell with the index $index .

=head2 $self->assign($index, $card)

Sets the card in the freecell with the index $index to $card, which
should be a L<Games::Solitaire::Verify::Card> object or undef.

=head2 $self->to_string()

Stringifies the freecells into the Freecell Solver solution display notation.

=head2 $self->cell_clone($pos)

Returns a B<clone> of the card in the position $pos .

=head2 $self->clear($pos)

Clears/empties the freecell at position $pos .

=head2 $board->clone()

Returns a clone of the freecells, with all of their cards duplicated.

=head2 $self->num_empty()

Returns the number of empty freecells.

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

  perldoc Games::Solitaire::Verify::Freecells

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
