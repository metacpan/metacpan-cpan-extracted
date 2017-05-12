package IBM::StorageSystem::Quota;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.02';
our @ATTR = qw(cluster device fileset type ID name SL_usage HL_usage used_usage 
SL_inode HL_inode used_inode gracetime_usage gracetime_inode in_doubt_kB last_update);

foreach my $attr ( @ATTR ) { 
        {   
                no strict 'refs';
                *{ __PACKAGE__ .'::'. $attr } = sub {
                        my( $self, $val ) = @_;
                        $self->{$attr} = $val if $val;
                        return $self->{$attr}
                }   
        }   
}

sub new {
        my( $class, $ibm, %args ) = @_; 
        my $self = bless {}, $class;

        defined $args{'Cluster:Device:Type:ID'} 
		or croak 'Constructor failed: mandatory Cluster:Device:Type:ID argument not supplied';

	foreach my $attr ( keys %args ) {
		my $mattr = lc $attr;
		$mattr =~ s/(\(|\))//g;

		foreach my $s ( qw(id hl sl) ) {
			my $u = uc $s;
			$mattr =~ s/(^|_)($s)/$1$u/g
		}

		$self->{$mattr} = $args{$attr} 
	}

	return $self;
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Quota - Class for operations with IBM StorageSystem quota object

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Quota - Class for operations with IBM StorageSystem quota objects

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";
	



=head1 METHODS

=head3 HL_inode

Returns the quota inode hard limit.

=head3 HL_usage

Returns the quota hard limit usage in kilobytes.

=head3 ID

Returns the ID of the user, group or file set, if any.

=head3 SL_inode

Returns the quota inode soft limit.

=head3 SL_usage

Returns the quota soft limit usage in kilobytes.

=head3 cluster

Returns the cluster name on which the quota is imposed.

=head3 device

Returns the device to which the quota is applied.

=head3 fileset

Returns the fileset to which the quota is applied.

=head3 gracetime_inode

Returns the usage time frame within which the user must bring inode usage below the quota.

=head3 gracetime_usage

Returns the usage time frame within which the user must bring disk space usage below the quota.

=head3 in_doubt_kB

Returns the amount of data free space or allocated space on the disk, where the system 
has not updated the quota system yet.

=head3 last_update

Specifies the time when the quota information was updated.

=head3 name

Specifies the user, group or file set name. If the user or group does not exist in the 
configured authentication server (AD or LDAP), this column displays user/group id instead 
of name. Note that NIS is considered as an ID mapping source and is not considered as an 
authentication server when configured with SONAS/StorageSystem Unified, so names exclusive to NIS 
(and not in AD) will display user/group id instead of name.

Similarly for NFS users with user/group names not present in authentication server, this 
column will display the user/group id.

=head3 type

Returns the group-, user- or file set-related quota

=head3 used_inode

Returns the actual usage of inodes for the quota.

=head3 used_usage

Returns the actual usage of disk space for the quota.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-quota at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Quota>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Quota

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Quota>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Quota>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Quota>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Quota/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

