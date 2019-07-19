package Games::Solitaire::Verify::VariantsMap;
$Games::Solitaire::Verify::VariantsMap::VERSION = '0.2202';
use strict;
use warnings;

use Games::Solitaire::Verify::VariantParams;

use parent 'Games::Solitaire::Verify::Base';


sub _init
{
    return 0;
}

my %variants_map = (
    "bakers_dozen" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 13,
            'num_freecells'          => 0,
            'sequence_move'          => "limited",
            'seq_build_by'           => "rank",
            'empty_stacks_filled_by' => "none",
        }
    ),
    "bakers_game" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 8,
            'num_freecells'          => 4,
            'sequence_move'          => "limited",
            'seq_build_by'           => "suit",
            'empty_stacks_filled_by' => "any",
        }
    ),
    "beleaguered_castle" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 8,
            'num_freecells'          => 0,
            'sequence_move'          => "limited",
            'seq_build_by'           => "rank",
            'empty_stacks_filled_by' => "any",
        }
    ),
    "cruel" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 12,
            'num_freecells'          => 0,
            'sequence_move'          => "limited",
            'seq_build_by'           => "suit",
            'empty_stacks_filled_by' => "none",
        }
    ),
    "der_katzenschwanz" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 2,
            'num_columns'            => 9,
            'num_freecells'          => 8,
            'sequence_move'          => "unlimited",
            'seq_build_by'           => "alt_color",
            'empty_stacks_filled_by' => "none",
        }
    ),
    "die_schlange" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 2,
            'num_columns'            => 9,
            'num_freecells'          => 8,
            'sequence_move'          => "limited",
            'seq_build_by'           => "alt_color",
            'empty_stacks_filled_by' => "none",
        }
    ),
    "eight_off" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 8,
            'num_freecells'          => 8,
            'sequence_move'          => "limited",
            'seq_build_by'           => "suit",
            'empty_stacks_filled_by' => "kings",
        }
    ),
    "fan" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 18,
            'num_freecells'          => 0,
            'sequence_move'          => "limited",
            'seq_build_by'           => "suit",
            'empty_stacks_filled_by' => "kings",
        }
    ),
    "forecell" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 8,
            'num_freecells'          => 4,
            'sequence_move'          => "limited",
            'seq_build_by'           => "alt_color",
            'empty_stacks_filled_by' => "kings",
        }
    ),
    "freecell" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 8,
            'num_freecells'          => 4,
            'sequence_move'          => "limited",
            'seq_build_by'           => "alt_color",
            'empty_stacks_filled_by' => "any",
        }
    ),
    "good_measure" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 10,
            'num_freecells'          => 0,
            'sequence_move'          => "limited",
            'seq_build_by'           => "rank",
            'empty_stacks_filled_by' => "none",
        }
    ),
    "kings_only_bakers_game" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 8,
            'num_freecells'          => 4,
            'sequence_move'          => "limited",
            'seq_build_by'           => "suit",
            'empty_stacks_filled_by' => "kings",
        }
    ),
    "relaxed_freecell" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 8,
            'num_freecells'          => 4,
            'sequence_move'          => "unlimited",
            'seq_build_by'           => "alt_color",
            'empty_stacks_filled_by' => "any",
        }
    ),
    "relaxed_seahaven_towers" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 10,
            'num_freecells'          => 4,
            'sequence_move'          => "unlimited",
            'seq_build_by'           => "suit",
            'empty_stacks_filled_by' => "kings",
        }
    ),
    "seahaven_towers" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 10,
            'num_freecells'          => 4,
            'sequence_move'          => "limited",
            'seq_build_by'           => "suit",
            'empty_stacks_filled_by' => "kings",
        }
    ),
    "simple_simon" => Games::Solitaire::Verify::VariantParams->new(
        {
            'num_decks'              => 1,
            'num_columns'            => 10,
            'num_freecells'          => 0,
            'sequence_move'          => "limited",
            'seq_build_by'           => "suit",
            'empty_stacks_filled_by' => "any",
            'rules'                  => "simple_simon",
        }
    ),
);


sub calc_variants_map
{
    my $self = shift;

    return \%variants_map;
}


sub get_variant_by_id
{
    my $self = shift;
    my $id   = shift;

    my $map = $self->calc_variants_map();

    if ( !exists( $map->{$id} ) )
    {
        return;
    }
    else
    {
        return $map->{$id}->clone();
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::VariantsMap - a mapping from the variants to
their parameters.

=head1 VERSION

version 0.2202

=head1 FUNCTIONS

=head2 $self->calc_variants_map()

Returns the variants map - a hash reference mapping the variant ID to its
parameters.

=head2 my $variant_params = $self->get_variant_by_id($id)

Returns the variant from its ID or undef if it does not exist.

=head1 PARAMETERS

=head2 Variants IDs

This is a list of the available variant IDs.

=over 4

=item * bakers_dozen

=item * bakers_game

=item * beleaguered_castle

=item * cruel

=item * der_katzenschwanz

=item * die_schlange

=item * eight_off

=item * fan

=item * forecell

=item * freecell

=item * good_measure

=item * kings_only_bakers_game

=item * relaxed_freecell

=item * relaxed_seahaven_towers

=item * seahaven_towers

=item * simple_simon

=back

=head1 SEE ALSO

L<Games::Solitaire::Verify::VariantParams> .

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-solitaire-verifysolution-move at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Solitaire-Verify>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Solitaire::Verify::VariantsMap

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Solitaire-Verify>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Solitaire-Verify>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Solitaire-Verify>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Shlomi Fish.

This program is released under the following license: MIT/Expat
( L<http://www.opensource.org/licenses/mit-license.php> ).

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

  perldoc Games::Solitaire::Verify::VariantsMap

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
