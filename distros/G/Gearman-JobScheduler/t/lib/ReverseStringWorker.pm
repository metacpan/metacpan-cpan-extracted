package ReverseStringWorker;

use strict;
use warnings;

use Moose;
with 'Gearman::JobScheduler::AbstractFunction';

use File::Slurp;

# Run job
sub run($;$)
{
    my ($self, $args) = @_;

    my $string = $args->{ string };
    my $write_results_to = $args->{ write_results_to };

    unless (defined $string) {
        die "Operand 'string' must be defined.";
    }

    say STDERR "Going to reverse string '$string'";

    $string = reverse( $string );

    if ( $write_results_to ) {
        say STDERR "Will write results to '$write_results_to'";
        unless ( write_file( $write_results_to, $string )) {
            die "Unable to write to file '$write_results_to'";
        }
    }

    return $string;
}

no Moose;    # gets rid of scaffolding

# Return package name instead of 1 or otherwise worker.pl won't know the name of the package it's loading
__PACKAGE__;
