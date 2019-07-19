package Games::Solitaire::Verify::Move;
$Games::Solitaire::Verify::Move::VERSION = '0.2202';
use warnings;
use strict;


use parent 'Games::Solitaire::Verify::Base';

use Games::Solitaire::Verify::Exception;

__PACKAGE__->mk_acc_ref(
    [
        qw(
            source_type
            dest_type
            source
            dest
            num_cards
            _game
            )
    ]
);


sub _from_fcs_string
{
    my ( $self, $str ) = @_;

    if ( $str =~ m{\AMove a card from stack (\d+) to the foundations\z} )
    {
        my $source = $1;

        $self->source_type("stack");
        $self->dest_type("foundation");

        $self->source($source);
    }
    elsif ( $str =~ m{\AMove a card from freecell (\d+) to the foundations\z} )
    {
        my $source = $1;

        $self->source_type("freecell");
        $self->dest_type("foundation");

        $self->source($source);
    }
    elsif ( $str =~ m{\AMove a card from freecell (\d+) to stack (\d+)\z} )
    {
        my ( $source, $dest ) = ( $1, $2 );

        $self->source_type("freecell");
        $self->dest_type("stack");

        $self->source($source);
        $self->dest($dest);
    }
    elsif ( $str =~ m{\AMove a card from stack (\d+) to freecell (\d+)\z} )
    {
        my ( $source, $dest ) = ( $1, $2 );

        $self->source_type("stack");
        $self->dest_type("freecell");

        $self->source($source);
        $self->dest($dest);
    }
    elsif ( $str =~ m{\AMove (\d+) cards from stack (\d+) to stack (\d+)\z} )
    {
        my ( $num_cards, $source, $dest ) = ( $1, $2, $3 );

        $self->source_type("stack");
        $self->dest_type("stack");

        $self->source($source);
        $self->dest($dest);
        $self->num_cards($num_cards);
    }
    elsif ( $str =~
        m{\AMove the sequence on top of Stack (\d+) to the foundations\z} )
    {
        my $source = $1;

        $self->source_type("stack_seq");
        $self->dest_type("foundation");

        $self->source($source);
    }
    else
    {
        Games::Solitaire::Verify::Exception::Parse::FCS->throw(
            error => "Cannot parse 'FCS' String", );
    }
}

sub _init
{
    my ( $self, $args ) = @_;

    $self->_game( $args->{game} );

    if ( exists( $args->{fcs_string} ) )
    {
        return $self->_from_fcs_string( $args->{fcs_string} );
    }
}


1;    # End of Games::Solitaire::Verify::Move

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::Move - a class wrapper for an individual
Solitaire move.

=head1 VERSION

version 0.2202

=head1 SYNOPSIS

    use Games::Solitaire::Verify::Move;

    my $move1 = Games::Solitaire::Verify::Move->new(
        {
            fcs_string => "Move a card from stack 0 to the foundations",
            game => "freecell",
        },
    );

=head1 FUNCTIONS

=head1 METHODS

=head2 $move->source_type()

Accessor for the solitaire card game's board layout's type -
C<"stack">, C<"freecell">, etc. used in the layout.

=head2 $move->dest_type()

Accessor for the destination type - C<"stack">, C<"freecell">,
C<"destination">.

=head2 $move->source()

The index number of the source.

=head2 $move->dest()

The index number of the destination.

=head2 $move->num_cards()

Number of cards affects - only relevant for a stack-to-stack move usually.

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

  perldoc Games::Solitaire::Verify::Move

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
