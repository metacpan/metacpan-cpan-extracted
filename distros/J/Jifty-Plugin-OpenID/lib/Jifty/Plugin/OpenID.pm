use strict;
use warnings;

package Jifty::Plugin::OpenID;
use base qw/Jifty::Plugin/;

our $VERSION = '1.02';

=head1 NAME

Jifty::Plugin::OpenID - Provides OpenID authentication for your jifty app

=head1 DESCRIPTION

Provides OpenID authentication for your app

=head1 USAGE

=head2 Config

please provide C<OpenIDSecret> in your F<etc/config.yml> , the C<OpenIDUA> is
B<optional> , OpenID Plugin will use L<LWPx::ParanoidAgent> by default.

    --- 
    application:
        OpenIDSecret: 1234
        OpenIDUA: LWP::UserAgent

or you can set C<OpenIDUserAgent> environment var in command-line:

    OpenIDUserAgent=LWP::UserAgent bin/jifty server

if you are using L<LWPx::ParanoidAgent> as your openid agent. 
you will need to provide C<JIFTY_OPENID_WHITELIST_HOST> for your own OpenID server.

    export JIFTY_OPENID_WHITELIST_HOST=123.123.123.123

=head2 User Model

Create your user model , and let it uses
L<Jifty::Plugin::OpenID::Mixin::Model::User> to mixin "openid" column.
and a C<name> method.

    use TestApp::Record schema {

        column email =>
            type is 'varchar';

    };
    use Jifty::Plugin::OpenID::Mixin::Model::User;

    sub name {
        my $self = shift;
        return $self->email;
    }

Note: you might need to declare a C<name> method. because the OpenID
CreateOpenIDUser action and SkeletonApp needs current_user->username to show
welcome message and success message , which calls C<brief_description> method.
See L<Jifty::Record> for C<brief_description> method.

=head2 View

OpenID plugin provides AuthenticateOpenID Action. so that you can render an
AuthenticateOpenID in your template:

    form {
        my $openid = new_action( class   => 'AuthenticateOpenID',
                                moniker => 'authenticateopenid' );
        render_action( $openid );
    };

this action renders a form which provides openid url field.
and you will need to provide a submit button in your form.  

    form {
        my $openid = new_action( class   => 'AuthenticateOpenID',
                                moniker => 'authenticateopenid' );

        # ....

        render_action( $openid );
        outs_raw(
            Jifty->web->return(
                to     => '/openid_verify_done',
                label  => _("Login with OpenID"),
                submit => $openid
            ));
    };

the C<to> field is for verified user to redirect to.
so that you will need to implement a template called C</openid_verify_done>:

    template '/openid_verify_done' => page {
        h1 { "Done" };
    };

=head2 Attribute Exchange

You can retrieve information from remote profile on authentication server with
 OpenID Attribute Exchange service extension.

Set in your config.yml

    - OpenID:
       ax_param: openid.ns.ax=http://openid.net/srv/ax/1.0&openid.ax.mode=fetch_request&openid.ax.type.email=http://axschema.org/contact/email&openid.ax.type.firstname=http://axschema.org/namePerson/first&openid.ax.type.lastname=http://axschema.org/namePerson/last&openid.ax.required=firstname,lastname,email
       ax_values: value.email,value.firstname,value.lastname
       ax_mapping: "{ 'email': 'value.email', 'name': 'value.firstname value.lastname' }"

this parameters are usuable for all OpenID endpoints supporting Attribute
Exchange extension. They can be overriden in your application. Watch and/or
override C<openid/wayf> template from L<Jifty::Plugin::OpenID::View>.

Or you can use in your view C<show('openid/wayf','/url_return_to');>.


=head3 ax_param

is the url send to authentication server. It defines namespace, mode, attributes
types and requested attributes.

hints : MyOpenID use schema.openid.net schemas instead of axschema.org, Google
provides lastname and firstname, Yahoo only fullname

=head3 ax_values

keys of attributes values read from authentication server response.

=head3 ax_mapping

mapping of recieve values with your application fields in json format.

=cut

__PACKAGE__->mk_accessors(qw(ax_mapping ax_values ax_param));

sub init {
    my $self = shift;
    my %opt = @_;
    my $ua_class = $self->get_ua_class;
    eval "require $ua_class";
    $self->ax_param($opt{ax_param});
    $self->ax_mapping($opt{ax_mapping});
    $self->ax_values($opt{ax_values});

    Jifty->web->add_css('openidplugin.css');
}

sub get_ua_class {
    return Jifty->config->app('OpenIDUA') 
                || $ENV{OpenIDUserAgent} 
                || 'LWPx::ParanoidAgent' ;
}

sub new_ua {
    my $class = shift;
    my $ua;
    my $ua_class = $class->get_ua_class;

    Jifty->log->info( "OpenID Plugin is using $ua_class as UserAgent" );

    if( $ua_class eq 'LWPx::ParanoidAgent' ) {
         $ua = LWPx::ParanoidAgent->new(
                        whitelisted_hosts => [ $ENV{JIFTY_OPENID_WHITELIST_HOST} ]
                     );
    }
    else {
        $ua = $ua_class->new;
    }
    return $ua;
}


sub get_csr {
    my $class = shift;
    return Net::OpenID::Consumer->new(
        ua              => $class->new_ua ,
        cache           => Cache::FileCache->new,
        args            => scalar Jifty->handler->cgi->Vars,
        consumer_secret => Jifty->config->app('OpenIDSecret'),
        @_,
    );
}

=head1 AUTHORS

Alex Vandiver, Cornelius  <cornelius.howl {at} gmail.com >, Yves Agostini

=head1 LICENSE

Copyright 2005-2010 Best Practical Solutions, LLC.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
