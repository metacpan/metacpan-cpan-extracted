use strict;
use warnings;

package Footprintless::Plugin::Ldap::ApacheDsLdapUtil;
$Footprintless::Plugin::Ldap::ApacheDsLdapUtil::VERSION = '1.00';
# ABSTRACT: A utility package for ApacheDs specific behaviors
# PODNAME: Footprintless::Plugin::Ldap::ApacheDsLdapUtil;

use Carp;
use Exporter qw(import);
use Net::LDAP::Util qw(canonical_dn);
use Log::Any;

our @EXPORT_OK = qw(
    backup
    copy
    copy_user
    restore
);

my $logger = Log::Any->get_logger();

use constant AUTOMATION_PWD_POLICY_DN => canonical_dn(
    'ads-pwdId=automation,ou=passwordPolicies,ads-interceptorId=authenticationInterceptor,ou=interceptors,ads-directoryServiceId=default,ou=config'
);

sub backup {
    my ( $ldap, $file, %options ) = @_;

    $logger->debugf( 'options=%s', \%options );
    $ldap->with_connection(
        sub {
            _backup_with_connection( $ldap, $file, %options );
        }
    );
}

sub _backup_with_connection {
    my ( $connected_ldap, $file, %options ) = @_;
    $logger->infof( 'exporting from %s', $connected_ldap->to_string() );
    $connected_ldap->export_ldif( $file, %options );
    $logger->trace('ldif export complete');
}

sub copy {
    my ( $ldap_from, $ldap_to, %options ) = @_;

    require File::Spec;
    require Footprintless::Util;
    my $temp_dir = Footprintless::Util::temp_dir();
    my $temp_ldif = File::Spec->catfile( $temp_dir, 'export.ldif' );

    backup( $ldap_from, $temp_ldif, %options );
    restore( $ldap_to, $temp_ldif, %options );

    unlink($temp_ldif);
}

sub copy_user {
    my ( $ldap_from, $ldap_to, %options ) = @_;

    my @email_list = $options{email_list} ? @{ $options{email_list} } : ();
    croak("filter or email(s) required")
        unless ( $options{filter} || @email_list );

    my $filter =
        $options{filter} || scalar(@email_list) == 1
        ? "(mail=$email_list[0])"
        : '(|(mail=' . join( ')(mail=', @email_list ) . '))';

    my $ldif;
    $ldap_from->with_connection(
        sub {
            my @dns = $ldap_from->search_for_list(
                {   attrs  => ['1.1'],
                    filter => $filter,
                    scope  => 'sub',
                },
                sub {
                    return $_[0]->dn();
                }
            );

            _backup_with_connection( $ldap_from, \$ldif, %options );
        }
    );

    $logger->debugf( 'options=%s', \%options );
    $ldap_to->with_connection(
        sub {
            $logger->infof( 'importing to %s', $ldap_to->to_string() );
            $ldap_to->import_ldif(
                \$ldif,
                each_entry => sub {
                    my ($entry) = @_;

                    $logger->infof( 'deleting %s', $entry->dn() );
                    $ldap_to->delete( $entry->dn(), scope => 'base' );

                    _restore_entry( $ldap_to, $entry );
                }
            );
        }
    );
}

sub restore {
    my ( $ldap, $file, %options ) = @_;

    $logger->debugf( 'options=%s', \%options );
    $ldap->with_connection(
        sub {
            _restore_with_connection( $ldap, $file, %options );
        }
    );
}

sub _restore_entry {
    my ( $ldap, $entry ) = @_;

    my $pwd_reset        = $entry->get_value('pwdReset');
    my $pwd_changed_time = $entry->get_value('pwdChangedTime');

    my $is_automation_pwd_policy = 0;
    my $pwd_policy_subentry      = $entry->get_value('pwdPolicySubentry');
    if ($pwd_policy_subentry) {
        my $pwd_policy_dn = $ldap->canonical_dn($pwd_policy_subentry);
        $is_automation_pwd_policy = ( AUTOMATION_PWD_POLICY_DN eq $pwd_policy_dn );
    }

    $entry->delete('pwdChangedTime') if ($pwd_changed_time);
    $ldap->add_or_update($entry);

    if ($pwd_changed_time) {
        my %modifications = ( replace => { 'pwdChangedTime' => $pwd_changed_time } );
        if ( !$pwd_reset && !$is_automation_pwd_policy ) {
            $modifications{'delete'} = ['pwdReset'];
        }
        $ldap->modify( $entry->dn(), %modifications );
    }
}

sub _restore_with_connection {
    my ( $connected_ldap, $file, %options ) = @_;
    $logger->infof( 'deleting from %s: %s', $connected_ldap->to_string(), \%options );
    $connected_ldap->delete( $options{base}, %options );

    $logger->infof( 'importing to %s', $connected_ldap->to_string() );
    $connected_ldap->import_ldif(
        $file,
        each_entry => sub {
            my ($entry) = @_;
            _restore_entry( $connected_ldap, $entry );
        }
    );
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Ldap::ApacheDsLdapUtil; - A utility package for ApacheDs specific behaviors

=head1 VERSION

version 1.00

=head1 SYNOPSIS

Utility methods for working with ApacheDS.

=head1 FUNCTIONS

=head2 backup($ldap, $file, %options)

Performs an 
L<export_ldif|Footprintless::Plugin::Ldap::Ldap/export_ldif($to, %options)>
to C<$file> passing along C<%options>.

=head2 copy($ldap_from, $ldap_to, %options)

Performs a backup of C<$ldap_from> followed by a restore to C<$ldap_to>.  The
C<%options> will be supplied to both calls.

=head2 copy_user($ldap_from, $ldap_to, %options)

Copies one or more user entries from C<$ldap_from> to C<$ldap_to>. The supported 
options are:

=over 4

=item email_list 

An C<ARRAYREF> of email addresses to copy (will be ignored if C<filter> is 
provided).

=item filter 

An ldap filter whose resulting entries will be copied.

=back

=head2 restore($ldap, $file, %options)

Performs an 
L<import_ldif|Footprintless::Plugin::Ldap::Ldap/import_ldif($from, %options)>
from C<$file> passing along C<%options>.

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
