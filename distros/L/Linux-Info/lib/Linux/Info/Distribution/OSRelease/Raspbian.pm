package Linux::Info::Distribution::OSRelease::Raspbian;

use warnings;
use strict;
use parent 'Linux::Info::Distribution::OSRelease';
use Hash::Util qw(lock_hash unlock_hash);
use Class::XSAccessor getters => {
    get_bug_report_url   => 'bug_report_url',
    get_support_url      => 'support_url',
    get_version_codename => 'version_codename',
};

use constant OUTDATED_VERSION => 0.1;

our $VERSION = '2.16'; # VERSION

# ABSTRACT: a subclass of Linux::Info::Distribution::OSRelease


sub _handle_missing {
    my ( $class, $info_ref ) = @_;
    my %codename_to_version = (
        buzz     => 1.1,
        rex      => 1.2,
        bo       => 1.3,
        hamm     => 2.0,
        slink    => 2.1,
        potato   => 2.2,
        woody    => 3.0,
        sarge    => 3.1,
        etch     => 4.0,
        lenny    => 5.0,
        squeeze  => 6.0,
        wheezy   => 7,
        jessie   => 8,
        stretch  => 9,
        buster   => 10,
        bullseye => 11,
        bookworm => 12,
        trixie   => 13,
        forky    => 14,
    );

    my $codename =
        ( exists $info_ref->{version_codename} )
      ? ( lc $info_ref->{version_codename} )
      : 'none';

    if ( exists $codename_to_version{$codename} ) {
        $info_ref->{version_id} = $codename_to_version{$codename};
    }
    else {
        $info_ref->{version_id} = OUTDATED_VERSION;
    }

    $info_ref->{version} = $info_ref->{version_id} . " ($codename)";
}

sub new {
    my ( $class, $file_path ) = @_;
    my $self = $class->SUPER::new($file_path);
    unlock_hash( %{$self} );

    my @attribs = ( 'bug_report_url', 'support_url', 'version_codename' );

    foreach my $attrib (@attribs) {
        $self->{$attrib} = $self->{cache}->{$attrib};
    }

    $self->clean_cache;
    lock_hash( %{$self} );
    return $self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::Distribution::OSRelease::Raspbian - a subclass of Linux::Info::Distribution::OSRelease

=head1 VERSION

version 2.16

=head1 DESCRIPTION

This subclass extends the attributes available on the parent class based on
what Raspbian GNU Linux makes available.

See the methods to check which additional information is available.

For some reason, Raspbian doesn't provide a version ID, like all other Linux
distributions. Instead, it provides a version codename that matches the ones
used by Debian GNU Linux, which should than be matched in order to retrieve
the version number.

Because of that, this class will require a new update everytime a new version
of Raspbian is released. When there is no related version codename available
(in other words, this class is outdated) the version
C<Linux::Info::Distribution::OSRelease::Raspbian::OUTDATED_VERSION> will be
returned with the instance.

=head1 METHODS

=head2 new

Returns a new instance of this class.

Expects as an optional parameter the complete path to a file that will be used
to retrieve data in the expected format.

=head2 get_bug_report_url

Returns the URL for reporting bugs for this distribution.

=head2 get_support_url

Returns the URL for support on how to get support on this distribution.

=head2 get_version_codename

Returns a string with the codename associated with this distribution version.

=head1 SEE ALSO

=over

=item *

L<https://raspberrytips.com/raspberry-pi-os-versions/>

=item *

L<https://wiki.debian.org/DebianReleases>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
