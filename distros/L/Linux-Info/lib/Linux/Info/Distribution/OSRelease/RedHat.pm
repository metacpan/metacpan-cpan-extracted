package Linux::Info::Distribution::OSRelease::RedHat;

use warnings;
use strict;
use base 'Linux::Info::Distribution::OSRelease';
use Hash::Util qw(lock_hash unlock_hash);
use Class::XSAccessor getters => {
    get_platform_id                     => 'platform_id',
    get_ansi_color                      => 'ansi_color',
    get_cpe_name                        => 'cpe_name',
    get_bug_report_url                  => 'bug_report_url',
    get_support_end                     => 'support_end',
    get_redhat_bugzilla_product         => 'redhat_bugzilla_product',
    get_redhat_bugzilla_product_version => 'redhat_bugzilla_product_version',
    get_redhat_support_product          => 'redhat_support_product',
    get_redhat_support_product_version  => 'redhat_support_product_version',
};

our $VERSION = '2.18'; # VERSION

# ABSTRACT: a subclass of Linux::Info::Distribution::OSRelease


sub new {
    my ( $class, $file_path ) = @_;
    my $self = $class->SUPER::new($file_path);
    unlock_hash( %{$self} );

    my @attribs = (
        'platform_id',                     'ansi_color',
        'cpe_name',                        'bug_report_url',
        'support_end',                     'redhat_bugzilla_product',
        'redhat_bugzilla_product_version', 'redhat_support_product',
        'redhat_support_product_version',
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

Linux::Info::Distribution::OSRelease::RedHat - a subclass of Linux::Info::Distribution::OSRelease

=head1 VERSION

version 2.18

=head1 DESCRIPTION

This subclass extends the attributes available on the parent class based on
what RedHat makes available.

See the methods to check which additional information is available.

=head1 METHODS

=head2 new

Returns a new instance of this class.

Expects as an optional parameter the complete path to a file that will be used
to retrieve data in the expected format.

=head2 get_platform_id

Returns the string of platform ID.

=head2 get_ansi_color

Returns the string of the respective ANSI color code.

=head2 get_cpe_name

Returns the CPE name.

=head2 get_bug_report_url

Returns the URL to report bugs for the distribution.

=head2 get_support_end

Returns a string of the data when the support for this distribution will end.

=head2 get_redhat_bugzilla_product

Returns a string of the RedHat product for support.

=head2 get_redhat_bugzilla_product_version

Returns a string of the RedHat product version for support.

=head2 get_redhat_support_product

Returns a string of the RedHat product for support.

=head2 get_redhat_support_product_version

Returns a string of the RedHat product version for support.

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
