package Games::Solitaire::BlackHole::Solver::_BoardsStream;
$Games::Solitaire::BlackHole::Solver::_BoardsStream::VERSION = '0.18.0';
use strict;
use warnings;
use autodie;

use 5.014;
use Moo;

has '_boardidx' => ( is => 'rw' );
has '_fh'       => ( is => 'rw', default => 0, );
has '_width'    => ( is => 'rw' );

sub _board_fn
{
    my ( $self, ) = @_;

    my $ret = sprintf( "deal%d", $self->_boardidx() );
    $self->_boardidx( 1 + $self->_boardidx() );

    return $ret;
}

sub _my_open
{
    my ( $self, $fn ) = @_;

    open my $read_fh, "<", $fn;
    $self->_fh($read_fh);

    return;
}

sub _fetch
{
    my ( $self, ) = @_;

    my $s = '';
    read( $self->_fh(), $s, $self->_width );
    my $fn = $self->_board_fn();
    if ( eof( $self->_fh() ) )
    {
        close( $self->_fh() );
        $self->_fh(undef);
        $self->_width(0);
    }
    return ( $fn, $s, );
}

sub _reset
{
    my ( $self, $_fn, $_width, $_boardidx, ) = @_;
    $self->_width($_width);
    $self->_boardidx($_boardidx);
    $self->_my_open($_fn);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.18.0

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Games-Solitaire-BlackHole-Solver>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Solitaire-BlackHole-Solver>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Games-Solitaire-BlackHole-Solver>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/G/Games-Solitaire-BlackHole-Solver>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Games-Solitaire-BlackHole-Solver>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Games::Solitaire::BlackHole::Solver>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-games-solitaire-blackhole-solver at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Games-Solitaire-BlackHole-Solver>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/black-hole-solitaire>

  git clone https://github.com/shlomif/black-hole-solitaire

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/black-hole-solitaire/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
