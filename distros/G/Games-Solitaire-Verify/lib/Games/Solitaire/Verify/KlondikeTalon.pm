package Games::Solitaire::Verify::KlondikeTalon;
$Games::Solitaire::Verify::KlondikeTalon::VERSION = '0.2202';
use warnings;
use strict;


use parent 'Games::Solitaire::Verify::Base';

use Games::Solitaire::Verify::Exception;
use Games::Solitaire::Verify::Card;

use List::Util qw(first);

__PACKAGE__->mk_acc_ref(
    [
        qw(
            _max_num_redeals
            _num_redeals_so_far
            _undealt_cards
            _waste
            )
    ]
);


sub _input_from_string
{
    my $self = shift;
    my $str  = shift;

    if ( my ($cards_str) = ( $str =~ /\ATalon: (.*)\z/ms ) )
    {
        $self->_undealt_cards(
            [
                map { Games::Solitaire::Verify::Card->new( { string => $_, } ) }
                    split /\s+/,
                $cards_str
            ]
        );
    }
    else
    {
        die "Wrong format - does not start with Talon.";
    }
}

sub _init
{
    my ( $self, $args ) = @_;

    $self->_max_num_redeals( $args->{max_num_redeals} );

    $self->_num_redeals_so_far(0);

    $self->_undealt_cards( [] );
    $self->_waste(         [] );

    if ( exists( $args->{string} ) )
    {
        $self->_input_from_string( $args->{string} );
    }

    return;
}


sub draw
{
    my $self = shift;

    if ( !@{ $self->_undealt_cards() } )
    {
        die "Cannot draw.";
    }

    push @{ $self->_waste() }, shift( @{ $self->_undealt_cards() } );

    return;
}


sub extract_top
{
    my $self = shift;

    if ( !@{ $self->_waste() } )
    {
        die "Cannot extract_top.";
    }

    return pop( @{ $self->_waste() } );
}


sub redeal
{
    my $self = shift;

    if ( @{ $self->_undealt_cards() } )
    {
        die "Cannot redeal while there are remaining cards.";
    }

    if ( $self->_num_redeals_so_far() == $self->_max_num_redeals() )
    {
        die "Cannot redeal because maximal number exceeded.";
    }

    $self->_num_redeals_so_far( $self->_num_redeals_so_far() + 1 );

    push @{ $self->_undealt_cards() }, @{ $self->_waste() };

    $self->_waste( [] );

    return;
}


sub to_string
{
    my $self = shift;

    return join( " ",
        "Talon:", ( map { $_->fast_s() } reverse @{ $self->_waste() } ),
        '==>', ( map { $_->fast_s() } @{ $self->_undealt_cards() } ), '<==', );
}

1;    # End of Games::Solitaire::Verify::KlondikeTalon

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::KlondikeTalon - a class for representing the
talon of Klondike-like games.

=head1 VERSION

version 0.2202

=head1 SYNOPSIS

    use Games::Solitaire::Verify::KlondikeTalon;

    # For internal use.

=head1 METHODS

=head2 $self->draw()

Draw a card from the undealt cards to the waste.

=head2 my $card = $self->extract_top()

Extract the top card and return it.

=head2 $self->redeal()

Redeal the talon after there are no undealt cards.

=head2 my $string = $self->to_string()

Return a string representation of the talon.

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

  perldoc Games::Solitaire::Verify::KlondikeTalon

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
