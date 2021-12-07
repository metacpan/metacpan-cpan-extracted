package Freecell::Deal::MS;
$Freecell::Deal::MS::VERSION = '0.0.1';
use strict;
use warnings;

use Math::RNG::Microsoft ();

use Class::XSAccessor {
    constructor => 'new',
    accessors   => [qw(deal)],
};

sub as_str
{
    my ($self) = @_;

    my @cards = (
        map {
            my $s = $_;
            map { $s . $_ } qw/C D H S/;
        } ( 'A', ( 2 .. 9 ), 'T', 'J', 'Q', 'K' )
    );
    Math::RNG::Microsoft->new( seed => scalar( $self->deal ) )
        ->shuffle( \@cards );
    my @lines = ( map { [ ':', ] } 0 .. 7 );
    my $i     = 0;
    while (@cards)
    {
        push @{ $lines[$i] }, pop(@cards);
        $i = ( ( $i + 1 ) & 7 );
    }
    my $str = join "", map { "@$_\n" } @lines;
    return $str;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Freecell::Deal::MS - deal Windows FreeCell / FC Pro layouts

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    use Freecell::Deal::MS ();

    {

        my $obj = Freecell::Deal::MS->new( deal => 240 );

        # TEST
        ok( $obj, "object" );

        # TEST
        is( $obj->as_str(), <<'EOF', 'as_str 240' );
    : JH 9C 5S KC 6S 2H AS
    : 5D 3D 9S 2S 3C AD 8C
    : 8S 5C KD QC 3H 4D 3S
    : 7S AC 9H 6C QH KS 4H
    : KH JD 7D 4C 8H 6H
    : TS TC 4S 5H QD JS
    : 9D JC 2C QS TH 2D
    : AH 7C 6D 8D TD 7H
    EOF
=head1 DESCRIPTION

=head1 METHODS

=head2 Freecell::Deal::MS->new(deal => 11982)

Constructor.

=head2 $obj->as_str()

Returns the deal layout as a string.

=head2 $obj->deal()

B<For internal use!>

=head1 LIMITATIONS

Does not handle deals above 2 Gi .

=head1 SEE ALSO

L<https://github.com/shlomif/fc-solve/blob/master/fc-solve/source/board_gen/make_multi_boards.c>

L<https://pypi.org/project/pysol-cards/>

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Freecell-Deal-MS>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Freecell-Deal-MS>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Freecell-Deal-MS>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/F/Freecell-Deal-MS>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Freecell-Deal-MS>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Freecell::Deal::MS>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-freecell-deal-ms at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Freecell-Deal-MS>. You will be automatically notified of any
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

This software is Copyright (c) 2021 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
