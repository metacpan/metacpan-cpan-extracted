#!/usr/bin/perl -c

package Device::Moose::SCSI;
{
    $Device::Moose::SCSI::AUTHORITY = "cpan:potatogim";
    $Device::Moose::SCSI::VERSION   = "0.13";
};

use Moose;
use namespace::clean    -except => "meta";

use Carp;
use IO::File;
use Fcntl               qw/:mode/;


#-----------------------------------------------------------------------------
#   Attributes
#-----------------------------------------------------------------------------
has "fh" =>
(
    is      => "ro",
    isa     => "FileHandle",
    writer  => "_set_fh",
    clearer => "close",
);

has "name" =>
(
    is     => "ro",
    isa    => "Str",
    writer => "_set_name",
);

has "devs" =>
(
    is      => "ro",
    isa     => "HashRef",
    builder => "_build_devs",
);


#-----------------------------------------------------------------------------
#   Private Methods
#-----------------------------------------------------------------------------
sub _build_devs
{
    my $self = shift;
    my %args = @_;

    my $dh = undef;

    if (!opendir($dh, "/dev"))
    {
        carp "Cannot read /dev: $!";
        return undef;
    }

    my %devs = ();

    foreach my $file (readdir($dh))
    {
        my @stat = lstat("/dev/$file");

        # next if stat() failed
        next unless (scalar(@stat));

        # next if file isn't character special or block device
        next unless (S_ISCHR($stat[2]) || S_ISBLK($stat[2]));

        my $major = int($stat[6] / 256);

        # major number of /dev/sg* is 21 and /dev/sd* is 8
        next unless ($major == 21 || $major == 8);

        my $minor = $stat[6] % 256;

        @{$devs{$file}}{qw/name major minor/} = ($file, $major, $minor);
    }

    return \%devs;
}


#-----------------------------------------------------------------------------
#   Public Methods
#-----------------------------------------------------------------------------
sub enumerate
{
    my $self = shift;
    my %args = @_;

    return sort { $a cmp $b } keys(%{$self->devs});
}

sub open
{
    my $self = shift;
    my %args = @_;

    $self->close() if (defined($self->fh));

    if (defined($args{device}))
    {
        my $fh = IO::File->new("+</dev/$args{device}");

        if (!defined($fh))
        {
            carp "Cannot open $args{device}: $!";
            return -1;
        }

        $self->_set_fh($fh);
        $self->_set_name($args{device});
    }

    return 0;
}

sub execute
{
    my $self = shift;
    my %args = @_;

    my ($command, $wanted, $data) = @args{qw/command wanted data/};

    $data = "" unless(defined($data));

    my $header = pack ("i4 I x16"
        , 36 + length($command) + length($data) # int pack_len
        , 36 + $wanted                          # int reply_len
        , 0                                     # int pack_id
        , 0                                     # int result
        , length($command) == 12 ? 1 : 0);      # unsigned int twelve_byte:1

    my $iobuf = $header . $command . $data;

    my $ret = syswrite($self->fh, $iobuf, length($iobuf));

    if (!defined($ret))
    {
        carp "Cannot write to " . $self->name . ": $!";
        return undef;
    }

    $ret = sysread($self->fh, $iobuf, 36 + $wanted);

    if (!defined($ret))
    {
        carp "Cannot read from " . $self->name . ": $!";
        return undef;
    }

    my @data = unpack("i4 I C16", substr($iobuf, 0, 36));

    return (substr($iobuf, 36), \@data);
}

sub inquiry
{
    my $self = shift;

    my ($model, undef) = $self->execute(
        command => pack("C x3 C x1", 0x12, 0x60)
        , wanted => 96);

    my ($serial, undef) = $self->execute(
        command => pack("C3 x1 C x1", 0x12, 0x01, 0x80, 0x60)
        , wanted => 96);

    my %enq;

    @enq{qw/DEVICE VENDOR PRODUCT REVISION SERIAL/}
        = (unpack("C x7 A8 A16 A4", $model), $serial);

    return \%enq;
}


#-----------------------------------------------------------------------------
#   Life Cycle
#-----------------------------------------------------------------------------
sub BUILD
{
    my $self = shift;
    my $args = shift;

    if (defined($args->{device}))
    {
        $self->open(device => $args->{device});
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Device::Moose::SCSI - Reimplementation of Device::SCSI with Moose.

=head1 SYNOPSIS

    use Device::Moose::SCSI;

    my $device  = Device::Moose::SCSI->new(device => "/dev/sg0");

    # INQUIRY
    my $inquiry = $device->inquiry();

    # TESTUNITREADY
    my ($result, $sense) = $device->execute (
        command => pack("C x5", 0x00)
        , wanted => 32
    );

=head1 DESCRIPTION

C<Device::Moose::SCSI> reimplementation of Device::SCSI using Moose.

See L<Device::SCSI> for detail information.

Refer to L<http://www.tldp.org/HOWTO/archived/SCSI-Programming-HOWTO>
if you need to know how to SCSI programming with Linux.

=head1 ATTRIBUTES

=over

=item B<fh>

=item B<name>

=back

=head1 METHODS

=over

=item B<enumerate>

=item B<open>

=item B<close>

=item B<execute>

=item B<inquiry>

=back

=head2 Lifecycle methods

=over

=item B<BUILD>

=back

=head1 AUTHOR

Ji-Hyeon Gim <potatogim@potatogim.net>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright(c) 2015, by Ji-Hyeon Gim <potatogim@potatogim.net>

This is free software; you can redistribute it and/or modify it
under the same terms as Perl 5 itself at:

L<http://www.perlfoundation.org/artistic_license_2_0>

You may obtain a copy of the full license at:

L<http://www.perl.com/perl/misc/Artistic.html>

=head1 SEE ALSO

L<Device::SCSI>, L<Moose>

=cut
