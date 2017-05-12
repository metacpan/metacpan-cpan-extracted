=head1 NAME

Linux::KernelSort - Perl extension for sorting and comparing Linux
kernel versions.  The expected kernel version naming convention is
the same naming convetion demonstrated by http://www.kernel.org.
NOTE:  Currently, only the 2.6.x series of kernels (including -rc's,
-git's, and -mm's) are properly evaluated.

=head1 SYNOPSIS

  use Linux::KernelSort;
  my $kernel = new Linux::KernelSort;

  int $ret;
  my $version1 = "2.6.19";
  my $version2 = "2.6.19-rc2-git7";
  $ret = $kernel->compare($version1, $version2);

  if ($ret == 0) {
    print "$version1 and $version2 are the same version";
  } elsif ($ret > 0) {
    print "$version1 is newer than $version2";
  } else {
    print "$version1 is older than $version2";
  }

  my @kernel_list = [ '2.6.15',
                      '2.6.18',
                      '2.6.18-rc2',
                      '2.6.18-rc2-git2',
                      '2.6.18-mm1',
                      '2.6.18-rc2-mm1' ];

  my @sorted_list = $kernel->sort($kernel_list);

  print "@sorted_list";

=head1 DESCRIPTION

Linux::KernelSort is intended to sort a list of kernel versions into
ascending order.  It also provides the capability to compare
two kernel versions and determine if one version is newer, older,
or the same as the other version.

=head1 FUNCTIONS

=cut

package Linux::KernelSort;

use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = {};
    $self->{debug} = 1;
    bless ($self, $class);
    return $self;
}

=head2 version_check()
    Purpose:  Verify the version is valid and follows the
              proper naming convention demonstrated by
              http://www.kernel.org
    Input:    A string containing the kernel version
    Return:   0 if version is valid
              1 if version is invalid

=cut

sub version_check {
    my $self = shift;
    my $version = shift || return undef;

    if ( $version !~ m/^\d+\.\d+\.\d+(-rc\d+)?(-git\d+)?(-scsi-misc\d+)?(-scsi-rc-fixes\d+)?(-mm\d+)?$/ ) {
        if ( $self->{debug} ) { print "Invalid Kernel Version: $version\n"; }
        return 1;
    }

    return 0;
}

=head2 rank()

    Purpose:  Generate a ranking for a given kernel version
    Input:    A string containing the kernel version which
              follows the proper naming convention demonstrated
              by http://www.kernel.org
    Return:   Kernel ranking

=cut

sub rank {
    my $self = shift;
    my $version = shift || return undef;

    if ( $self->version_check($version) ) {
        return undef;
    }

    $version =~ s/\.//g;
    $version =~ m/^(\d+).*/;
    my $rank = $1;

    if ( $version =~ m/-rc(\d+)/ ) {
        my $rc = $1;
        $rank = $rank - 1;
        $rank = $rank . ".$rc";
    } else {
        $rank = $rank . ".0";
    }

    if ( $version =~ m/-git(\d+)/ ) {
        my $git = $1;
        $rank = $rank . ".$git"
    } else {
        $rank = $rank . ".0";
    }

    if ( $version =~ m/-scsi-misc(\d+)/ ) {
        my $scsi_misc = $1;
        $rank = $rank . ".$scsi_misc"
    } else {
        $rank = $rank . ".0";
    }

    if ( $version =~ m/-scsi-rc-fixes(\d+)/ ) {
        my $rc_fixes = $1;
        $rank = $rank . ".$rc_fixes"
    } else {
        $rank = $rank . ".0";
    }

    if ( $version =~ m/-mm(\d+)/ ) {
        my $mm = $1;
        $rank = $rank . ".$mm";
    } else {
        $rank = $rank . ".0"
    }

    return $rank;
}

=head2 compare()

    Purpose:  Compare two kernel versions
    Input:    Strings ($kernel1, $kernel2) each containing a
              kernel version which follows the proper naming
              conventaion demonstrated by http://www.kernel.org
    Return   -1 if $kernel1 < $kernel2  (ie $kernel1 is older than $kernel2)
              0 if $kernel1 == $kernel2 (ie $kernel1 is the same version as $kernel2)
              1 if $kernel1 > $kernel2  (ie $kernel1 is newer than $kernel2)

=cut

sub compare {
    my $self = shift;
    my $kernel1 = shift || return undef;
    my $kernel2 = shift || return undef;

    my $rank1 = $self->rank($kernel1);
    my $rank2 = $self->rank($kernel2);

    if ( !$rank1 || !$rank2 ) {
        if ( $self->{debug} ) { print "Unable to properly compare kernel versions: $kernel1, $kernel2\n"; }

        if ( !$rank1 && !$rank2 ) {
            return 0;
        } elsif ( !$rank1 ) {
            return -1;
        } else {
            return 1;
        }
    }

    while (length($rank1) && length($rank2)) {
        $rank1 =~ m/^(\d+)\.?(.*)/;
        my $value1 = $1;
        $rank1 = $2;

        $rank2 =~ m/^(\d+)\.?(.*)/;
        my $value2 = $1;
        $rank2 = $2;

        if ($value1 == $value2) {
            next;
        } elsif ($value1 < $value2) {
            return -1;
        } else {
            return 1;
        }
    }

    return 0;
}

=head2 sort()

    Purpose:  Sort a list of kernel versions in ascending order.
              Uses shell sort algorithm.
    Input:    Array of strings containing kernel versions which
              follows the proper naming convention demonstrated
              by http://www.kernel.org
    Return:   Sorted array

=cut

sub sort {
    my $self = shift;
    my (@kernels) = @_;

    my $size = @kernels;
    for (my $gap = int($size/2); $gap > 0; $gap = int($gap/2)) {
        for (my $i = $gap; $i < $size; $i++) {
            for (my $j = $i-$gap; ($j >= 0) && ($self->compare($kernels[$j], $kernels[$j+$gap]) > 0); $j -= $gap) {
                my $temp = $kernels[$j];
                $kernels[$j] = $kernels[$j+$gap];
                $kernels[$j+$gap] = $temp;
            }
        }
    }

    return @kernels;
}

=head1 AUTHOR

Leann Ogasawara <lt>ogasawara@osdl.org<gt>

=head1 COPYRIGHT AND LICENSE

Linux-KernelSort is Copyright (c) 2006, by Leann Ogasawara.
All rights reserved. You may distribute this code under the terms
of either the GNU General Public License or the Artistic License,
as specified in the Perl README file.

=cut

1;

__END__
