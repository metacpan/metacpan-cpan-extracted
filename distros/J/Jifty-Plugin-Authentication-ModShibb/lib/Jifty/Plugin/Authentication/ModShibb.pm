use strict;
use warnings;

package Jifty::Plugin::Authentication::ModShibb;
use base qw/Jifty::Plugin/;

our $VERSION = '0.03';

=head1 NAME

Jifty::Plugin::Authentication::ModShibb - Shibboleth auth. plugin for Jifty

=head1 DESCRIPTION

This may be combined with the L<Jifty::Plugin::User> plugin to provide user authentication using Shibboleth web single sign-on.
The Shibboleth System is a standards based software package for web single sign-on across or within organizational boundaries. It supports authorization and attribute exchange using the OASIS SAML protocol.
Jifty::Plugin::Authentication::ModShibb requires a C<shibd> service provider which will set required attributes in environment variables.


=head1 CONFIG

 in etc/config.yml

  Plugins: 
    - Authentication::ModShibb:
       mapping:                           # jifty column : shibboleth attribute
         shibb_id: eppn
         email: email
         name: displayName
       authz:  $ENV{'primary_affiliation'} eq 'employee' # shibboleth attribute : value


C<shibb_id> is mandatory and must provide a distinct id for each user

C<name> is highly recommended to display feedback for users

C<email> is highly recommended if you mix shibboleth authentication and other jifty authentication plugins

add in your User Model

 use Jifty::Plugin::Authentication::ModShibb::Mixin::Model::User;

apache

   <Location />
    AuthType shibboleth
    Require shibboleth
   </Location>
     
  <Location /shibblogin>
    ShibRequestSetting applicationId uads
    AuthType shibboleth
    ShibRequestSetting requireSession 1
    require valid-user
   </Location>

For debugging idp and sp config you can add an apache authentication on C</shibb_test> location.

=head1 METHODS

=head2 prereq_plugins

This plugin depends on the L<User|Jifty::Plugin::User> plugin.

=cut


sub prereq_plugins {
    return ('User');
}

__PACKAGE__->mk_accessors(qw(shibb_mapping shibb_mandatory shibb_authz));


=head2 init

load config 

=cut


sub init {
    my $self = shift;
    my %args = @_;
    $self->shibb_mapping( $args{mapping} );
    $self->shibb_authz( $args{authz} );

    my @mandatory = ();
    foreach my $val (values %{$args{mapping}} ) {
        push @mandatory, $val;
    };
    if ( $args{authz}) {
        push @mandatory, $1 while $args{authz}=~m/ENV{'?(.*?)'?}/g;
    };
    $self->shibb_mandatory(@mandatory);
};


=head1 SEE ALSO

L<Jifty::Manual::AccessControl>, L<Jifty::Plugin::User>, L<Shibboleth::SP>

=head1 AUTHOR

Yves Agostini, <yvesago@cpan.org>

=head1 LICENSE

Copyright 2011, Yves Agostini <yvesago@cpan.org>. 

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
