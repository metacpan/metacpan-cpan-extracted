package Logfile::SmartFilter;
use Date::Format;
require Logfile::Base;

use 5.008004;
use strict;
use warnings;

our @ISA = qw(Logfile::Base);

our $VERSION = '0.01';

sub next {
    my $self = shift;
    my $fh   = $self->{Fh};

    my (
        $line,                $time,        $elapsed,
        $remotehost,          $code_status, $bytes,
        $method,              $URL,         $rfc931,
        $peerstatus_peerhost, $type,        $smartfilter_category,
        $date
    );
    while ( $line = <$fh> ) {
        chomp($line);
        (
            $time,        $elapsed, $remotehost,
            $code_status, $bytes,   $method,
            $URL,         $rfc931,  $peerstatus_peerhost,
            $type,        $smartfilter_category
          )
          = split( ' ', $line, 11 );
        last if ($time);
    }

    return undef unless $time;

    #date formating e.g. 01/Nov/2004:18:13:34
    $date = time2str( "%d/%b/%Y:%H:%M:%S", $time );

    Logfile::Base::Record->new(
        Host                 => $remotehost,
        Date                 => $date,
        URL                  => $URL,
        Bytes                => $bytes,
        Elapsed              => $elapsed,
        Code_Status          => $code_status,
        Method               => $method,
        RFC931               => $rfc931,
        Peerstatus_Peerhost  => $peerstatus_peerhost,
        Type                 => $type,
        SmartFilter_Category => $smartfilter_category
    );
}

sub norm {
    my ( $self, $key, $val ) = @_;
    $val;
}

1;
__END__

=head1 NAME

Logfile::SmartFilter - Perl extension for generating reports from Secure Computing's SmartFilter logs.

=head1 SYNOPSIS

  use Logfile::SmartFilter;

=head1 DESCRIPTION

The Logfile::SmartFilter extension will help you to generate various reports from Secure Computing's SmartFilter logs.  The package was customised by subclassing the L<Logfile>::Base package by I<Ulrich Pfeifer>. Please see that module for more information on how to pass logfiles to this module and generate reports.

This module will parse logfiles in the format used by the Cisco Cache Engine appliances with SmartFilter installed.

The following fields are available for reporting:
	Records
        Host
        Date
        URL
        Bytes
        Elapsed
        Code_Status
        Method
        RFC931
        Peerstatus_Peerhost
        Type
        SmartFilter_Category

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.23 with options

  -A
	-B
	-C
	-X
	-n
	Logfile::SmartFilter
	-v
	0.01
	--skip-exporter

=back



=head1 SEE ALSO
L<Logfile> by I<Ulrich Pfeifer>.
L<Date::Format> by I<Graham Barr>.

=head1 AUTHOR

Khurt Williams, E<lt>khurtwilliams@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Khurt Williams

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
