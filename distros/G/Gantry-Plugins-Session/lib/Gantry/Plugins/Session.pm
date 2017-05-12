package Gantry::Plugins::Session;
use strict; use warnings;

use Gantry;
use Gantry::Utils::Crypt;
  
use base 'Exporter';
our @EXPORT = qw( 
    session_id
    session_init
    session_lock
    session_store
    session_remove
    session_inited
    session_update
    session_unlock
    session_retrieve
    do_cookiecheck
);

our $VERSION = '0.04';
my %registered_callbacks;
my $lock =  '_LOCK_';

#-----------------------------------------------------------
# $class->get_callbacks( $namespace )
#-----------------------------------------------------------
sub get_callbacks {
    my ( $class, $namespace ) = @_;

    return if ( $registered_callbacks{ $namespace }++ );

    warn "Your app needs a 'namespace' method which doesn't return 'Gantry'"
            if ( $namespace eq 'Gantry' );
    return (
        { phase => 'init', callback => \&initialize }
    );
}

#-----------------------------------------------------------
# initialize
#-----------------------------------------------------------
sub initialize {
    my ($gobj) = @_;

	$gobj->session_init();

}

sub session_init {
    my ($gobj) = @_;

    my $cache;
    my $cookie;
    my $session;
    my $app_rootp = $gobj->app_rootp || "";
    my $cookiecheck = $app_rootp . '/cookiecheck';
    my $regex = qr/^${app_rootp}\/(cookiecheck).*/;
    my $secret = $gobj->fish_config('session_secret') || 'w3s3cR7';
    my $crypt = Gantry::Utils::Crypt->new({'secret' => $secret});

    return if ($gobj->fish_uri =~ /^$regex/);

    # check to see if a previous session is active

    if ($session = $gobj->get_cookies('_session_id_')) {

        # OK, store the session id

        $gobj->session_id($session);

    } else {

        # set a cookie and see if it works

        $cookie = $crypt->encrypt(time, {}, rand(), $$);

        $gobj->set_cookie(
            {
                name => '_session_id_',
                value => $cookie,
                path => '/'
            }
        );

          $gobj->relocate($cookiecheck);

    }

}

sub do_cookiecheck {
    my $gobj = shift;

    my $session;
    my $app_rootp = $gobj->app_rootp || "/";

    # if cookies are enabled they should be returned on the redirect

    if ($session = $gobj->get_cookies('_session_id_')) {

        # Ok, redirect them back to the applicaion

        $gobj->session_inited(1);
        $gobj->session_id($session);
        $gobj->session_store($lock, '0');
        $gobj->relocate($app_rootp);

    } else {

        # Hmmm, OK, lets give them a nudge

        my $session_title = $gobj->fish_config('session_title') || 'Missing Cookies';
        my $session_wrapper = $gobj->fish_config('session_wrapper') || 'default.tt';
        my $session_template = $gobj->fish_config('session_template') || 'session.tt';

        $gobj->template_wrapper($session_wrapper);
        $gobj->stash->view->title($session_title);
        $gobj->stash->view->template($session_template);

    }

}

#-----------------------------------------------------------
# session_store
#-----------------------------------------------------------
sub session_store {
    my ($gobj, $key, $value) = (shift, shift, shift);

    my $session = $gobj->session_id();

    $gobj->cache_namespace($session);
    $gobj->cache_set($key, $value);

}

#-----------------------------------------------------------
# session_retrieve
#-----------------------------------------------------------
sub session_retrieve {
    my ($gobj, $key) = (shift, shift);

    my $data;
    my $session = $gobj->session_id();

    $gobj->cache_namespace($session);
    $data = $gobj->cache_get($key);

    return $data;

}

#-----------------------------------------------------------
# session_remove
#-----------------------------------------------------------
sub session_remove {
    my ($gobj, $key) = (shift, shift);

    my $session = $gobj->session_id();

    $gobj->cache_namespace($session);
    $gobj->cache_del($key);

}

#-----------------------------------------------------------
# session_update
#-----------------------------------------------------------
sub session_update {
    my ($gobj, $key, $value) = (shift, shift, shift);

    my $session = $gobj->session_id();

    $gobj->cache_namespace($session);
    $gobj->cache_del($key);
    $gobj->cache_set($key, $value);

}

#-----------------------------------------------------------
# session_id
#-----------------------------------------------------------
sub session_id {
    my ($gobj, $p) = (shift, shift);

    $$gobj{__SESSION_ID__} = $p if defined $p;
    return($$gobj{__SESSION_ID__});

}

#-----------------------------------------------------------
# session_inited
#-----------------------------------------------------------
sub session_inited {
    my ($gobj, $p) = @_;

    $$gobj{__SESSION_INITED__} = $p if defined $p;
    return($$gobj{__SESSION_INITED__});

}

#-----------------------------------------------------------
# session_lock
#-----------------------------------------------------------
sub session_lock {
    my ($gobj, $attempts) = (shift, shift);

    my $value;
    my $stat = 0;
    my $session = $gobj->session_id();


    $attempts = 30 if (!defined($attempts));
    $gobj->cache_namespace($session);

    for (my $x = 0; $x < $attempts; $x++) {

        $value = $gobj->cache_get($lock) || 0;
        if ($value eq '1') {

            sleep(1);

        } else {

            $gobj->cache_set($lock, '1');
            $stat = 1;
            last;

        }

    }

    return $stat;

}

#-----------------------------------------------------------
# session_unlock
#-----------------------------------------------------------
sub session_unlock {
    my ($gobj) = (shift);

    my $session = $gobj->session_id();

    $gobj->cache_namespace($session);
    $gobj->cache_set($lock, '0');

}

1;

__END__

=head1 NAME

Gantry::Plugins::Session - Plugin for cookie based session management

=head1 SYNOPSIS

In Apache Perl startup or app.cgi or app.server:

    <Perl>
        # ...
        use MyApp qw{ -Engine=CGI -TemplateEngine=TT Session };
    </Perl>
    
Inside MyApp.pm:

    use Gantry::Plugins::Session;

=head1 DESCRIPTION

This plugin mixes in a method that will provide simple session management. 
Session management is done by setting a cookie to a known value. The session
cookie will only last for the duration of the browser's usage. The session
cookie can be considered an ID and for all practical purposes is an 'idiot' 
number.

Session state can be associated with the session id. The state is stored
within the session cache. Once again this is short time storage. The cache is 
periodically purged of expired items. 

Note that you must include Session in the list of imported items when you use 
your base app module (the one whose location is app_rootp). Failure to do so 
will cause errors.

Session is dependent on Gantry::Plugins::Cache for handling the session cache.

=head1 CONFIGURATION

The following items can be set by configuration:

 session_secret           a plain text key used to encrypt the cookie
 session_title            a title for the session template
 session_wrapper          the wrapper for the session template
 session_template         the template for missing cookies notice

The following reasonable defaults are being used for those items:

 session_secret           same as used by Gantry::Plugins::AuthCookie.pm
 session_title            "Missing Cookies"
 session_wrapper          default.tt
 session_template         session.tt

=head1 METHODS

=over 4

=item session_id

This method returns the current session id.

 $session = $self->session_id();

=item session_store

This method will store a key/value pair within the session cache. Multiple
key/value pairs may be stored per session.

 $self->session_store('key', 'value');

=item session_retrieve

This method will retireve the stored value for a given key.

 $data = $self->session_retrieve('key');

=item session_remove

This method will remove the stored value for a given key.

 $self->session_remove('key');

=item session_update

This method will update the value for the given key.

 $self->session_update('key', 'value');

=item session_lock
 
This method along with session_unlock() provide a simple locking mechanism
to help serialize access to the session store. You may supply an otional 
parameter to control the number of attempts when aquiring the lock. The 
default is 30 attempts. It will return true if successfull.

 if ($self->session_lock()) {

    ...

    $self->session_unlock();

 }

=item session_unlock
 
This method will unlock the session store.
 
=back

=head1 PRIVATE METHODS

=over 4

=item get_callbacks

For use by Gantry.pm. Registers the callbacks needed for session management
during the PerlHandler Apache phase or its moral equivalent.

=item initialize

Callback to initialize plugin configuration.

=item do_cookiecheck

A URL to check to see if cookies are activated on the browser. If they
are not, then a page will be displayed prompting them to turn 'cookies' on.

=back

=head1 SEE ALSO

    Gantry
    Gantry::Plugins::Cache

=head1 AUTHOR

Kevin L. Esteb <kesteb@wsipc.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
