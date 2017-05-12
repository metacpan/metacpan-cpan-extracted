use strict;
use warnings;

package Jifty::Plugin::Authentication::Ldap;
use base qw/Jifty::Plugin/;

our $VERSION = '1.01';

=head1 NAME

Jifty::Plugin::Authentication::Ldap - LDAP Authentication Plugin for Jifty

=head1 DESCRIPTION

B<CAUTION:> This plugin is experimental.

This may be combined with the L<User|Jifty::Plugin::User::Mixin::Model::User>
Mixin to provide user accounts and ldap password authentication to your
application.

When a new user authenticates using this plugin, a new User object will be created
automatically.  The C<name> and C<email> fields will be automatically populated
with LDAP data.

in etc/config.yml

  Plugins: 
    - Authentication::Ldap: 
       LDAPhost: ldap.univ.fr           # ldap server
       LDAPbase: ou=people,dc=.....     # base ldap
       LDAPName: displayname            # name to be displayed (cn givenname)
       LDAPMail: mailLocalAddress       # email used optional
       LDAPuid: uid                     # optional


Then create a user model

  jifty model --name=User

and edit lib/App/Model/User.pm to look something like this:

  use strict;
  use warnings;
  
  package Venice::Model::User;
  
  use Jifty::DBI::Schema;
  use Venice::Record schema {
	# More app-specific user columns go here
  };
  
  use Jifty::Plugin::User::Mixin::Model::User;
  use Jifty::Plugin::Authentication::Ldap::Mixin::Model::User;
  
  sub current_user_can {
      my $self = shift;
      my $type = shift;
      my %args = (@_);
      
    return 1 if
          $self->current_user->is_superuser;
    
    # all logged in users can read this table
    return 1
        if ($type eq 'read' && $self->current_user->id);
    
    return $self->SUPER::current_user_can($type, @_);
  };
  
  1;

=head2 ACTIONS

This plugin will add the following actions to your application.
For testing you can access these from the Admin plugin.

=over

=item Jifty::Plugin::Authentication::Ldap::Action::LDAPLogin

The login path is C</ldaplogin>.

=item Jifty::Plugin::Authentication::Ldap::Action::LDAPLogout

The logout path is C</ldaplogout>.

=back

=cut

=head2 METHODS

=head2 prereq_plugins

This plugin depends on the L<User|Jifty::Plugin::User::Mixin::Model::User> Mixin.

=cut


sub prereq_plugins {
    return ('User');
}

use Net::LDAP;


my ($LDAP, %params);

=head2 Configuration

The following options are available in your C<config.yml>
under the Authentication::Ldap Plugins section.

=over

=item C<LDAPhost>

Your LDAP server.

=item C<LDAPbase>

[Mandatory] The base object where your users live. If C<LDAPBindTemplate> is
defined, C<LDAPbase> is only used for user search.

=item C<LDAPBindTemplate>

Alternatively to C<LDAPbase>, you can specify here the whole DN string, with
I<%u> as a placeholder for UID.

=item C<LDAPMail>

The DN that your organization uses to store Email addresses.  This
gets copied into the User object as the C<email>.

=item C<LDAPName>

The DN that your organization uses to store Real Name.  This gets
copied into the User object as the C<name>.

=item C<LDAPuid>

The DN that your organization uses to store the user ID.  Usually C<cn>.
This gets copied into the User object as the C<ldap_id>.

=item C<LDAPOptions>

These options get passed through to L<Net::LDAP>.

Default Options :

 debug   => 0
 onerror => undef
 async   => 1 

Other options you may want :
 
 timeout => 30

See C<Net::LDAP> for a full list.  You can overwrite the defaults
selectively or not at all.

=item C<LDAPLoginHooks>

Optional list of Perl functions that would be called after a successful login
and after a corresponding User object is loaded and updated. The function is
called with a hash array arguments, as follows:

  username => string
  user_object => User object
  ldap => Net::LDAP object
  infos => User attributes as returned by get_infos  

=item C<LDAPFetchUserAttr>

Optional list of LDAP user attributes fetched by get_infos. The values are
returned to the login hook as arrayrefs.

=back

=head2 Example

The following example authenticates the application against a MS Active
Directory server for the domain MYDOMAIN. Each user entry has the attribute
'department' which is used for authorization. C<LDAPbase> is used for user
searching, and binding is done in a Microsoft way. The login hook checks
if the user belongs to specific departments and updates the user record.


 ######
 #   etc/config.yml:  
  Plugins: 
    - User: {}
    - Authentication::Ldap:
       LDAPhost: ldap1.mydomain.com
       LDAPbase: 'DC=mydomain,DC=com'
       LDAPBindTemplate: 'MYDOMAIN\%u'
       LDAPName: displayName
       LDAPMail: mail
       LDAPuid: cn
       LDAPFetchUserAttr:
         - department
       LDAPLoginHooks:
         - 'Myapp::Model::User::ldap_login_hook'

  ######
  #  package Myapp::Model::User;
  sub ldap_login_hook
  {
      my %args = @_;

      my $u = $args{'user_object'};    
      my $department = $args{'infos'}->{'department'}[0];

      my $editor = 0;
      if( $department eq 'NOC' or
          $department eq 'ENGINEERING' )
      {
          $editor = 1;
      }

      $u->__set( column => 'is_content_editor', value => $editor );
  }


  
=cut

sub init {
    my $self = shift;
    my %args = @_;

    $params{'Hostname'} = $args{LDAPhost};
    $params{'bind_template'} = $args{LDAPBindTemplate};
    $params{'base'}     = $args{LDAPbase} or die "Need LDAPbase in plugin config";
    $params{'uid'}      = $args{LDAPuid}     || "uid";
    $params{'email'}    = $args{LDAPMail}    || "";
    $params{'name'}     = $args{LDAPName}    || "cn";
    $params{'login_hooks'} = $args{LDAPLoginHooks}    || [];
    $params{'fetch_attrs'} = $args{LDAPFetchUserAttr} || [];
    
    if( not $params{'bind_template'} ) {
        $params{'bind_template'} = $params{'uid'}.'=%u,'.$params{'base'};
    }
    
    my $opts            = $args{LDAPOptions} || {};

    # Default options for Net::LDAP
    $opts->{'debug'}   = 0       unless defined $opts->{'debug'};
    $opts->{'onerror'} = 'undef' unless defined $opts->{'onerror'};
    $opts->{'async'}   = 1       unless defined $opts->{'async'};
    $params{'opts'}    = $opts;

    $LDAP = Net::LDAP->new($params{Hostname},%{$opts})
        or die "Can't connect to LDAP server ",$params{Hostname};
}

sub LDAP {
    return $LDAP;
}

sub bind_template {
    return $params{'bind_template'};
}

sub base {
    return $params{'base'};
}

sub uid {
    return $params{'uid'};
}

sub email {
    return $params{'email'};
};

sub name {
    return $params{'name'};
};

sub opts {
    return $params{'opts'};
};

sub login_hooks {
    return @{$params{'login_hooks'}};
}

sub get_infos {
    my ($self,$user) = @_;

    my $result = $self->LDAP()->search (
            base   => $self->base(),
            filter => '('.$self->uid().'='.$user.')',
            attrs  =>  [$self->name(),$self->email(), @{$params{'fetch_attrs'}}],
            sizelimit => 1
             );
    $result->code && Jifty->log->error( 'LDAP uid=' . $user . ' ' . $result->error );
    my ($entry) = $result->entries;
    my $ret = {
        dn => $entry->dn(),
        name => $entry->get_value($self->name()),
        email => $entry->get_value($self->email()),
    };    
    foreach my $attr (@{$params{'fetch_attrs'}}) {
        my @val = $entry->get_value($attr);
        $ret->{$attr} = [ @val ];
    }
    return $ret;
};



=head1 SEE ALSO

L<Jifty::Manual::AccessControl>, L<Jifty::Plugin::User::Mixin::Model::User>, L<Net::LDAP>

=head1 AUTHORS

Yves Agostini, <yvesago@cpan.org>, Stanislav Sinyagin

and others authors from Jifty (maxbaker, clkao, sartak, alexmv)

=head1 LICENSE

Copyright 2007-2010 Yves Agostini. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
