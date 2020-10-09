package Math::GrahamFunction::SqFacts::Dipole;
$Math::GrahamFunction::SqFacts::Dipole::VERSION = '0.02004';
use strict;
use warnings;


use parent qw(Math::GrahamFunction::SqFacts);

use List::Util ();
__PACKAGE__->mk_accessors(qw(result compose));

sub _initialize
{
    my $self = shift;
    my $args = shift;

    $self->result( $args->{result} );
    $self->compose( $args->{compose} );

    return 0;
}


sub clone
{
    my $self = shift;
    return __PACKAGE__->new(
        {
            'result'  => $self->result()->clone(),
            'compose' => $self->compose()->clone(),
        }
    );
}


sub mult_by
{
    my $n_ref = shift;
    my $m_ref = shift;

    $n_ref->result()->mult_by( $m_ref->result() );
    $n_ref->compose()->mult_by( $m_ref->compose() );

    return 0;
}


sub is_square
{
    my $self = shift;
    return $self->result()->is_square();
}


sub exists
{
    my ( $self, $factor ) = @_;

    return $self->result()->exists($factor);
}


sub first
{
    my $self = shift;

    return $self->result()->first();
}


sub factors
{
    my $self = shift;

    return $self->result->factors();
}

sub _get_ret
{
    my $self = shift;

    return [ @{ $self->compose->factors() } ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::GrahamFunction::SqFacts::Dipole - a dipole of two vectors - a result and
a composition.

=head1 VERSION

version 0.02004

=head1 WARNING!

This is a module for Math::GrahamFunction's internal use only.

=head1 METHODS

=head2 my $copy = $dipole->clone()

Clones the dipole returning a new dipole with the clone of the result and the
composition.

=head2 $changing_dipole->mult_by($constant_dipole)

Multiplies the result by the result and the composition by the composition.

=head2 $bool = $dipole->is_square()

Returns whether the result is square.

=head2 $bool = $dipole->exists($factor)

Returns whether the factor exists in the result.

=head2 $first_factor = $dipole->first()

Returns the C<first()> factor of the result vector.

=head2 $factors = $dipole->factors()

Equivalent to C<$dipole->result()->factors()>.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Math-GrahamFunction>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-GrahamFunction>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Math-GrahamFunction>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/M/Math-GrahamFunction>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Math-GrahamFunction>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Math::GrahamFunction>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-math-grahamfunction at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Math-GrahamFunction>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-math-grahamfunction>

  git clone git://github.com/shlomif/perl-math-grahamfunction.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-math-grahamfunction/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
