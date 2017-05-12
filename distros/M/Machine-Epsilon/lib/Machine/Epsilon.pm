package Machine::Epsilon;
use strict;
use warnings;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(machine_epsilon);    ## no critic (ProhibitAutomaticExportation)

our $VERSION = '1.0.2';

=head1 NAME

Machine::Epsilon - The maximum relative error while rounding a floating point number

=head1 SYNOPSIS


    use Machine::Epsilon; # imports machine_epsilon() automatically

    my $epsilon = machine_epsilon();

=cut

=head1 FUNCTIONS

=head2 machine_epsilon

Returns the rounding error for the machine.

=cut

my $epsilon;

sub machine_epsilon {

    return $epsilon if $epsilon;

    # Machine accuracy for 32-bit floating point number
    my $ma_32bit_23mantissa = 1.0 / (2**23);

    # Machine accuracy for 64-bit floating point number
    my $ma_64bit_52mantissa = 1.0 / (2**52);

    # Machine accuracy for 128-bit floating point number (e.g. IBM AIX)
    my $ma_128bit_105mantissa = 1.0 / (2**112);

    # Always start with a power of 2 to avoid roundoff errors!!
    my $e = 1.0;
    while (1) {
        if (1.0 + $e / 2 == 1.0) { last; }
        $e = $e / 2.0;

        # Accuracy already better than a 128-bit machine!!
        if ($e < $ma_128bit_105mantissa) {
            warn "Machine accuracy seems too good to be true!! "
                . "Do we have such a powerful machine? Assuming that "
                . "something isn't right, and returning machine accuracy "
                . "for 64 bit double.";
            $e = $ma_64bit_52mantissa;
            last;
        }
    }

    # If accuracy is very bad, we return the minimum accuracy for a 32-bit double
    if ($e > $ma_32bit_23mantissa) {
        warn "Machine accuracy ($e greater than $ma_32bit_23mantissa) "
            . "seems worse than the primitive 32-bit double representation. "
            . "Setting to minimum accuracy of $ma_32bit_23mantissa.";
        return $ma_32bit_23mantissa;
    }

    $epsilon = $e;

    return $e;
}

=head1 AUTHOR

binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-machine-epsilon at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Machine-Epsilon>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Machine::Epsilon


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Machine-Epsilon>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Machine-Epsilon>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Machine-Epsilon>

=item * Search CPAN

L<http://search.cpan.org/dist/Machine-Epsilon/>

=back

=head1 REFERENCES

    http://en.wikipedia.org/wiki/Machine_epsilon

=head1 LICENSE AND COPYRIGHT

Copyright 2014 binary.com.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1;    # End of Machine::Epsilon

