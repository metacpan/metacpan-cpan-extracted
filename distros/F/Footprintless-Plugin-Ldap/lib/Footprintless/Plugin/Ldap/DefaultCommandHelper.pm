use strict;
use warnings;

package Footprintless::Plugin::Ldap::DefaultCommandHelper;
$Footprintless::Plugin::Ldap::DefaultCommandHelper::VERSION = '1.00';
# ABSTRACT: The default implementation of command helper for ldap
# PODNAME: Footprintless::Plugin::Ldap::DefaultCommandHelper

use Carp;
use Footprintless::Plugin::Ldap::ApacheDsLdapUtil;

sub new {
    return bless( {}, shift )->_init(@_);
}

sub allowed_destination {
    my ( $self, $coordinate ) = @_;
    return 1;
}

sub backup {
    my ( $self, $ldap, $file, %options ) = @_;
    Footprintless::Plugin::Ldap::ApacheDsLdapUtil::backup( $ldap, $file, %options );
}

sub copy {
    my ( $self, $ldap_from, $ldap_to, %options ) = @_;
    Footprintless::Plugin::Ldap::ApacheDsLdapUtil::copy( $ldap_from, $ldap_to, %options );
}

sub copy_user {
    my ( $self, $ldap_from, $ldap_to, %options ) = @_;
    Footprintless::Plugin::Ldap::ApacheDsLdapUtil::copy_user( $ldap_from, $ldap_to, %options );
}

sub _init {
    my ( $self, $footprintless ) = @_;
    $self->{footprintless} = $footprintless;
    return $self;
}

sub locate_file {
    my ( $self, $file ) = @_;
    croak("file not found [$file]") unless ( -f $file );
    return $file;
}

sub restore {
    my ( $self, $ldap, $file, %options ) = @_;
    Footprintless::Plugin::Ldap::ApacheDsLdapUtil::restore( $ldap, $file, %options );
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Ldap::DefaultCommandHelper - The default implementation of command helper for ldap

=head1 VERSION

version 1.00

=head1 CONSTRUCTORS

=head2 new($footprintless)

Creates a new instance.

=head1 METHODS

=head2 allowed_destination($coordinate)

Returns a I<truthy> value if C<$coordinate> is allowed as a destination.

=head2 backup($ldap, $file, %options)

See L<Footprintless::Plugin::Ldap::ApacheDsLdapUtil>.

=head2 copy($ldap_from, $ldap_to, %options)

See L<Footprintless::Plugin::Ldap::ApacheDsLdapUtil>.

=head2 copy_user($ldap_from, $ldap_to, %options)

See L<Footprintless::Plugin::Ldap::ApacheDsLdapUtil>.

=over 4

=back

=head2 locate_file($file)

Returns the path to C<$file>.  Croaks if the file cannot be found.

=head2 restore($ldap, $file, %options)

See L<Footprintless::Plugin::Ldap::ApacheDsLdapUtil>.

=over 4

=back

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless::Plugin::Ldap|Footprintless::Plugin::Ldap>

=item *

L<Footprintless::Plugin::Ldap|Footprintless::Plugin::Ldap>

=item *

L<Footprintless::Plugin::Ldap::Ldap|Footprintless::Plugin::Ldap::Ldap>

=item *

L<Footprintless::Plugin::Ldap::ApacheDsLdapUtil|Footprintless::Plugin::Ldap::ApacheDsLdapUtil>

=back

=cut
