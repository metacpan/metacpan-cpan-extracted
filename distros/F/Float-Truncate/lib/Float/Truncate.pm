package Float::Truncate;

use strict;
use 5.008_005;
our $VERSION = '0.03';
use vars qw/@ISA @EXPORT @EXPORT_OK/;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw/truncate truncate_force/;

sub truncate {
    my ( $number, $length ) = @_;
    return $number unless defined $length;
    return sprintf "%.${length}f", $number;
}

sub truncate_force {
    my ( $number, $length ) = @_;
    return $number unless defined $length;

    $length = 10**$length;
    return int( $number * $length ) / $length;
}

1;
__END__

=encoding utf-8

=head1 NAME

Float::Truncate - Ttruncate Float decimal length by special length

=head1 SYNOPSIS

  use Float::Truncate qw/truncate truncate_force/;

=head1 DESCRIPTION

Float::Truncate is used for truncate float decimal length

    use Float::Truncate qw/truncate truncate_force/;

    my $float = 1.556;

    print truncate( $float, 2 );       # output 1.56
    print truncate_force( $float, 2 ); # output 1.55

    # If not special length argument, will original float number.
    print truncate( $float );          # output 1.556

=head1 AUTHOR

MC Cheung E<lt>mc.cheung@aol.comE<gt>

=head1 COPYRIGHT

Copyright 2018- MC Cheung

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

