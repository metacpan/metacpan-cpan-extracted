package Games::Solitaire::Verify::Exception;
$Games::Solitaire::Verify::Exception::VERSION = '0.2202';
use strict;
use warnings;


use Exception::Class (
    'Games::Solitaire::Verify::Exception',
    'Games::Solitaire::Verify::Exception::Parse' =>
        { isa => "Games::Solitaire::Verify::Exception", },
    'Games::Solitaire::Verify::Exception::Parse::FCS' =>
        { isa => "Games::Solitaire::Verify::Exception::Parse", },
    'Games::Solitaire::Verify::Exception::Parse::Card' =>
        { isa => "Games::Solitaire::Verify::Exception::Parse", },
    'Games::Solitaire::Verify::Exception::Parse::Card::UnknownRank' =>
        { isa => "Games::Solitaire::Verify::Exception::Parse::Card", },
    'Games::Solitaire::Verify::Exception::Parse::Card::UnknownSuit' =>
        { isa => "Games::Solitaire::Verify::Exception::Parse::Card", },
    'Games::Solitaire::Verify::Exception::Parse::Column' =>
        { isa => "Games::Solitaire::Verify::Exception::Parse", },
    'Games::Solitaire::Verify::Exception::Parse::Column::Prefix' =>
        { isa => "Games::Solitaire::Verify::Exception::Parse::Column", },
    'Games::Solitaire::Verify::Exception::Parse::State' =>
        { isa => "Games::Solitaire::Verify::Exception::Parse", },
    "Games::Solitaire::Verify::Exception::Parse::State::Foundations" =>
        { isa => "Games::Solitaire::Verify::Exception::Parse::State", },
    "Games::Solitaire::Verify::Exception::Parse::State::Freecells" =>
        { isa => "Games::Solitaire::Verify::Exception::Parse::State", },
    "Games::Solitaire::Verify::Exception::Parse::State::Column" => {
        isa    => "Games::Solitaire::Verify::Exception::Parse::State",
        fields => ["index"],
    },
    "Games::Solitaire::Verify::Exception::State" => {
        isa    => "Games::Solitaire::Verify::Exception",
        fields => ["cards"],
    },
    "Games::Solitaire::Verify::Exception::State::ExtraCards" => {
        isa => "Games::Solitaire::Verify::Exception::State",
    },
    "Games::Solitaire::Verify::Exception::State::MissingCards" => {
        isa => "Games::Solitaire::Verify::Exception::State",
    },
    "Games::Solitaire::Verify::Exception::State::TooHighRank" => {
        isa => "Games::Solitaire::Verify::Exception::State",
    },
    "Games::Solitaire::Verify::Exception::VariantParams::Param" => {
        isa    => "Games::Solitaire::Verify::Exception",
        fields => ["value"],
    },
    "Games::Solitaire::Verify::Exception::VariantParams::Param::NumDecks" => {
        isa => "Games::Solitaire::Verify::Exception::VariantParams::Param",
    },
    "Games::Solitaire::Verify::Exception::VariantParams::Param::EmptyStacksFill"
        => {
        isa => "Games::Solitaire::Verify::Exception::VariantParams::Param",
        },
    "Games::Solitaire::Verify::Exception::VariantParams::Param::Stacks" => {
        isa => "Games::Solitaire::Verify::Exception::VariantParams::Param",
    },
    "Games::Solitaire::Verify::Exception::VariantParams::Param::Freecells" => {
        isa => "Games::Solitaire::Verify::Exception::VariantParams::Param",
    },
    "Games::Solitaire::Verify::Exception::VariantParams::Param::SeqMove" => {
        isa => "Games::Solitaire::Verify::Exception::VariantParams::Param",
    },
    "Games::Solitaire::Verify::Exception::VariantParams::Param::SeqBuildBy" =>
        {
        isa => "Games::Solitaire::Verify::Exception::VariantParams::Param",
        },
    "Games::Solitaire::Verify::Exception::VariantParams::Param::Rules" => {
        isa => "Games::Solitaire::Verify::Exception::VariantParams::Param",
    },

    'Games::Solitaire::Verify::Exception::Variant' => {
        isa    => "Games::Solitaire::Verify::Exception",
        fields => ["variant"],
    },
    'Games::Solitaire::Verify::Exception::Variant::Unknown' =>
        { isa => "Games::Solitaire::Verify::Exception::Variant", },
    'Games::Solitaire::Verify::Exception::VerifyMove' => {
        isa    => "Games::Solitaire::Verify::Exception",
        fields => ["problem"],
    },
    'Games::Solitaire::Verify::Exception::Move' => {
        isa    => "Games::Solitaire::Verify::Exception",
        fields => ["move"],
    },
    'Games::Solitaire::Verify::Exception::Move::Variant::Unsupported' =>
        { isa => "Games::Solitaire::Verify::Exception::Move", },
    'Games::Solitaire::Verify::Exception::Move::NotEnoughEmpties' =>
        { isa => "Games::Solitaire::Verify::Exception::Move", },
    'Games::Solitaire::Verify::Exception::Move::Src' =>
        { isa => "Games::Solitaire::Verify::Exception::Move", },
    'Games::Solitaire::Verify::Exception::Move::Src::Col' =>
        { isa => "Games::Solitaire::Verify::Exception::Move::Src", },
    'Games::Solitaire::Verify::Exception::Move::Src::Col::NoCards' =>
        { isa => "Games::Solitaire::Verify::Exception::Move::Src::Col", },
    'Games::Solitaire::Verify::Exception::Move::Src::Col::NonSequence' => {
        isa    => "Games::Solitaire::Verify::Exception::Move::Src::Col",
        fields => [qw(pos)],
    },
    'Games::Solitaire::Verify::Exception::Move::Src::Col::NotEnoughCards' =>
        { isa => "Games::Solitaire::Verify::Exception::Move::Src::Col", },
    'Games::Solitaire::Verify::Exception::Move::Src::Col::NotTrueSeq' =>
        { isa => "Games::Solitaire::Verify::Exception::Move::Src::Col", },
    'Games::Solitaire::Verify::Exception::Move::Src::Freecell::Empty' =>
        { isa => "Games::Solitaire::Verify::Exception::Move::Src", },
    'Games::Solitaire::Verify::Exception::Move::Dest' =>
        { isa => "Games::Solitaire::Verify::Exception::Move", },
    'Games::Solitaire::Verify::Exception::Move::Dest::Foundation' =>
        { isa => "Games::Solitaire::Verify::Exception::Move::Dest", },
    'Games::Solitaire::Verify::Exception::Move::Dest::Freecell' =>
        { isa => "Games::Solitaire::Verify::Exception::Move::Dest", },
    'Games::Solitaire::Verify::Exception::Move::Dest::Col' =>
        { isa => "Games::Solitaire::Verify::Exception::Move::Dest", },
    'Games::Solitaire::Verify::Exception::Move::Dest::Col::NonMatchSuits' => {
        isa    => "Games::Solitaire::Verify::Exception::Move::Dest::Col",
        fields => [qw(seq_build_by)],
    },
'Games::Solitaire::Verify::Exception::Move::Dest::Col::OnlyKingsCanFillEmpty'
        => { isa => "Games::Solitaire::Verify::Exception::Move::Dest::Col", },
    'Games::Solitaire::Verify::Exception::Move::Dest::Col::RankMismatch' =>
        { isa => "Games::Solitaire::Verify::Exception::Move::Dest::Col", },

);




1;    # End of Games::Solitaire::Verify::Exception

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::Verify::Exception - provides various exception
classes for G::S::Verify.

=head1 VERSION

version 0.2202

=head1 SYNOPSIS

    use Games::Solitaire::Verify::Exception;

=head1 DESCRIPTION

These are L<Exception:Class> exceptions for L<Games::Solitaire::Verify> .

=head1 FUNCTIONS

=head2 new($args)

The constructor. Blesses and calls _init() .

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

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

  perldoc Games::Solitaire::Verify::Exception

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
