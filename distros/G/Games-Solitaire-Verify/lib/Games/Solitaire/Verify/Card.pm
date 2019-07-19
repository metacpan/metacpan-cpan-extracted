package Games::Solitaire::Verify::Card;
$Games::Solitaire::Verify::Card::VERSION = '0.2202';
use warnings;
use strict;


use parent 'Games::Solitaire::Verify::Base';

use Games::Solitaire::Verify::Exception;

__PACKAGE__->mk_acc_ref(
    [
        qw(
            _flipped
            _s
            data
            id
            rank
            suit
            _game
            )
    ]
);


sub _recalc
{
    my ($self) = @_;

    $self->_s( $self->to_string() );

    return;
}

sub _card_num_normalize
{
    my $arg = shift;

    if ( ref($arg) eq "" )
    {
        return +{ map { $_ => $arg } (qw(t non_t)) };
    }
    else
    {
        return $arg;
    }
}

my @card_nums = (
    map { _card_num_normalize($_) } (
        "A",
        ( 2 .. 9 ),
        {
            't'     => "T",
            'non_t' => "10",
        },
        ,
        "J", "Q", "K"
    )
);

my %ranks_map =
    ( map { $card_nums[$_]->{t} => ( $_ + 1 ) } ( 0 .. $#card_nums ) );

my @suits_map_proto = (
    [ "H" => { name => "hearts",   color => "red", }, ],
    [ "C" => { name => "clubs",    color => "black", }, ],
    [ "D" => { name => "diamonds", color => "red", }, ],
    [ "S" => { name => "spades",   color => "black", }, ],
);

my %suits_map = ( map { @$_ } @suits_map_proto );


sub get_suits_seq
{
    my $class = shift;

    return [ map { $_->[0] } @suits_map_proto ];
}


sub calc_rank
{
    my ( $self, $s ) = @_;

    return $ranks_map{$s};
}


sub calc_rank_with_0
{
    my ( $self, $str ) = @_;

    if ( $str eq "0" )
    {
        return 0;
    }
    else
    {
        return $self->calc_rank($str);
    }
}

sub _from_string
{
    my ( $self, $str ) = @_;

    my $is_flipped = 0;

    if ( $str =~ s{\A<(.*)>\z}{$1}ms )
    {
        $is_flipped = 1;
    }

    if ( length($str) != 2 )
    {
        Games::Solitaire::Verify::Exception::Parse::Card->throw(
            error => "string length is too long", );
    }

    my ( $rank, $suit ) = split( //, $str );

    if ( !defined( $self->rank( $self->calc_rank($rank) ) ) )
    {
        Games::Solitaire::Verify::Exception::Parse::Card::UnknownRank->throw(
            error => "unknown rank", );
    }

    if ( exists( $suits_map{$suit} ) )
    {
        $self->suit($suit);
    }
    else
    {
        Games::Solitaire::Verify::Exception::Parse::Card::UnknownSuit->throw(
            error => "unknown suit", );
    }

    $self->set_flipped($is_flipped);

    return;
}

sub _init
{
    my ( $self, $args ) = @_;

    if ( exists( $args->{string} ) )
    {
        $self->_from_string( $args->{string} );
        $self->_recalc();
    }

    if ( exists( $args->{id} ) )
    {
        $self->id( $args->{id} );
    }

    if ( exists( $args->{data} ) )
    {
        $self->data( $args->{data} );
    }

    return;
}


sub color
{
    my ($self) = @_;

    return $self->color_for_suit( $self->suit() );
}


sub color_for_suit
{
    my ( $self, $suit ) = @_;

    return $suits_map{$suit}->{'color'};
}


sub clone
{
    my $self = shift;

    my $new_card = Games::Solitaire::Verify::Card->new();

    $new_card->data( $self->data() );
    $new_card->id( $self->id() );
    $new_card->suit( $self->suit() );
    $new_card->rank( $self->rank() );

    $new_card->_recalc();

    return $new_card;
}


sub _to_string_without_flipped
{
    my $self = shift;

    return $self->rank_to_string( $self->rank() ) . $self->suit();
}

sub to_string
{
    my $self = shift;

    my $s = $self->_to_string_without_flipped();

    return ( $self->is_flipped ? "<$s>" : $s );
}


sub fast_s
{
    return shift->_s;
}


{
    my @_t_nums = ( '0', ( map { $_->{t} } @card_nums ) );

    sub get_ranks_strings
    {
        return \@_t_nums;
    }

    sub rank_to_string
    {
        my ( $class, $rank ) = @_;

        return $_t_nums[$rank];
    }

}


sub is_flipped
{
    return shift->_flipped();
}


sub set_flipped
{
    my ( $self, $v ) = @_;

    $self->_flipped($v);

    $self->_recalc();

    return;
}

1;    # End of Games::Solitaire::Verify::Card

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::Card - a class wrapper for an individual
Solitaire card.

=head1 VERSION

version 0.2202

=head1 SYNOPSIS

    use Games::Solitaire::Verify::Card;

    # Initialise a Queen-of-Hearts
    my $queen_of_hearts = Games::Solitaire::Verify::Card->new(
        {
            string => "QH",
            id => 4,
            data => { %DATA },
        },
    );

=head1 METHODS

=head2 $class->get_suits_seq()

Returns the expected sequence of the suits - "H", "S", "C", "D".

=head2 $class->calc_rank($rank_string)

Calculates the numerical rank of the string passed as argument.

Example:

    my $ten = Games::Solitaire::Verify::Card->calc_rank("T")
    # Prints 10.
    print "$ten\n";

=head2 $class->calc_rank_with_0($rank_string)

Same as calc_rank only supporting "0" as the zero'th card.

=head2 $card->data()

Arbitrary data that is associated with the card. Can hold any scalar.

=head2 $card->id()

A simple identifier that identifies the card. Should be a string.

=head2 $card->rank()

Returns the rank of the card as an integer. Ace is 1, 2-10 are 2-10;
J is 11, Q is 12 and K is 13.

=head2 $card->suit()

Returns "H", "C", "D" or "S" depending on the suit.

=head2 $card->color()

Returns "red" or "black" depending on the rank of the card.

=head2 $card->color_for_suit($suit)

Get the color of the suit $suit (which may be different than the card's suit).

=head2 my $copy = $card->clone();

Clones the card into a new copy.

=head2 $card->to_string()

Converts the card to a string representation.

=head2 $card->fast_s()

A cached string representation. (Use with care).

=head2 $class->rank_to_string($rank_idx)

Converts the rank to a string.

=head2 my [@ranks] = $class->get_ranks_strings()

Returns an (effectively constant) array reference of rank strings.

( Added in version 0.17 .)

=head2 $card->is_flipped()

Determines if the card is flipped.

=head2 $card->set_flipped($flipped_bool)

Sets the card’s flipped status.

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

  perldoc Games::Solitaire::Verify::Card

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
