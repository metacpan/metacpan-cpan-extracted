package Math::RNG::Microsoft;
$Math::RNG::Microsoft::VERSION = '0.4.0';
use 5.006;
use strict;
use warnings;


use integer;

use parent 'Math::RNG::Microsoft::Base';

use Class::XSAccessor {
    constructor => 'new',
    accessors   => [qw(seed)],
};

sub rand
{
    my $self = shift;
    $self->seed( ( $self->seed() * 214013 + 2531011 ) & (0x7FFF_FFFF) );
    return scalar( ( $self->seed >> 16 ) & 0x7fff );
}

sub _custom_bound
{
    my ( $self, $bigint, $max ) = @_;

    return ( $bigint % $max );
}

sub _private_max_random
{
    my ( $obj, $max ) = @_;

    my $bigint = scalar( $obj->rand() );
    my $result = scalar( $obj->_custom_bound( $bigint, $max ) );

    return $result;
}

sub max_rand
{
    my ( $obj, $max ) = @_;

    my $result = $obj->_private_max_random( $max, );

    return $result;
}


1;    # End of Math::RNG::Microsoft

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::RNG::Microsoft - a pseudo-random number generator compatible
with Visual C.

=head1 VERSION

version 0.4.0

=head1 SYNOPSIS

    use Math::RNG::Microsoft;

    my $randomizer = Math::RNG::Microsoft->new(seed => 24);

    my $random_digit = $randomizer->rand_max(10);

=head1 DESCRIPTION

This is a random number generator used by L<Games::ABC_Path::Generator>, which
emulates the one found in Microsoft's Visual C++. It was utilised here, out
of familiarity and accessibility, because it is commonly used to generate
Freecell layouts in the Freecell world (see
L<http://en.wikipedia.org/wiki/FreeCell_%28Windows%29> ).

B<NOTE:> This is not a cryptologically secure random number generator,
nor is it a particularly good one, so its use is discouraged unless
compatibility with the Windows C Run-time-library is needed.

=head1 SUBROUTINES/METHODS

=head2 new

The constructor. Accepts a numeric seed as an argument.

    my $randomizer = Math::RNG::Microsoft->new(seed => 1);

=head2 $randomizer->rand()

Returns a random integer from 0 up to 0x7fff - 1.

    my $n = $randomizer->rand()

=head2 $randomizer->max_rand($max)

Returns a random integer in the range 0 to ($max-1).

    my $n = $randomizer->max_rand($max);
    # $n is now between 0 and $max - 1.

=head2 $randomizer->seed($seed)

Can be used to re-assign the seed of the randomizer (though not recommended).

=head2 my $array_ref = $randomizer->shuffle(\@array)

Shuffles the array reference of the first argument, B<destroys it> and returns
it. This is using the fisher-yates shuffle.

=head2 my $new_array_ref = $randomizer->fresh_shuffle(\@array)

Copies the array reference of the first argument to a new array, shuffles it
and returns it. This is using the fisher-yates shuffle.

@array remains unchanged.

(Added in version 0.4.0 .)

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Math-RNG-Microsoft>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-RNG-Microsoft>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Math-RNG-Microsoft>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/M/Math-RNG-Microsoft>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Math-RNG-Microsoft>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Math::RNG::Microsoft>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-math-rng-microsoft at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Math-RNG-Microsoft>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/abc-path>

  git clone https://github.com/shlomif/abc-path

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-RNG-Microsoft> or by email
to
L<bug-math-rng-microsoft@rt.cpan.org|mailto:bug-math-rng-microsoft@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
