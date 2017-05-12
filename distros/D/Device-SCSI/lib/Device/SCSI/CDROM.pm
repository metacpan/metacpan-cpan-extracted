package Device::SCSI::CDROM;
BEGIN {
  $Device::SCSI::CDROM::DIST = 'Device-SCSI';
}
BEGIN {
  $Device::SCSI::CDROM::VERSION = '1.004';
}
# ABSTRACT: Perl module to control SCSI CD-ROM devices
use 5.005;
use warnings;
use strict;
use base 'Device::SCSI';

use Carp;


sub disc_info {
    my $self=shift;
    my($data, $sense)=$self->execute(pack("C x5 C n x", 0x43, 1, 20), 20); # READ TOC
    return if $sense->[0];
    my($first, $last)=unpack("x2 C C", $data);
    return($first, $last);
}


sub toc {
    my $self=shift;

    my($first,$last)=($self->disc_info);
    return unless defined $last;

    my %tracks=(
        FIRST => $first,
        LAST => $last,
    );
    foreach my $track ($first..$last) {
        my($data, $sense)=$self->execute(pack("C x5 C n x", 0x43, $track, 20), 20); # READ TOC
        die "Can't read track $track" if $sense->[0];
        # 2 -> first, 3 -> last 8..11 -> start 16..19 -> end
        my($start, $end)=unpack("x8 N x4 N", $data);
        $tracks{$track}={
            START => $start,
            FINISH => $end
        };
    }
    $tracks{CD}={
        START => $tracks{$first}{START},
        FINISH => $tracks{$last}{FINISH}
    };

    return \%tracks;
}

1;

__END__
=pod

=head1 NAME

Device::SCSI::CDROM - Perl module to control SCSI CD-ROM devices

=head1 VERSION

version 1.004

=head1 SYNOPSIS

 use Device::SCSI::CDROM;
 # use the same way as Device::SCSI but with extra methods.

=head1 DESCRIPTION

This is an incomplete package that may ultimately provide device-specific
support for CD-ROM and other read-only units. The API is poor and may change
at any time.

=head1 METHODS

=head2 disc_info

 my($first, $last) = $device->disc_info;

This returns the track numbers of the first and last track on the CD
inserted in the drive.

=head2 toc

 my $tracks=$device->toc;
 my $first=$tracks->{FIRST};
 my $last=$tracks->{LAST};
 foreach my $track ($first..$last, 'CD') {
     my $trackstart=$tracks->{$track}{START};
     my $trackend=$tracks->{$track}{FINISH};
     # use these values
 }

This reads the Table Of Contents on the CD, and returns a hashref containing
information on all thr tracks on the CD. The keys are:

=head3 FIRST

The number of the first track on the CD.

=head3 LAST

The number of the last track on the CD.

=head3 CD

A hashref with keys B<START> and B<FINISH> mapping to the block numbers of
the start and end of the CD.

=head3 (Numbers 1 ... 99)

A hashref with keys B<START> and B<FINISH> mapping to the block numbers of
the start and end of the track with the same number as the key.

=head1 AUTHOR

Peter Corlett <abuse@cabal.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Peter Corlett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

