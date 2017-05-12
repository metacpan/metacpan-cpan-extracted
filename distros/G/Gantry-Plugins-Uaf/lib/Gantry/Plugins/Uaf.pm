package Gantry::Plugins::Uaf;

use strict; 
use warnings;

use Gantry;
use Gantry::Utils::Crypt;
use File::Spec;

use base 'Exporter';
our @EXPORT = qw( 
    uaf_init
    uaf_user
    uaf_authn
    uaf_authz
    uaf_inited
    uaf_authenicate
    do_login
    do_logout
);

our $VERSION = '0.03';
my %registered_callbacks;

#-----------------------------------------------------------
# $class->get_callbacks( $namespace )
#-----------------------------------------------------------
sub get_callbacks {
    my ( $class, $namespace ) = @_;

    return if ( $registered_callbacks{ $namespace }++ );

    warn "Your app needs a 'namespace' method which doesn't return 'Gantry'"
            if ( $namespace eq 'Gantry' );

    return (
        { phase => 'init', callback => \&initialize },
        { phase => 'post_init', callback => \&uaf_authenticate }
    );

}

#-----------------------------------------------------------
# initialize
#-----------------------------------------------------------
sub initialize {
    my $gobj = shift;

    $gobj->uaf_init();

}

sub uaf_init {
    my $gobj = shift;

    my @parts;
    my $filename;
    my $uaf_authn = $gobj->fish_config('uaf_authn_module') || 'Gantry::Plugins::Uaf::Authenticate';
    my $uaf_authz = $gobj->fish_config('uaf_authz_module') || 'Gantry::Plugins::Uaf::Authorize';

    # load our authorization and authentication modules

    @parts = split('::', $uaf_authn);
    $filename = File::Spec->catfile(@parts) . ".pm";

    eval { 

        require $filename;
        $uaf_authn->import();
        $gobj->{_UAF_AUTHN_} = $uaf_authn->new($gobj);

    }; if ($@) { warn "authn died $@\n"; die "Unable to load $uaf_authn; $@"; }

    @parts = split('::', $uaf_authz);
    $filename = File::Spec->catfile(@parts) . ".pm";

    eval { 

        require $filename;
        $uaf_authz->import();
        $gobj->{_UAF_AUTHZ_} = $uaf_authz->new($gobj);

    }; if ($@) { warn "authz died $@\n"; die "Unable to load $uaf_authz; $@"; }

    $gobj->uaf_inited(1);

}

sub uaf_authenticate {
    my $gobj = shift;

    my $user;
    my $regex = $gobj->uaf_authn->filter;


    # authenticate the session, this happens with each access

    return if ($gobj->uri =~ /^$regex/);

	if ($gobj->uaf_authn->avoid()) {

		if ($gobj->session_lock()) {

            if (defined($user = $gobj->uaf_authn->is_valid())) {

                #
                # Uncomment this line of code and you will get an everchanging 
                # security token. Some internet pundits consider this a 
                # "good thing". But in an xhr async environment you will get 
                # a rather nasty race condition. i.e. The browsers don't 
                # consistently update the cookies from xhr requests. While a 
                # standard page loads work quite nicely.
                #
                # --> $gobj->uaf_authn->set_token($user);
                #
                $gobj->uaf_user($user);
                $gobj->session_unlock();

            } else { 

                $gobj->session_unlock();
                $gobj->uaf_authn->relocate($gobj->uaf_authn->login_rootp); 
            
            }
            
        }

    }

}

sub do_login {
    my ($gobj, $action) = @_;

    $gobj->uaf_authn->login($action);

}

sub do_logout {
    my $gobj = shift;

    $gobj->uaf_authn->logout();

}

# ---------------------------------------------------------------------
# Accessors
# ---------------------------------------------------------------------

sub uaf_authn {
    my $gobj = shift;

    return $gobj->{_UAF_AUTHN_};

}

sub uaf_authz {
    my $gobj = shift;

    return $gobj->{_UAF_AUTHZ_};

}

sub uaf_user {
    my ($gobj, $p) = @_;

    $gobj->{_UAF_USER_} = $p if (defined($p));
    return $gobj->{_UAF_USER_};

}

sub uaf_inited {
    my ($gobj, $p) = @_;

    $gobj->{_UAF_INITED_} = $p if (defined($p));
    return $gobj->{_UAF_INITED_};

}

1;

__END__

=head1 NAME

Gantry::Plugins::Uaf - A User Authentication and Authorization Framework

=head1 SYNOPSIS

In the Apache Perl startup or app.cgi or app.server:

    <Perl>
        # ...
        use MyApp qw{ -Engine=CGI -TemplateEngine=TT Cache Session Uaf};
    </Perl>
    
Inside MyApp.pm:

    use Gantry::Plugins::Uaf;

=head1 DESCRIPTION

This plugin mixes in a method that will provide session authentication and 
user authorization. Session authentication is based on a valid username and 
password. While user authorization is based on application defined rules 
which grant access to resources. The goal of this module is to be 
simple and flexiable.

To met this goal four objects are defined. They are Authenticate, 
Authorize, User and Rule. This package provides basic implementations of 
those objects. 

The Rule object either grants or denies access to a resource. The access is 
anything you want to use. A resource can be anything you define.

The User object consists of username and attributes. You can define as many 
and whatever attributes you want. The User object is not tied to any one 
datastore.

The base Authenticate object has two users hardcoded within. Those users are
"admin" and "demo", with corresponding passwords. This object handles the
authentication along with basic login and logout functionality.

The base Authorization object has only one rule defined: AllowAll.

Using the default, provided, Authentication and Authorization modules should
allow you get your application up and running in minimal time. Once that is
done, then you can define your User datastore, what your application rules 
are and then create your objects. Once you do that, then you can load
your own modules with the following config variables.

 uaf_authn_factory - The module name for your Authentication object
 uaf_authz_factory - The module name for your Authorization object

The defaults for those are:

 Gantry::Plugins::Uaf::Authorize
 Gantry::Plugins::Uaf::Authenticate

These modules must be on the Perl include path and are loaded during
Gantry's startup processing. This plugin also requires the Session plugin. 

=head1 METHODS

=over 4

=item uaf_authenticate

The method that is called for every url. It controls the authentication 
process, loads the User object and sets the scurity token.

=back

=head1 ACCESSORS

=over 4

=item uaf_authn

Returns the handle for the Authentication object.

=item uaf_authz

Returns the handle for the Authorization object.

Example:

=over 4

 $manager = $gobj->uaf_authz;
 if ($manager->can($user, "read", "data")) {

 }

=back

=item uaf_user

Set/Returns the handle for the User object.

Example:

=over 4

 $user = $gobj->uaf_user;
 $gobj->uaf_user($user);

=back

=back

=head1 PRIVATE METHODS

=over 4

=item get_callbacks

For use by Gantry. Registers the callbacks needed by Uaf
during the PerlHandler Apache phase or its moral equivalent.

=item initialize

This method is called by Gantry it will load and initialize your Authentication
and Authorization modules.

=item do_login

Exposes the url "/login", and calls the login() method of your Authenticaton 
module.

=item do_logout

Exposes the url "/logout", and calls the logout() method of your Authentication
module.

=back

=head1 SEE ALSO

 Gantry
 Gantry::Plugins::Session
 Gantry::Plugins::Uaf::Rule
 Gantry::Plugins::Uaf::User
 Gantry::Plugins::Uaf::Authorize
 Gantry::Plugins::Uaf::Authenticate
 Gantry::Plugins::Uaf::AuthorizeFactory

=head1 ACKNOWLEGEMENT

This module was heavily influenced by Apache2::SiteControl 
written by Tony Kay, E<lt>tkay@uoregon.eduE<gt>.

=head1 AUTHOR

Kevin L. Esteb <kesteb@wsipc.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
