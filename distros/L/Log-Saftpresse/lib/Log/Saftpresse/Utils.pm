package Log::Saftpresse::Utils;

use strict;
use warnings;

# ABSTRACT: class with collection of some utility functions
our $VERSION = '1.6'; # VERSION

use Log::Saftpresse::Constants;

our (@ISA, @EXPORT_OK);

BEGIN {
	require Exporter;

	@ISA = qw(Exporter);
	@EXPORT_OK = qw( &adj_int_units &adj_time_units &get_smh );
}

# Return (value, units) for integer
sub adj_int_units {
    my $value = $_[0];
    my $units = ' ';
    $value = 0 unless($value);
    if($value > $divByOneMegAt) {
        $value /= $oneMeg;
        $units = 'm'
    } elsif($value > $divByOneKAt) {
        $value /= $oneK;
        $units = 'k'
    }
    return($value, $units);
}

# Return (value, units) for time
sub adj_time_units {
    my $value = $_[0];
    my $units = 's';
    $value = 0 unless($value);
    if($value > 3600) {
        $value /= 3600;
        $units = 'h'
    } elsif($value > 60) {
        $value /= 60;
        $units = 'm'
    }
    return($value, $units);
}

# Get seconds, minutes and hours from seconds
sub get_smh {
    my $sec = shift @_;
    my $hr = int($sec / 3600);
    $sec -= $hr * 3600;
    my $min = int($sec / 60);
    $sec -= $min * 60;
    return($sec, $min, $hr);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Utils - class with collection of some utility functions

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
