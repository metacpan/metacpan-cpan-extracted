#
# A tiny pure-perl Mac Alias record class.
# Based on an unattributed text file found floating around
# on the internet, plus further research.
#

package Mac::Alias::Parse;

=head1 NAME

Mac::Alias::Parse - Parse and create Mac Alias records

=head1 SYNOPSIS

 use Mac::Alias::Parse;

 $fields = Mac::Alias::Parse::unpack_alias( $bytes );
 $filename = $fields->{target}->{long_name};
    
 $bytes = Mac::Alias::Parse::pack_alias(
     target => { inode => ..., long_name => ..., createdUTC => ..., ... },
     folder => { ... },
     inode_path => [ ... ],
     ...
 );

=head1 DESCRIPTION

The functions C<unpack_alias()> and C<pack_alias()> convert between an
alias record, as found in various Mac data structures or on disk, and
an easier-to-manipulate Perl data structure.

=cut


# Excerpt from text file:

# ALIAS RECORD STRUCTURE
# A basic record is 150 bytes in length excluding extra info. The Mac
# OS uses colons in file paths instead of forward slashs as used in
# URLs, so the colon can't be used in file, directory nor disk
# names. Also directorys and files have a Mac OS name limit of 31
# characters. Disks have a limit of 27 characters.

# (end excerpt)

# The alias record starts with a length word; it is also self-delimiting
# (the last entry in the "Extra" list is a sentinel). This might be
# a relic of earlier extension efforts (fields being added to the end
# of the fixed structure, before the "Extra" stuff was implemented) or
# it might just be a processing convenience--- not sure.

# The fixed part of the alias record looks like this:
#
# offs len  what
#   6   2   Alias record version (we understand version 2)
#   8   2   Kind of item pointed to (0=file, 1=folder)
#  10   1   Length of volume name
#  11  27   Volume name (padded with NULs)
#  38   4   Volume creation date (seconds since Mac epoch, in local timezone)
#  42   2   Filesystem type ("volume signature", eg kHFSPlusSigWord)[1]
#  44   2   Volume type [2]
#  46   4   Containing folder's File Number (inode)
#  50   1   Filename length
#  51  63   Filename (padded with NULs)
# 114   4   Destination item's File Number (inode)
# 118   4   Item's creation date (seconds since Mac epoch)
# 122   4   Item's creator (FourCharCode)
# 126   4   Item's type (FourCharCode)
# 130   2   Number of levels From [3]
# 132   2   Number of levels To [3]
# 134   4   Volume attribute flags [???]
# 138   2   Volume file system ID (???, typically 0, or 'cu' for network mounts)
# 140  10   Reserved (set to zeroes)

# The fixed part is followed by a series of "extra" fields in a tag-length-
# value style:

#   0   2   Record type/tag (-1 / 65535 indicates end of list)
#   2   2   Length of data field
#   4   .   Data
#   .  0/1  Optional pad with 0 byte to even byte boundary

# Record types/tags:

#   0: Folder name (Carbon-mangled)
#   1: Inode-path to containing folder
#   2: Carbon pathname of file
#   3: AppleShare zone name [4]
#   4: AppleShare server name [4]
#   5: AppleShare user name [4]
#   6: Driver name [4]
#   9: Network mount info
#  10: AppleRemoteAccess dialup info [4]
#  14: Unicode filename [5]
#  15: Unicode volume name [5]
#  16: High-resolution date: volume creation date
#  17: High-resolution date: file creation date
#  18: POSIX path to file, treating volume root as /
#  19: POSIX path of volume mount point
#  20: Recursive alias record of volume's disk image file
#  21: Length of prefix of POSIX path which is user's home directory

# The folder name (record 0) is mangled to fit in the 31-byte
# System 7 HFS-not-plus limit.

# The inode-path (record 1) contains a sequence of 4-byte inode numbers,
# starting with the containing folder and continuing up to the volume's
# root. (The root isn't included; if the containing folder *is* the root,
# this is a zero-length list.) The first value is the same as the folder's
# inode in the fixed portion of the record, if both exist.

# The network mount info record appears to contain a network mount type,
# flags word, and URL of the mount point.

# The high-resolution dates (16 and 17) seem to be normal Mac-epoch dates
# scaled by 2^16. In practice the fractional seconds always seem to
# be zero. Not clear what they are the dates of.

# [1] For reference on volume data types and magic numbers, see TN1150.
# [2] From the textfile: Fixed HD = 0; Network Disk = 1; 400kB FD = 2;
#     800kB FD = 3; 1.4MB FD = 4; Other Ejectable Media = 5
# [3] From and To are unclear to me. If unspecified they are -1 (65535),
#     and in the aliases I've examined they are always -1. The textfile
#     describes them as the number of "directories from alias thru to root"
#     and "directories from root thru to source".
# [4] From textfile.
# [5] These contain a (redundant?) 2-byte length followed by UTF-16-BE data.

# If an inode/fileID is missing (e.g. some network filesystems) it
# is stored as 0xFFFFFFFF.

use strict;
use Exporter   ( );
use Carp       ( 'carp', 'croak' );
use Encode;
use Math::BigInt;
use Math::BigFloat;
use Unicode::Normalize  ( 'NFD', 'NFC' );

our $VERSION    = '0.20';
our @ISA        = 'Exporter';
our @EXPORT_OK  = qw( &unpack_alias &pack_alias );

sub unpack_alias {
    my($bytes) = @_;
    my(%into, %vol, %dir, %targ, $appinfo, $recsize, $version,
       $file_length, $file_name, $vol_length, $vol_name, $extra_ptr,
       @extra);

    ($appinfo, $recsize, $version) = unpack('a4 nn', $bytes);

    warn 'Alias record is truncated'
        if ($recsize > length($bytes) || 150 > length($bytes));
    
    warn "Unexpected alias record version (found $version, expected 2)\n"
        if ($version != 2);

    # Unpack the fixed-length portion of the alias record.
    (
     $targ{'kind'},
     $vol_length, $vol_name,
     @vol{qw( created signature type )},
     $dir{'inode'},
     $file_length, $file_name,
     @targ{qw( inode created type creator )},
     @into{qw( xfrom xto )},
     @vol{qw( flags fsid )},
     $into{'reserved'},
    ) = unpack('x8 n C a27 N a2 nN C a63 NN a4 a4 nnNa2 a10', $bytes);
    $extra_ptr = 150;

    $vol{'name'} = substr($vol_name, 0, $vol_length);
    $targ{'name'} = substr($file_name, 0, $file_length);
    
    $into{'volume'} = \%vol;
    $into{'folder'} = \%dir;
    $into{'target'} = \%targ;
    
    # Remove fields with known "missing value" values
    $into{'appinfo'} = $appinfo unless $appinfo eq "\x00\x00\x00\x00";
    delete $into{'xfrom'} if $into{'xfrom'} == 65535;
    delete $into{'xto'} if $into{'xto'} == 65535;
    delete $targ{'creator'} if $targ{'creator'} eq "\x00\x00\x00\x00";
    delete $targ{'type'} if $targ{'type'} eq "\x00\x00\x00\x00";
    delete $targ{'inode'} if $targ{'inode'} eq 0xFFFFFFFF;
    delete $into{'reserved'} if $into{'reserved'} eq ( "\x00" x 10 );
    delete $vol{'fsid'} if $vol{'fsid'} eq "\x00\x00";
    delete $dir{'inode'} if $dir{'inode'} eq 0xFFFFFFFF;

    # If the extra tag-length-value section exists, parse it
    if (length($bytes) > $extra_ptr) {
        my(@extra);
        
        while(length($bytes) >= (4+$extra_ptr)) {
            
            # Extract the next record
            my($t, $l) = unpack('nn', substr($bytes, $extra_ptr, 4));
            last if $t == 65535;
            my($f) = substr($bytes, 4+$extra_ptr, $l);
            $extra_ptr += 4 + $l;
            $extra_ptr ++ if ( $l % 2 ) != 0;
            
            # Parse a few known record types.
            if ($t == 0) {
                $dir{'name'} = $f;
            } elsif ($t == 1) {
                $into{'inode_path'} = [ unpack('N*', $f) ];
            } elsif ($t == 2) {
                $into{'carbon_path'} = $f;
            } elsif ($t == 9) {
                # Unknown format, but known to be volume info.
                $vol{'9'} = $f;
            } elsif ($t == 14) {
                $targ{'long_name'} = &unpackUC($f);
            } elsif ($t == 15) {
                $vol{'long_name'} = &unpackUC($f);
            } elsif ($t == 16) {
                $vol{'createdUTC'} = &unpackLongTime($f);
            } elsif ($t == 17) {
                $targ{'createdUTC'} = &unpackLongTime($f);
            } elsif ($t == 18) {
                $into{'posix_path'} = $f;
            } elsif ($t == 19) {
                $vol{'posix_path'} = $f;
            } elsif ($t == 20) {
                $vol{'alias'} = &unpack_alias($f);
            } elsif ($t == 21) {
                $into{'posix_homedir_length'} = unpack('n', $f);
            } else {
                push(@extra, $t, $f);
            }
        }
        
        $into{'extra'} = \@extra if @extra;
    }

    \%into;
}

sub pack_alias {
    my(%alis) = @_;

    # Extract the hashes into local copies so we can
    # remove entries as we process them.
    my(%vol, %dir, %targ);
    %vol  = %{ delete $alis{'volume'} } if exists $alis{'volume'};
    %dir  = %{ delete $alis{'folder'} } if exists $alis{'folder'};
    %targ = %{ delete $alis{'target'} } if exists $alis{'target'};

    my($k, $i, @extra, $extra);

    # Populate the fixed-length portion of the record.
    my(@fixed) = (
        (delete $alis{'appinfo'}), undef, 2,
        (delete $targ{'kind'}),
        undef, (delete($vol{'name'})),
        (delete @vol{qw( created signature type )}),
        (delete $dir{'inode'}),
        undef, (delete($targ{'name'})),
        (delete @targ{qw( inode created type creator )}),
        (delete @alis{qw( xfrom xto )}),
        (delete @vol{qw( flags fsid )}),
        (delete $alis{'reserved'})
        );

    # Fail if any required info is missing.
    my(%required) = (
        3 => 'target->{"kind"}',
        5 => 'volume->{"name"}',
        7 => 'volume->{"signature"}',
        8 => 'volume->{"type"}',
        11 => 'target->{"name"}'
        );
    foreach $k (keys %required) {
        croak "Missing value ".$required{$k}
            unless defined($fixed[$k]);
    }

    $fixed[4] = length($fixed[5]);
    $fixed[10] = length($fixed[11]);

    # Fill in any missing values with their appropriate markers.
    my($fc0) = "\x00\x00\x00\x00"; # FourCharCode all zeros
    my(@missings) = (
        $fc0, undef, 2,
        undef, undef, undef,
        0, undef, 5,
        0xFFFFFFFF,
        undef, undef,
        0xFFFFFFFF, 0, $fc0, $fc0,
        0xFFFF, 0xFFFF,
        0, "\x00\x00",
        ( "\x00" x 10 )
        );
    die unless (21 == @fixed) and (@fixed == @missings);
    for($i = 0; $i < 21; $i++) {
        $fixed[$i] = $missings[$i] if !defined $fixed[$i];
    }
    
    # Process any remaining keys into the 'extra' array.
    @extra = ();
    foreach $k (keys %alis) {
        my($v) = $alis{$k};
        if ($k eq 'inode_path') {
            push(@extra, 1, pack('N*', @$v));
        } elsif ($k eq 'carbon_path') {
            push(@extra, 2, $v);
        } elsif ($k eq 'posix_path') {
            push(@extra, 18, Encode::encode('utf8', $v));
        } elsif ($k eq 'posix_homedir_length') {
            push(@extra, 21, pack('n', $v));
        } elsif ($k eq 'extra') {
            push(@extra, @$v);
        } else {
            carp "Unrecognized alias key \"$k\"";
        }
    }
    foreach $k (keys %vol) {
        my($v) = $vol{$k};
        if ($k eq 'long_name') {
            push(@extra, 15, &packUC($v));
        } elsif ($k eq 'posix_path') {
            push(@extra, 19, Encode::encode('utf8', $v));
        } elsif ($k eq 'alias') {
            push(@extra, 20, &pack_alias(%$v));
        } elsif ($k eq 'createdUTC') {
            push(@extra, 16, &packLongTime($v));
        } elsif ($k eq '9') {
            # Unknown format, but known to be volume info.
            push(@extra, 9, $v);
        } else {
            carp "Unrecognized alias key volume->{\"$k\"}";
        }
    }
    foreach $k (keys %dir) {
        my($v) = $dir{$k};
        if ($k eq 'name') {
            push(@extra, 0, $v);
        } else {
            carp "Unrecognized alias key folder->{\"$k\"}";
        }
    }
    foreach $k (keys %targ) {
        my($v) = $targ{$k};
        if ($k eq 'long_name') {
            push(@extra, 14, &packUC($v));
        } elsif ($k eq 'createdUTC') {
            push(@extra, 17, &packLongTime($v));
        } else {
            carp "Unrecognized alias key target->{\"$k\"}";
        }
    }
    
    $extra = '';
    if (@extra) {
        push(@extra, 0xFFFF, '');

        while(@extra) {
            my($t) = shift @extra;
            my($v) = shift @extra;
            $extra .= pack('nn', $t, length($v)) . $v;
            if ((length($v) % 2) == 1) {
                $extra .= "\x00";
            }
        }

    }

    $fixed[1] = 150 + length($extra);
    
    return pack('a4nnn Ca27 Na2nN Ca63 NNa4a4 nnNa2 a10', @fixed) . $extra;
}

sub unpackUC {
    my($buf) = @_;

    my($count) = unpack('n', $buf);
    my($bufsz) = (length($buf) - 2) / 2;
    warn "Unicode string has unexpected count (count=$count, expecting $bufsz)\n"
        if ($count != $bufsz);
    return Encode::decode('utf-16be', substr($buf, 2));
}

sub packUC {
    my($str) = @_;
    my($bytes) = Encode::encode('utf-16be', NFD($str));
    return pack('n', length($bytes)/2) . $bytes;
}

sub unpackLongTime {
    # Precise times are stored in 48.16-fixed-point time format
    # This corresponds to the UTCDateTime format.
    # It represents the number of seconds (and fractional seconds)
    # since the Mac epoch of Jan 1, 1904.
    # The offset from the common POSIX epoch is 2082844800 seconds.
    my($h, $m, $l) = unpack('nNn', $_[0]);
    my($t);
    
    if ($h == 0) {
        $t = $m;
    } else {
        $t = from_hex Math::BigInt '0x'.unpack('H*', substr($_[0], 0, 6));
    }

    return $t if ($l == 0);
    
    $l = new Math::BigFloat $l;
    $l->precision(-5);
    $l->bdiv(65536);
    $l->badd($t);
    return $l;
}

sub packLongTime {
    my($str) = @_;
    my(@x);

    if (@x = ($str =~ /^(\d+):(\d+):(\d+)$/)) {
        return pack('nNn', @x);
    } elsif ($str =~ /^(\d+)(\.\d+)$/) {
        return pack('nNn', 0, int($1), 65536 * ('0' . $2));
    } elsif ($str =~ /^\d+$/) {
        return pack('nNn', 0, $str, 0);
    } else {
        croak "Cannot pack \"$str\" into 48.16-bit time";
    }
}

=head1 CREDITS

The initial information about the structure of alias records was derived
from an unattributed text file found in various places on the internet.

Perl implementation and additional format investigation by Wim Lewis.

=head1 COPYRIGHT

Copyright 2011-2013, Wim Lewis E<lt>wiml@hhhh.orgE<gt>

This software is available under the same terms as perl.

=cut

1;
