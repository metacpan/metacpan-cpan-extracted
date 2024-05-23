package Linux::Info::KernelSource;

use warnings;
use strict;
use Carp qw(confess);

our $VERSION = '2.11'; # VERSION

# ABSTRACT: defines the files that are source of kernel information


sub new {
    my ( $class, $opts_ref ) = @_;
    my $self;

    if ( ( defined($opts_ref) ) and ( ref $opts_ref eq 'HASH' ) ) {
        $self = {
            sys_osrelease => $opts_ref->{sys_osrelease}
              || '/proc/sys/kernel/osrelease',
            version           => $opts_ref->{version} || '/proc/version',
            version_signature => $opts_ref->{version_signature}
              || '/proc/version_signature',
        };
    }
    else {
        $self = {
            sys_osrelease     => '/proc/sys/kernel/osrelease',
            version           => '/proc/version',
            version_signature => '/proc/version_signature',
        };
    }

    bless $self, $class;
    return $self;
}


sub get_sys_osrelease {
    my $self = shift;
    my $file = $self->{sys_osrelease};
    open( my $in, '<', $file ) or confess "Cannot read $file: $!";
    my $release = <$in>;
    chomp $release;
    close($in) or confess "Cannot close $file: $!";
    return $release;
}


sub get_version {
    my $self = shift;
    my $file = $self->{version};
    open( my $in, '<', $file ) or confess "Cannot read $file: $!";
    my $line = <$in>;
    chomp $line;
    close($in) or confess "Cannot close $file: $!";
    return $line;
}


sub get_version_signature {
    my $self   = shift;
    my $source = $self->{version_signature};
    my $line;

    if ( -r $source ) {
        open( my $in, '<', $source ) or confess("Cannot read $source: $!");
        $line = <$in>;
        chomp $line;
        close($in) or confess("Cannot close $source: $!");
    }
    else {
        confess "Missing $source, which is supposed to exists on Ubuntu!";
    }

    return $line;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::KernelSource - defines the files that are source of kernel information

=head1 VERSION

version 2.11

=head1 METHODS

=head2 new

Creates a instance.

Optionally, can receive a hash reference to configure customized paths
instead of the default ones.

The expected keys/values are:

=over

=item *

C<sys_osrelease>: path to a corresponding F</proc/sys/kernel/osrelease> file path.

=item *

C<version>: path to a corresponding F</proc/version> file path.

=item *

C<version_signature>: path to a corresponding F</proc/version_signature> file
path. This one is specific to Ubuntu Linux.

=back

=head2 get_sys_osrelease

Getter for the C<sys_osrelease> file path content.

=head2 get_version

Getter for the C<version> file path content.

=head2 get_version_signature

Getter for the C<version_signature> file path content.

=head1 SEE ALSO

=over

=item *

L<Linux::Info::KernelRelease> and subclasses.

=item *

https://ubuntu.com/kernel

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
