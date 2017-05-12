package Gantry::Plugins::AuthCookie;
use strict; use warnings;

use Gantry::Utils::HTML qw( :all );

use Crypt::CBC;
use MIME::Base64;
use Digest::MD5 qw( md5_hex );
use Authen::Htpasswd;
use Authen::Htpasswd::User;
use Sub::Install;

# lets export a do method and some conf accessors
use base 'Exporter';
our @EXPORT = qw( 
    do_login 
    auth_user_row 
    auth_user_groups 
    auth_require
    auth_groups
    auth_deny
    auth_optional
    auth_table
    auth_file
    auth_ldap
    auth_ldap_hostname
    auth_ldap_binddn
    auth_ldap_userdn
    auth_ldap_groupdn
    auth_ldap_filter
    auth_secret
    auth_user_field
    auth_password_field
    auth_group_table
    auth_group_join_table
    auth_logout_url
    auth_login_url
    auth_cookie_name
    auth_cookie_domain
    auth_execute_login
    auth_execute_logout
);

my %registered_callbacks;

#-----------------------------------------------------------
# $class->get_callbacks( $namespace )
#-----------------------------------------------------------
sub get_callbacks {
    my ( $class, $namespace ) = @_;

    return if ( $registered_callbacks{ $namespace }++ );

    return (
        { phase => 'init',      callback => \&initialize },
        { phase => 'post_init', callback => \&auth_check },
    );
}

#-----------------------------------------------------------
# initialize
#-----------------------------------------------------------
sub initialize {
    my( $gobj ) = @_;

    $gobj->auth_optional( $gobj->fish_config( 'auth_optional' ) || 'no' );
    $gobj->auth_deny( $gobj->fish_config( 'auth_deny' ) || 'no' );
    $gobj->auth_table( $gobj->fish_config( 'auth_table' ) || 'user' );
    $gobj->auth_file( $gobj->fish_config( 'auth_file' ) || '' );
    $gobj->auth_ldap( $gobj->fish_config( 'auth_ldap' ) || '' );
    $gobj->auth_ldap_hostname( 
        $gobj->fish_config( 'auth_ldap_hostname' ) || '' 
    );
    $gobj->auth_ldap_binddn( $gobj->fish_config( 'auth_ldap_binddn' ) || '' );
    $gobj->auth_ldap_userdn( $gobj->fish_config( 'auth_ldap_userdn' ) || '' );
    $gobj->auth_ldap_groupdn( $gobj->fish_config( 'auth_ldap_groupdn' ) || '' );
    $gobj->auth_ldap_filter( 
        $gobj->fish_config( 'auth_ldap_filter' ) || 'uid' 
    );

    $gobj->auth_group_table(
        $gobj->fish_config( 'auth_group_table' ) || 'user_group'
    );
    $gobj->auth_group_join_table(
        $gobj->fish_config( 'auth_group_join_table' ) || 'user_groups'
    );
    
    $gobj->auth_user_field( 
        $gobj->fish_config( 'auth_user_field' ) || 'ident'
    );
        
    $gobj->auth_password_field(
        $gobj->fish_config( 'auth_password_field' ) || 'password'
    );
    
    $gobj->auth_require( 
        $gobj->fish_config( 'auth_require' ) || 'valid-user'
    );
    
    $gobj->auth_groups( $gobj->fish_config( 'auth_groups' ) || '' );
    $gobj->auth_secret(
        $gobj->fish_config( 'auth_secret' ) || $gobj->gantry_secret()
    );

    if ( $gobj->fish_config( 'test_username' ) 
        || $gobj->fish_config( 'test_user_id' ) ) {
        
        $gobj->test( 1 );
    }
    
    eval {
        $gobj->auth_cookie_name(
            $gobj->fish_config( 'auth_cookie_name' ) || 'auth_cookie'
        );
    };

    eval {
        $gobj->auth_cookie_domain(
            $gobj->fish_config( 'auth_cookie_domain' )
        );
    };

    eval {
        $gobj->auth_logout_url(
            $gobj->fish_config( 'auth_logout_url' )
        );
    };

    eval {
        $gobj->auth_login_url(
            $gobj->fish_config( 'auth_login_url' )
        );
    };

    # initialize these in the Gantry object
    $gobj->auth_user_row( {} );
    $gobj->auth_user_groups( {} );
    
}

#-----------------------------------------------------------
# auth_check
#-----------------------------------------------------------
sub auth_check {
    my $gobj = shift;
    
    if ( $gobj->test() ) {
         my $obj  = Gantry::Plugins::AuthCookie::AuthUserObject->new( {
             id       => $gobj->fish_config( 'test_user_id' ),
             user_id  => $gobj->fish_config( 'test_user_id' ),
             $gobj->auth_user_field() => $gobj->fish_config( 'test_username' ),
         } );
                
        $gobj->auth_user_row( $obj );
        $gobj->user( $gobj->fish_config( 'test_username' ) );
        
        return;
    }
    
    # check for controller config, look for auth stuff and process
    if ( my $config_ref = $gobj->can( 'controller_config' ) ) {

        my $config = $config_ref->();

        foreach my $m ( @{ $config->{authed_methods} } ) {

            if ( $m->{action} eq $gobj->action() ) {
                
                $gobj->auth_deny( 'yes' ); 
                    
                # set group access
                if ( $m->{group} ) {
                    $gobj->auth_require( 'group' );
                    $gobj->auth_groups( $m->{group} );
                }
                # set valid-user access
                else {
                    $gobj->auth_require( 'valid-user' );
                }
            }            
        }
    }
    
    if ( $gobj->auth_optional() eq 'yes' && $gobj->auth_deny() ne 'yes' ) {
        validate_user( $gobj );
    }
    elsif ( $gobj->auth_deny() eq 'yes' ) {

        # check auth && redirect if not authed
        if ( ! validate_user( $gobj ) ) {
            my $goto;
            my $qstring = '';
            my $req     = $gobj->apache_request();
            my $loc     = $gobj->location;
            my $uri     = $gobj->uri;
            my $crypt   = Gantry::Utils::Crypt->new(
                { 'secret' => $gobj->auth_secret() }
            );
                        
            $uri =~ s/^$loc//;
            $goto = $uri || '/';
           
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

            $loc =~ s!^/$!!; # fix for root page login redirection

            $gobj->relocate( $loc . "/login?url=${goto}" );
        }

    }
}

#-----------------------------------------------------------
# validate_user
#-----------------------------------------------------------
sub validate_user {
    my $gobj = shift;

    # stash an empty object
    my $obj  = Gantry::Plugins::AuthCookie::AuthUserObject->new( {
        'id'                         => '',
        'user_id'                    => '',
        $gobj->auth_user_field()     => '',
        $gobj->auth_password_field() => '',
    } );
    
    $gobj->auth_user_row( $obj );
 
    # immediately return success for login and static
    my $app_rootp = $gobj->app_rootp() || '';
    my $regex     = qr/^${app_rootp}\/(login|static).*/;
    
    return 1 if $gobj->uri =~ /^$regex|login|cookiecheck$/;

    my $cookie_name = 'auth_cookie';
    eval { $cookie_name = $gobj->auth_cookie_name(); };

    my $cookie    = $gobj->get_cookies( $cookie_name );
    return 0 if ! $cookie;
        
    my( $username, $password ) = decrypt_cookie( $gobj, $cookie );
    
    return 0 if ( ! $username || ! $password );
    
    my $user_groups = {};

    if ( $gobj->auth_file() ) {
        my $pwfile = Authen::Htpasswd->new(
            $gobj->auth_file(), { encrypt_hash => 'md5' }
        );
        
        my $user = $pwfile->lookup_user( $username );
        return 0 if ! $user;
 
        if ( $user && $user->check_password( $password ) ) {
        
            my $obj  = Gantry::Plugins::AuthCookie::AuthUserObject->new( {
                id       => $username,
                user_id  => $username,
                $gobj->auth_user_field()     => $username,
            } );
                       
           $gobj->auth_user_row( $obj );
           $gobj->user( $username );
        }
        else {
            return 0;             
        }
    }
    # Look up via LDAP.
    elsif( $gobj->auth_ldap() 
        && $gobj->auth_ldap_hostname 
        && $gobj->auth_ldap_binddn 
        && $gobj->auth_ldap_filter ) {
            
        require Net::LDAP;
        require Net::LDAP::Util;
        Net::LDAP::Util->import( qw( ldap_error_desc ldap_error_text ) );

        my $ldap = Net::LDAP->new( $gobj->auth_ldap_hostname() ) or die "$@";

        # Attempt to bind to a directory with dn and password
        # We do this rather than directly comparing password hashes,
        # thus remaining compatible with more exotic ldap implementations.
        my $mesg = $ldap->bind( 
            ( $gobj->auth_ldap_filter() 
                . "=$username, " 
                . $gobj->auth_ldap_binddn()
            ),
            password => $password
        );

        unless( $mesg->code ) { 
            my $profile_mesg = $ldap->search( # perform a search
                base   => $gobj->auth_ldap_binddn(),
                filter => $gobj->auth_ldap_filter() . "=$username",
            );
                      
            my $uidNumber;

            unless( $profile_mesg->code ) {
                # With any luck there will always be only one match...it is 
                # poor LDAP implementation of your filter
                # if you get more than one for this.
                # if not, the last matching data will overwrite.  
                   while( my $entry = $profile_mesg->shift_entry ) {
                    $uidNumber = $entry->get_value( 'uidNumber' );                            
                }
            }

            # Create a valid AuthUserObject
            my $obj  = Gantry::Plugins::AuthCookie::AuthUserObject->new( {
                id       => $username,
                user_id  => $username,
                $gobj->auth_user_field() => $username,
            } );
                
            # Auth the object.                                
            $gobj->auth_user_row( $obj );
            
   			# Put the user information into the gantry object.
   			# Set __USER__ to uidNumber if at all possible.  This way we know 
            # for fact that we have a unique UID.  It would be poor form to 
            # have multiple identical usernames, but it is still possible.  
            # UID's simply cannot repeat.  This way we can
            # filter for uidNumber in outside routines to get full user 
            # information.  If it's not available (ie, perhaps it's an 
            # organizationalPerson?), just sub in the username as per usual.
            $gobj->user( $uidNumber || $username );
            
        }
            
        else{
            return 0;
        }
		if( $gobj->auth_ldap_groupdn ){
           	# Similarly to the DBIC function below, we'll attempt to look
            # up group information as well, based on what we are provided
            # in auth_ldap_groupdn.  Match all groups that our user exists
            # as a member of.
            my $group_mesg = $ldap->search( # perform a search
                base   => $gobj->auth_ldap_groupdn(),
                filter => "memberUid=$username",
            );

			my @groups;
        	unless( $group_mesg->code ){
				# Shift out each group entry, and enter it's cn
				# into the user_groups hash as a key with a value of 1.
           		while( my $entry = $group_mesg->shift_entry ){
					++$user_groups->{ $entry->get_value( 'cn' ) };           			
           		}
        	}
        }

    }
    # look up via DBIC
    else {
        my $sch =   $gobj->can( 'get_auth_schema' )
                    ? $gobj->get_auth_schema()
                    : $gobj->get_schema();
        my $user_row  = $sch->resultset( $gobj->auth_table() )->search( { 
            $gobj->auth_user_field()     => $username,
            $gobj->auth_password_field() => $password,
        } )->next;

        if ( $user_row ) {
            # put the user row into the gantry object
            $gobj->auth_user_row( $user_row );
            $gobj->user( $username );
        }
        else {
            return 0;            
        }

        eval {  # Try to pull groups, don't complain if it fails.
            my $dbh = $sch->storage->dbh;

            my $user_table      = $gobj->auth_table();
            my $grp_table       = $gobj->auth_group_table();
            my $grp_join_table  = $gobj->auth_group_join_table();
            
            my @sql;
            my $group_ident = '';
            
            push( @sql,
                "select g.ident from $user_table u, $grp_join_table m,",
                "$grp_table g",
                "where m.$user_table = u.id and m.$grp_table = g.id",
                'and u.id = ', $user_row->id
            );

            {
                # DBI, please keep quiet
                local $dbh->{ PrintWarn  };
                local $dbh->{ PrintError };
                $dbh->{ PrintWarn  } = 0;
                $dbh->{ PrintError } = 0;

                my $q = $dbh->prepare( join( ' ', @sql ) );
                $q->execute();
                $q->bind_columns( \$group_ident );

                foreach ( $q->fetchrow_arrayref ) {
                    ++$user_groups->{ $group_ident } if $group_ident;
                }
            }

        };
        # We don't care if the above does not work.  Groups are optional.
    }

    # put the user groups into the gantry object
    $gobj->auth_user_groups( $user_groups );    

    if ( $gobj->auth_require() eq 'group' ) {
        
        my @groups = split( /\s*,\s*/, $gobj->auth_groups() );

        # loop over groups and return 1 if user group exists
        foreach ( @groups ) {
            return 1 if defined $user_groups->{$_};
        }
        
        # otherwise return 0
        return 0;
    }
    
    # return success
    return 1;
    
} # end validate_user

#-----------------------------------------------------------
# auth_execute_login
#-----------------------------------------------------------
sub auth_execute_login {
    my ( $self, $opts ) = @_;

    if ( ! $opts->{user} || ! $opts->{password} ) {
        die "user/password required";
    }
    
    my $cookie_name = 'auth_cookie';
    my $domain;

    eval { $cookie_name = $self->auth_cookie_name();   };
    eval { $domain      = $self->auth_cookie_domain(); };
    
    my $encd = encrypt_cookie( 
        $self, 
        $opts->{user}, 
        $opts->{password} 
    );

    # set cookie, redirect to do_frontpage.
    $self->set_cookie( {  
        name     => $cookie_name,
        value    => $encd, 
        path     => '/',
        domain   => $domain,
    } ); 
    
}

#-----------------------------------------------------------
# auth_execute_logout
#-----------------------------------------------------------
sub auth_execute_logout {
    my ( $self ) = @_;

    my $cookie_name = 'auth_cookie';
    my $domain;

    eval { $cookie_name = $self->auth_cookie_name();   };
    eval { $domain      = $self->auth_cookie_domain(); };
    
    $self->set_cookie( {  
            name     => $cookie_name,
            value    => '', 
            expires  => 0, 
            path     => '/',
            domain   => $domain,
    } );  
    
}

#-----------------------------------------------------------
# do_login
#-----------------------------------------------------------
sub do_login {
     my ( $self, $page ) = @_;

    my %param = $self->get_param_hash();

    my $cookie_name = 'auth_cookie';
    my $domain;
    eval { $cookie_name = $self->auth_cookie_name();   };
    eval { $domain      = $self->auth_cookie_domain(); };

    if ( defined $param{logout} ) {

        $self->auth_execute_logout();

        my $relocation;

        eval {
            $relocation = $self->auth_logout_url;
        };
        if ( $@ ) {
            $relocation = auth_logout_url( $self );
        }

        $self->relocate( $relocation );        
        return();    
    }
    
    $page ||= $param{page};
    
    $self->stash->view->template( 'login.tt' );
    $self->stash->view->title( 'Login' );
    
    my @errors;
    if ( ! ( @errors = checkvals( $self )  ) ) {
        
        $self->auth_execute_login( {
            user     => $param{username},
            password => $param{password}
        } );

        # check for url param then redirect
        if ( $param{url} ) {
            my $crypt   = Gantry::Utils::Crypt->new(
                { 'secret' => $self->auth_secret() }
            );
                    
            $self->relocate( $self->location . $crypt->decrypt( $param{url} ) );        
        }

        # check for ":" separated paths then redirect
        elsif ( $page ) {
            $page =~ s/\:/\//g;
            $self->relocate( $page );
        }

        # else send them to the application root
        else {
            $self->relocate( $self->auth_login_url );
        }

        return();
    }

    my $retval = {};
    my $url    = $param{url} || '';

    $retval->{page}       = $page;
    $retval->{url}        = $url;
    $retval->{param}      = \%param;
    $retval->{login_form} = login_form( $self, $page, $url );
    $retval->{errors}     = ( $self->is_post() ) ? \@errors : 0;
    
    $self->status( $self->status_const( 'FORBIDDEN' ) );
    $self->stash->view->data( $retval );
   
}

#-------------------------------------------------
# login_form( $self )
#-------------------------------------------------
sub login_form {
    my ( $self, $page, $url ) = @_;
    
    my %in    = $self->get_param_hash();
    $in{page} = $page;
    $in{url}  = $url;
    
    my @form = ( ht_form( $self->uri ),
        q!<TABLE border=0>!,
            ht_input( 'page', 'hidden', \%in ),
            ht_input( 'url',  'hidden', \%in ),
        q!<TR><TD><B>Username</B><BR>!,
        ht_input( 'username', 'text', \%in, 'size=15 id="username"' ),
        qq!</TD></TR>!,

        q!<TR><TD><B>Password</B><BR>!,
        ht_input( 'password', 'password', \%in, 'size=15' ),
        q!</TD></TR>!,

        q!<TR><TD align=right>!,
        ht_submit( 'submit', 'Log In' ),
        q!</TD></TR>!,

        q!</TABLE>!,
        ht_uform() 
    );

    return( join( ' ', @form ) );
} # END login_form

#-------------------------------------------------
# decrypt_cookie
#-------------------------------------------------
sub decrypt_cookie {
    my ( $self, $encrypted ) = @_;

    $encrypted ||= '';
    
    local $^W = 0; # Crappy perl module dosen't run without warnings.
    
    my $c;
    eval {
        $c = new Crypt::CBC ( {    
            'key'         => $self->auth_secret(),
            'cipher'     => 'Blowfish',
            'padding'    => 'null',
        } );
    };
    if ( $@ ) {
        die "Error building CBC object are your Crypt::CBC and"
            .   " Crypt::Blowfish up to date?  Actual error: $@";
    }

    my $p_text = $c->decrypt( MIME::Base64::decode( $encrypted ) );
    
    $c->finish();

    my ( $user, $pass, $md5 ) = split( ':;:', $p_text );

    $user ||= '';
    $pass ||= '';
    $md5  ||= '';

    my $omd5 = md5_hex( $user . $pass ) || '';

    if ( $omd5 eq $md5 ) {
        return( $user, $pass );
    }
    else {
        return( $user, undef );
    }

} # END decrypt_cookie

#-------------------------------------------------
# encrypt_cookie
#-------------------------------------------------
sub encrypt_cookie {
    my ( $self, $username, $pass ) = @_;

    local $^W = 0;    

    $username     ||= '';
    $pass         ||= '';

    my $c;
    eval {
        $c = new Crypt::CBC( {    
            'key'         => $self->auth_secret(),
            'cipher'     => 'Blowfish',
            'padding'    => 'null',
        } );
    };
    if ( $@ ) {
        die "Error building CBC object are your Crypt::CBC and"
            .   " Crypt::Blowfish up to date?  Actual error: $@";
    }

    my $md5 = md5_hex( $username . $pass );
    
    my $encd     = $c->encrypt("$username:;:$pass:;:$md5");
    my $c_text   = MIME::Base64::encode( $encd, '');

    $c->finish();
 
    return( $c_text );
    
} # END encrypt_cookie

#-------------------------------------------------
# checkvals
#-------------------------------------------------
sub checkvals {
    my ( $self ) = @_;

    my %in = $self->get_param_hash();
    
    my @errors;

    if ( ! $in{username} ) {
        push( @errors, 'Enter your username' );
    }
    
    if ( ! $in{password} ) {
        push( @errors, 'Enter your password' );
    }

    if ( ! @errors ) {
        if ( $self->auth_file() ) {
             my $pwfile = Authen::Htpasswd->new(
                $self->auth_file(), { encrypt_hash => 'md5' }
            );

            my $user = $pwfile->lookup_user( $in{username} );

            if ( $user && $user->check_password( $in{password} ) ) {

                my $obj  = Gantry::Plugins::AuthCookie::AuthUserObject->new( {
                    id       => $in{username},
                    user_id  => $in{username},
                    $self->auth_user_field()     => $in{username},
                    $self->auth_password_field() => $in{password},
                } );
                                
                $self->auth_user_row( $obj );

            }
            else {
                push( @errors, 'Login Failure' );                
            }            
        }
        elsif( $self->auth_ldap() 
            && $self->auth_ldap_hostname 
            && $self->auth_ldap_binddn 
            && $self->auth_ldap_filter ) {
            
            require Net::LDAP;
            require Net::LDAP::Util;
            Net::LDAP::Util->import( qw( ldap_error_desc ldap_error_text ) );

            my $ldap = Net::LDAP->new( 
                $self->auth_ldap_hostname() 
            ) or die "$@";

            # Attempt to bind to a directory with dn and password
            # We do this rather than directly comparing password hashes,
            # thus remaining compatible with more exotic ldap implementations.
            my $mesg = $ldap->bind( 
                ( $self->auth_ldap_filter()
                    . "=$in{'username'}, "
                    . $self->auth_ldap_binddn()
                ),
                password => $in{'password'}
            );

            unless( $mesg->code ) { 
                my $profile_mesg = $ldap->search( # perform a search
                    base   => $self->auth_ldap_binddn(),
                    filter => $self->auth_ldap_filter() . "=$in{'username'}",
                );
                      
                my $uidNumber;

                unless( $profile_mesg->code ) {
                    # With any luck there will always be only one match...it 
                    # is poor LDAP
                    # bind_dn/filter if you get more than one for this.
                    # if not, the last matching data will overwrite.  
                    while( my $entry = $profile_mesg->shift_entry ) {
                        $uidNumber = $entry->get_value( 'uidNumber' );                            
                    }
                }

                # Create a valid AuthUserObject
                my $obj  = Gantry::Plugins::AuthCookie::AuthUserObject->new( {
                    id       => $in{username},
                    user_id  => $in{username},
                    $self->auth_user_field()     => $in{username},
                    $self->auth_password_field() => $in{password},
                } );
                
                # Auth the object.                                
                $self->auth_user_row( $obj );
                
            }
            
            # If the user is in debug mode, and auth fails, give them a verbose 
            # explanation of what went wrong.  In production, this would look 
            # very unprofessional. :\
            # If there is a known logging mechanism, this needs to log the 
            # failure, and what username was attempting it (and probably 
            # what IP address).
            else{
                if( $self->auth_ldap() eq 'debug' ){
                    push( @errors, 
                        "hostname: " . $self->auth_ldap_hostname() 
                    );

                    push( @errors, 
                        "bind dn: "
                        . $self->auth_ldap_filter()
                        . "=$in{'username'}, "
                        . $self->auth_ldap_binddn()
                    );
                    push( @errors, 
                        ldap_error_desc( $mesg->code ) 
                        . ": " 
                        . ldap_error_text( $mesg->code ) 
                    );
                }
                else{
                    push( @errors, 'Login Failure' );
                }
            }
        }
        else {
            eval {
                my $sch =   $self->can( 'get_auth_schema' )
                            ? $self->get_auth_schema()
                            : $self->get_schema();
                my $password_field = $self->auth_password_field();
                my $row = $sch->resultset( $self->auth_table() )->find( {
                    $self->auth_user_field()        => $in{username},
                    $self->auth_password_field()    => $in{password},
                } );

                if ( $row ) {
                    # Specified user/pass is correct so save the auth row.
                    $self->auth_user_row( $row );
                }
                else {
                    # We didn't get a row back so query again
                    # using only the user to determine if we have
                    # a bad user name or bad password. This extra
                    # step is necessary in the case where we are using
                    # encrypted passwords.
                    $row = $sch->resultset( $self->auth_table() )->find( {
                        $self->auth_user_field() => $in{username},
                    } );
                    
                    unless ( $row ) {
                        push( @errors, 'Invalid user' );
                    }
                    else {
                        push( @errors, "Invalid password" );
                    }
                }
            };
            if ( $@ ) {
                die 'Error: (perhaps you didn\'t include AuthCookie in '
                    . "the same list as -Engine?).  Full error: $@";
            }
        }
    }
    
    return( @errors );
} # END checkvals

#-------------------------------------------------
# $self->auth_optional
#-------------------------------------------------
sub auth_optional {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_OPTIONAL__} = $p if defined $p;
    return( $$self{__AUTH_OPTIONAL__} ); 
    
} # end auth_optional

#-------------------------------------------------
# $self->auth_deny
#-------------------------------------------------
sub auth_deny {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_DENY__} = $p if defined $p;
    return( $$self{__AUTH_DENY__} ); 
    
} # end auth_deny

#-------------------------------------------------
# $self->auth_table
#-------------------------------------------------
sub auth_table {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_TABLE__} = $p if defined $p;
    return( $$self{__AUTH_TABLE__} ); 
    
} # end auth_table

#-------------------------------------------------
# $self->auth_user_field
#-------------------------------------------------
sub auth_user_field {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_USER_FIELD__} = $p if defined $p;
    return( $$self{__AUTH_USER_FIELD__} ); 
    
} # end auth_user_field

#-------------------------------------------------
# $self->auth_password_field
#-------------------------------------------------
sub auth_password_field {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_PASSWORD_FIELD__} = $p if defined $p;
    return( $$self{__AUTH_PASSWORD_FIELD__} ); 
    
} # end auth_password_field

#-------------------------------------------------
# $self->auth_secret
#-------------------------------------------------
sub auth_secret {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_SECRET__} = $p if defined $p;
    return( $$self{__AUTH_SECRET__} ); 
    
} # end auth_secret

#-------------------------------------------------
# $self->auth_require
#-------------------------------------------------
sub auth_require {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_REQUIRE__} = $p if defined $p;
    return( $$self{__AUTH_REQUIRE__} ); 
    
} # end auth_require

#-------------------------------------------------
# $self->auth_file
#-------------------------------------------------
sub auth_file {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_FILE__} = $p if defined $p;
    return( $$self{__AUTH_FILE__} ); 
    
} # end auth_file


#-------------------------------------------------
# $self->auth_ldap
#-------------------------------------------------
sub auth_ldap {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_LDAP__} = $p if defined $p;
    return( $$self{__AUTH_LDAP__} ); 
} # end auth_ldap

#-------------------------------------------------
# $self->auth_ldap_hostname
#-------------------------------------------------
sub auth_ldap_hostname {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_LDAP_HOSTNAME__} = $p if defined $p;
    return( $$self{__AUTH_LDAP_HOSTNAME__} ); 
} # end auth_ldap_hostname

#-------------------------------------------------
# $self->auth_ldap_binddn
#-------------------------------------------------
sub auth_ldap_binddn {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_LDAP_BINDDN__} = $p if defined $p;
    return( $$self{__AUTH_LDAP_BINDDN__} ); 
} # end auth_ldap_binddn

#-------------------------------------------------
# $self->auth_ldap_userdn
#-------------------------------------------------
sub auth_ldap_userdn {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_LDAP_USERDN__} = $p if defined $p;
    return( $$self{__AUTH_LDAP_USERDN__} ); 
} # end auth_ldap_userdn

#-------------------------------------------------
# $self->auth_ldap_groupdn
#-------------------------------------------------
sub auth_ldap_groupdn {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_LDAP_GROUPDN__} = $p if defined $p;
    return( $$self{__AUTH_LDAP_GROUPDN__} ); 
} # end auth_ldap_groupdn

#-------------------------------------------------
# $self->auth_ldap_filter
#-------------------------------------------------
sub auth_ldap_filter {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_LDAP_FILTER__} = $p if defined $p;
    return( $$self{__AUTH_LDAP_FILTER__} ); 
} # end auth_ldap_filter

#-------------------------------------------------
# $self->auth_group_table
#-------------------------------------------------
sub auth_group_table {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_GROUP_TABLE__} = $p if defined $p;
    return( $$self{__AUTH_GROUP_TABLE__} ); 
    
} # end auth_group_table

#-------------------------------------------------
# $self->auth_group_join_table
#-------------------------------------------------
sub auth_group_join_table {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_GROUP_JOIN_TABLE__} = $p if defined $p;
    return( $$self{__AUTH_GROUP_JOIN_TABLE__} ); 
    
} # end auth_group_join_table

#-------------------------------------------------
# $self->auth_groups
#-------------------------------------------------
sub auth_groups {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_GROUPS__} = $p if defined $p;
    return( $$self{__AUTH_GROUPS__} ); 
    
} # end auth_groups

#-------------------------------------------------
# $self->auth_user_row
#-------------------------------------------------
sub auth_user_row {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_USER_ROW__} = $p if defined $p;
    return( $$self{__AUTH_USER_ROW__} ); 
    
} # end auth_user_row

#-------------------------------------------------
# $self->auth_user_groups
#-------------------------------------------------
sub auth_user_groups {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_USER_GROUPS__} = $p if defined $p;
    return( $$self{__AUTH_USER_GROUPS__} ); 
    
} # end auth_user_groups

#-------------------------------------------------
# $self->auth_login_url
#-------------------------------------------------
sub auth_login_url {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_LOGIN_URL__} = $p if defined $p;
    return( $$self{__AUTH_LOGIN_URL__} || $self->location ); 
    
} # end auth_login_url

#-------------------------------------------------
# $self->auth_logout_url
#-------------------------------------------------
sub auth_logout_url {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_LOGOUT_URL__} = $p if defined $p;
    return( $$self{__AUTH_LOGOUT_URL__} || $self->app_rootp . '/login' ); 
    
} # end auth_logout_url

#-------------------------------------------------
# $self->auth_cookie_name
#-------------------------------------------------
sub auth_cookie_name {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_COOKIE_NAME__} = $p if defined $p;
    return( $$self{__AUTH_COOKIE_NAME__} || 'auth_cookie' );
    
} # end auth_cookie_name

#-------------------------------------------------
# $self->auth_cookie_domain
#-------------------------------------------------
sub auth_cookie_domain {
    my ( $self, $p ) = ( shift, shift );

    $$self{__AUTH_COOKIE_DOMAIN__} = $p if defined $p;
    return( $$self{__AUTH_COOKIE_DOMAIN__} );
    
} # end auth_cookie_name

package Gantry::Plugins::AuthCookie::AuthUserObject;

sub new {
    my( $class, $methods ) = @_;

    my $self = {};
    foreach my $method ( keys %$methods ) {
        
        Sub::Install::reinstall_sub({
            code => sub { return $methods->{$method} },
            into => __PACKAGE__,
            as   => $method
        }); 
    }

    bless( $self, $class );        
    return $self;    
}

1;

__END__

=head1 NAME

Gantry::Plugins::AuthCookie - Plugin for cookie based authentication

=head1 SYNOPSIS

Plugin must be included in the Applications use statment.

    <Perl>
        use MyApp qw{
                -Engine=CGI
                -TemplateEngine=TT
                -PluginNamespace=your_module_name
                AuthCookie
        };
    </Perl>

Bigtop:

    config {
        engine MP20;
        template_engine TT;
        plugins AuthCookie;
        ...


There are various config options.

Apache Conf:

    <Location /controller>
        PerlSetVar auth_deny yes
        PerlSetVar auth_require valid-user
    </Location>

Gantry Conf:

    <GantryLocation /authcookie/sqlite/closed>
        auth_deny yes
        auth_require valid-user
    </GantryLocation>

Controller Config: (putting auth restictions on the method/action)

    sub controller_config {
        my ( $self ) = @_;
        {
            authed_methods => [
                { action => 'do_delete',  group => '' },
                { action => 'do_add',     group => '' },
                { action => 'do_edit',    group => '' },
            ],
        }
    } # END controller_config

Controller Config via Bigtop:

    method controller_config is hashref {
        authed_methods 
            do_delete   => ``,
            do_edit     => ``,
            do_add      => ``;
    }

=head1 DESCRIPTION

This plugin mixes in a method that will supply the login routines and 
accessors that will store the authed user row and user groups.

Note that you must include AuthCookie in the list of imported items
when you use your base app module (the one whose location is app_rootp).
Failure to do so will cause errors.

=head1 CONFIGURATION

Authentication can be turned on and off by setting 'auth_deny' 
or L<auth_optional>. 

    $self->auth_deny( 'yes' );

If 'yes', then validation is turned on and the particular location will 
require that the user is authed. 

Just like Apache, you must define the type of auth, valid-user or group.

    $self->auth_require( 'valid-user' ); # default

    or

    $self->auth_require( 'group' );

After successful login the user row, groups (if any) will be set into the 
Gantry self object and can be retrieved using:

    $self->auth_user_row
    $self->auth_user_groups

For example, to access the username

$self->auth_user_row->username or whatever you have set for your 
auth_user_field see L<Gantry::Plugins::AuthCookie#CONFIG OPTIONS>

And to access the groups

    my $groups = $self->auth_user_groups();
    
    foreach my $group ( keys %{ $groups } ) {
        print $group;
    } 


AuthCookie assumes that you have the following tables:

    table user (
        id          int,
        username    varchar,
        password    varchar,
    )
    
    table user_group (
        id      int,
        ident   int,    
    )
    
    # join table
    table user_groups (
        user
        user_group
    )

Optionally you can modify some the table expections like so:

    $self->auth_table( 'my_usertable' );
    $self->auth_user_field( 'myusername' );
    $self->auth_password_field( 'mypassword' );
    
    $self->auth_group_table( 'user_group' );
    $self->auth_group_join_table( 'user_user_group' );

=head1 CONFIG OPTIONS

    auth_deny           'no' / 'yes'              # default 'off'
    auth_table          'user_table'              # default 'user'
    auth_file           '/path/to/htpasswd_file'  # Apache htpasswd file
    auth_user_field     'ident'                   # default 'ident'
    auth_password_field 'password'                # default 'password'
    auth_require        'valid-user' or 'group'   # default 'valid-user'
    auth_groups         'group1,group2'     # allow these groups
    auth_secret         'encryption_key'    # default 'w3s3cR7'
    auth_cookie_name    'my_auth_cookie'    # default 'auth_cookie'
    auth_cookie_domain  'www.example.com'   # default URL full domain
    auth_group_table    'user_group'
    auth_group_join_table 'user_groups'

=head1 METHODS

=over 4

=item do_login

this method provides the login form and login routines.

=item auth_user_row

This is mixed into the gantry object and can be called retrieve the DBIC user
row.

=item auth_user_groups

This is mixed into the gantry object and can be called to retrieve the
defined groups for the authed user.

=item auth_execute_login

    $self->auth_execute_login( { user => 'joe', password => 'mypass' } );

This method can be called at anytime to log a user in.

=item auth_execute_logout

    $self->auth_execute_logout();

This method can be called at anytime to log a user out.

=item get_callbacks

For use by Gantry.pm.  Registers the callbacks needed to auth pages
during PerlHandler Apache phase or its moral equivalent.

=back

=head1 CONFIGURATION ACCESSORS

=over 4

=item auth_deny

accessor for auth_deny. Turns authentication on when set to 'yes'.

=item auth_optional

accessor for auth_optional. User validation is active when set to 'yes'.

=item auth_table

accessor for auth_table. Tells AuthCookie the name of the user table. 
default is 'user'. 

=item auth_group_join_table

accessor for the name of the auth group to members joining table. Defaults
to 'user_groups'.

=item auth_group_table

accessor for the name of the auth group table.  Defaults to 'user_group'.

=item auth_file

accessor for auth_file. Tells AuthCookie to use the Apache style htpasswd file
and where the file is located.

=item auth_user_field

accessor for auth_user_field. Tells AuthCookie the name of the username field
in the user database table.  Defaults to 'ident'.

=item auth_password_field

accessor for auth_password_field. Tells AuthCookie the name of the password
field in the user database table.

=item auth_require

accessor for auth_require. Tells AuthCookie the type of requirement for the
set authentication. It's either 'valid-user' (default) or 'group'

=item auth_groups

accessor for auth_groups. This tells AuthCookie which groups are allowed 
which is enforced only when auth_require is set to 'group'. You can supply
multiple groups by separating them with commas.

=item auth_secret

accessor for auth_secret. auth_secret is the encryption string used to 
encrypt the cookie. You can supply your own encryption string or just use the
default the default value.

=item auth_logout_url

accessor for auth_logout_url.  auth_logout_url is a full URL where the
user will go when they log out.  Logging out happens when the do_login
method is called with a query_string parameter logout=1.

=item auth_login_url

accessor for auth_login_url.  auth_login_url is a full/relative URL where the
user will go after they login.  

=item auth_cookie_name

accessor for name of auth cookie.  By default the cookie is called
'auth_cookie'.  Import this and define a conf variable of the same name
to change the cookie's name.

=item auth_cookie_domain

accessor for the auth cookie's domain.  By default undef is used, so the
cookie will be set on the fully qualified domain of the login page.  Import
this method and define a conf variable of the same name to change the
domain.

=item auth_ldap

Accessor method for auth_ldap. Tells AuthCookie to use ldap for auth.

=item auth_ldap_binddn

Accessor method for auth_ldap_binddn. The bind dn is the user that is allowed
to search the directory.

=item auth_ldap_filter

Accessor method for auth_ldap_filter. The ldap search filter is used to map the
username to the ldap directory attribute used to select the desired entry.

=item auth_ldap_groupdn

Accessor method for auth_ldap_groupdn. Used to set the base for searching for
user groups in the directory.

=item auth_ldap_hostname

Accessor method for auth_ldap_hostname. This is the hostname of the ldap server.

=item auth_ldap_userdn

Accessor method for auth_ldap_userdn. Not currently used.

=back

=head1 PRIVATE SUBROUTINES

=over 4

=item auth_check

callback for auth check.

=item checkvals

check for login form.

=item decrypt_cookie

decryption routine for cookie.

=item encrypt_cookie

encryption routine for cookie.

=item initialize

callback to initialize plugin configuration.

=item login_form

html login form.

=item validate_user

validation routines.

=back

=head1 SEE ALSO

    Gantry

=head1 AUTHOR

Timotheus Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Timotheus Keefer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
