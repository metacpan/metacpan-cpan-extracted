package Linux::Info::Distribution::OSRelease::Ubuntu;

use warnings;
use strict;
use base 'Linux::Info::Distribution::OSRelease';
use Hash::Util qw(lock_hash unlock_hash);
use Class::XSAccessor getters => {
    get_version_codename   => 'version_codename',
    get_support_url        => 'support_url',
    get_bug_report_url     => 'bug_report_url',
    get_privacy_policy_url => 'privacy_policy_url',
    get_ubuntu_codename    => 'ubuntu_codename',
};

our $VERSION = '2.18'; # VERSION

# ABSTRACT: a subclass of Linux::Info::Distribution::OSRelease


sub new {
    my ( $class, $file_path ) = @_;
    my $self = $class->SUPER::new($file_path);
    unlock_hash( %{$self} );

    my @attribs = (
        'version_codename', 'support_url',
        'bug_report_url',   'privacy_policy_url',
        'ubuntu_codename',
    );

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

Linux::Info::Distribution::OSRelease::Ubuntu - a subclass of Linux::Info::Distribution::OSRelease

=head1 VERSION

version 2.18

=head1 DESCRIPTION

This subclass extends the attributes available on the parent class based on
what Ubuntu makes available.

See the methods to check which additional information is available.

=head1 METHODS

=head2 new

Returns a new instance of this class.

Expects as an optional parameter the complete path to a file that will be used
to retrieve data in the expected format.

=head2 get_version_codename

Returns the Ubuntu codename for the released version.

=head2 get_support_url

Returns the URL with support information about Ubuntu.

=head2 get_bug_report_url

Returns the URL with details on how to report bugs on Ubuntu.

=head2 get_privacy_policy_url

Returns the URL with the privacy policy of Ubuntu.

=head2 get_ubuntu_codename

Returns a string the Ubuntu codename, based on the version.

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
