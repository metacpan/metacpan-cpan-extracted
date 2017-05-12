package Math::KullbackLeibler::Discrete;
$Math::KullbackLeibler::Discrete::VERSION = '0.07';
use 5.006;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

our @EXPORT = qw(kl);


sub kl {
    my ($P, $Q, %opts) = @_;

    my $eps = 0.00001;

    $eps = $opts{epsilon} if exists $opts{epsilon};

    # Universe
    my $SU = {};
    $SU->{$_}++ for (keys %$P, keys %$Q);

    # | Universe - P |
    my $susp = scalar(keys %$SU) - scalar(keys %$P);

    # | Universe - Q |
    my $susq = scalar(keys %$SU) - scalar(keys %$Q);

    my $pc = $eps * ($susp/scalar(keys %$P));
    my $qc = $eps * ($susq/scalar(keys %$Q));

    my $Pline = sub {
        my $i = shift;
        return exists($P->{$i}) ? $P->{$i} - $pc : $eps;
    };
    my $Qline = sub {
        my $i = shift;
        return exists($Q->{$i}) ? $Q->{$i} - $qc : $eps;
    };

    my $kl = 0;
    for (keys %$SU) {
        $kl += $Pline->($_) * log($Pline->($_) / $Qline->($_));
    }

    return $kl;
}


1; # End of Math::KullbackLeibler::Discrete

__END__

=pod

=encoding utf-8

=head1 NAME

Math::KullbackLeibler::Discrete

=head1 VERSION

version 0.07

=head1 SYNOPSIS

This module computes Kullback-Leibler divergence for two discrete
distributions, using smoothing.

    use Math::KullbackLeibler::Discrete;

    my $P = { a => 1/2, b => 1/4, c => 1/4 };
    my $Q = { a => 7/12, b => 2/12, d => 3/12 };

    my $kl = kl( $P, $Q );

    # optionally set the smoothing epsilon
    my $kl2 = kl( $P, $Q, epsilon => 0.0001 );

    # setting epsilon to 0 results in no smoothing.
    my $kl3 = kl( $P, $Q, epsilon => 0 );

=head1 NAME

Math::KullbackLeibler::Discrete - Computes Kullback-Leibler divergence for two discrete distributes.

=head1 EXPORT

=head2 kl

Computes smoothed KL.

Receives two mandatory arguments: two anonymous hashrefs, that map
events to their probabilities.

Implementation based on the description presented at
L<http://www.cs.bgu.ac.il/~elhadad/nlp09/KL.html>.

The smoothing amount can be specified as parameter:

   kl( $P, $Q, epsilon => 0.001 );

This makes it possible to turn of smoothing, defined epsilon as
zero. However, notice that this will lead to errors in case of
divergent domains.

=head1 AUTHOR

Alberto Simoes, C<< <ambs at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-kullbackleibler-discrete at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-KullbackLeibler-Discrete>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::KullbackLeibler::Discrete

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-KullbackLeibler-Discrete>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-KullbackLeibler-Discrete>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-KullbackLeibler-Discrete>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-KullbackLeibler-Discrete/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Michael Elhadad for making his lecture on-line, so I found a
nice and clean explanation of how this metric could be computed and
implemented.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Alberto Simões.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
