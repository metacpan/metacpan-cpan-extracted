package Gantry::Plugins::CookieCheck;
use strict;
use warnings;

use Gantry::Utils::Crypt ();

use base 'Exporter';
our @EXPORT = qw(
    do_cookiecheck
);

our $VERSION = '0.02';

my %registered_callbacks;

#-----------------------------------------------------------
# $class->get_callbacks( $namespace )
#-----------------------------------------------------------
sub get_callbacks {
    my ( $class, $namespace ) = @_;

    return if ( $registered_callbacks{ $namespace }++ );

    return (
        { phase => 'pre_init', callback => \&set_test_cookie },
    );
}

#-----------------------------------------------------------
# set_test_cookie
#-----------------------------------------------------------
sub set_test_cookie {
    my ( $gobj ) = @_;
    my $uri = $gobj->fish_uri();
    my $loc = $gobj->fish_location();
    my $cc_exclude = $gobj->fish_config('cc_exclude');

    # Set a test cookie under the following circumstances.
    # The test cookie (acceptcookies) is not already set.
    # The current uri does not match cookiecheck.
    # There is no cookie check exclude path provided or
    # there is an exclusion and it doesn't match the current location.
    if (
        ( ! $gobj->get_cookies( 'acceptcookies' ) ) and
        ( $uri !~ /cookiecheck\/?$/o ) and
        (
            ( ! $cc_exclude ) or ( $cc_exclude and ( $uri !~ /$cc_exclude/ ) )
        )
    ) {
        my $req     =   $gobj->apache_request();
        my $secret  =   $gobj->fish_config( 'cc_secret' )
                        || $gobj->gantry_secret();
        my $crypt   =   Gantry::Utils::Crypt->new( { 'secret' => $secret } );
        my $qstring =   '';
        my $goto;
        my $cookie;
        
        $cookie = {
            name     => 'acceptcookies',
            value    => '1',
            path     => '/',
        };
        $cookie->{domain} = $gobj->fish_config('cc_domain')
            if $gobj->fish_config('cc_domain');

        # Set a test cookie and then redirect.
        $gobj->set_cookie($cookie);

        # Determine where to redirect the user for the cookie check.
        $uri    =~ s/^$loc//;
        $goto   = $uri || '/' ;

        # Add parameters.
        foreach my $param ( $req->param() ) {
            $qstring .= sprintf( '&%s=%s', $param, $req->param( $param ) );
        }

        if ( $qstring ) {
            # Change the first & to a ? and add query string to goto.
            $qstring =~ s/^&/?/o;
            $goto .= $qstring;
        }

        # Encrypt goto
        $goto = $gobj->url_encode( $crypt->encrypt( $goto ) );

        # Redirect the user.
        $gobj->relocate( $loc . "/cookiecheck?url=${goto}" );
    }
}

#-----------------------------------------------------------
# do_cookiecheck()
#-----------------------------------------------------------
sub do_cookiecheck {
    my $gobj    =   shift;
    my $params  =   $gobj->params();
    my $secret  =   $gobj->fish_config( 'cc_secret' )
                    || $gobj->gantry_secret();
    my $crypt   =   Gantry::Utils::Crypt->new( { 'secret' => $secret } );

    # Decrypt url parameter.
    $params->{url} = $crypt->decrypt( $params->{url} );

    # If acceptcookies is set then send the user to the original
    # url they requested.
    if( $gobj->get_cookies( 'acceptcookies' ) ) {
        $gobj->relocate( $gobj->location() . $params->{url} );
    }
    else {
        # Cookies aren't enabled. Display an error page.
        my $cc_title        =   $gobj->fish_config( 'cc_title' ) || 'Missing Cookies';
        my $cc_wrapper      =   $gobj->fish_config( 'cc_wrapper' ) ||
                                $gobj->fish_config( 'template_wrapper' ) || 'default.tt';
        my $cc_template     =   $gobj->fish_config( 'cc_template' ) || 'cc.tt';

        $gobj->template_wrapper( $cc_wrapper );
        $gobj->stash->view->title( $cc_title );
        $gobj->stash->view->template( $cc_template );
    }
}

1;

__END__


=head1 NAME

Gantry::Plugins::CookieCheck - Plugin to test that cookies are enabled.

=head1 SYNOPSIS

Plugin must be included in the Applications use statment.

    <Perl>
        use MyApp qw{
                -Engine=CGI
                -TemplateEngine=TT
                -PluginNamespace=your_module_name
                CookieCheck
        };
    </Perl>

Bigtop:

    config {
        engine MP20;
        template_engine TT;
        plugins CookieCheck;
        ...


There are various config options.

Apache Conf:

    <Location /controller>
        PerlSetVar cc_title Title
        PerlSetVar cc_wrapper default.tt
        PerlSetVar cc_template cc_template.tt
        PerlSetVar cc_secret zak7mubuS9SpUraTHucUXePhAdR4meFUhAmAChEjAPuGUBrakeVenuvu
    </Location>

Gantry Conf:

    cc_title Title
    cc_wrapper default.tt
    cc_template cc_template.tt
    cc_secret zak7mubuS9SpUraTHucUXePhAdR4meFUhAmAChEjAPuGUBrakeVenuvu
    cc_domain my.domain.com
    cc_exclude /regex/path/to/exclude

=head1 DESCRIPTION

This module is based on the cookie check code that was originally
part of the Gantry::Plugins::Session module. It will check if
cookies are enabled by setting a test cookie called acceptcookies
and then redirect the user to a method called do_cookiecheck that
will verify the cookie exists. This module works best when
-StateMachine=Exceptions is used since that will allow the redirect
to take place right away instead of waiting till the entire request
has been processed.

=head1 CONFIGURATION

The following items can be set by configuration:

 cc_title       a title for the session template
 cc_wrapper     the wrapper for the session template
 cc_template    the template for missing cookies notice
 cc_secret      key used to encrypt url string during redirection
 cc_domain      domain used for test cookie
 cc_exclude     regular expression of locations to exclude from the
                cookie check.

The following reasonable defaults are being used for those items:

 cc_title       "Missing Cookies"
 cc_wrapper     template_wrapper from configuration or default.tt
 cc_template    cc.tt
 cc_secret      the value specified for gantry_secret
 cc_domain      empty.
 cc_exclude     all locations are checked

=head1 METHODS

=over 4

=item get_callbacks

  get_callbacks($namespace)

Register the set_test_cookie callback for the init phase.

=item do_cookiecheck

  do_cookiecheck()

This method verifies the acceptcookies cookie was set and redirects the
user back to the originally requested url. If the acceptcookies cookie
is missing the user is given an error page telling them they need
to enable cookies in their web browser.

=item set_test_cookie

  set_test_cookie()

This method checks for the existence of the acceptcookies cookie. If it
is not found then it sets the cookie and redirects the user to the
do_cookiecheck method.

=back

=head1 SEE ALSO

    Gantry
    Gantry::Utils::Crypt

=head1 AUTHOR

John Weigel <jweigel@sunflowerbroadband.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 The World Company

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
