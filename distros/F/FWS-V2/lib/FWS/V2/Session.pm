package FWS::V2::Session;

use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';

=head1 NAME

FWS::V2::Session - Framework Sites version 2 session related methods

=head1 VERSION

Version 1.13091122

=cut

our $VERSION = '1.13091122';


=head1 SYNOPSIS

    use FWS::V2;
    
    my $fws = FWS::V2->new();

    $fws->saveFormValue( 'thisThing' );


=head1 DESCRIPTION

FWS version 2 session methods are used to manipulate how a session is maintained, authenticated, and initiated.

=head1 METHODS


=head2 formArray

Return a list of all the available form values passed.

    #
    # get the array
    #
    my @formArray = $fws->formArray();

=cut

sub formArray {
    my ( $self ) =  @_;
    my @returnArray;
    for my $key ( keys %{$self->{form}} ) { push ( @returnArray, $key ) }
    return @returnArray;
}


=head2 formValue

Get or set a form value.  If the value was not set, it will always return an empty string, never undefined.

    #
    # set the form value
    #
    $fws->formValue( 'myVar', 'This is what its set to' );

    #
    # get the form value and pass it to the html rendering
    #
    $valueHash{html} .= $fws->formValue( 'myVar' );

=cut

sub formValue {
    my ( $self, $field, $fieldVal ) =  @_;
    if ( defined $fieldVal ) { $self->{form}{$field} = $fieldVal }
    if ( !defined $self->{form}{$field}) { $self->{form}{$field} = '' }
    return $self->{form}{$field};
}


=head2 fwsGUID

Retrieve the GUID for the fws site. If it does not yet exist, make a new one.

    print $fws->fwsGUID();

=cut

sub fwsGUID {
    my ( $self ) = @_;

    #
    # if is not set, set it and create the site id
    #
    if ( !$self->siteValue( 'fwsGUID' ) ) {

        #
        # get the sid for the fws site
        #
        my ( $fwsGUID ) = $self->getSiteGUID( 'fws' );

        #
        # if its blank make a new one
        #
        if ( !$fwsGUID ) {
            $fwsGUID = $self->createGUID( 'f' );
            my ( $adminGUID ) = $self->getSiteGUID( 'admin' );
            $self->runSQL( SQL => "insert into site set sid='fws', guid='" . $fwsGUID . "', site_guid='" . $self->safeSQL( $adminGUID ) . "'" );
        }

        #
        # add it as a siteValue and return the result
        #
        $self->siteValue( 'fwsGUID', $fwsGUID ) ;
        return $fwsGUID;
    }

    #
    # I already know it, just return the result
    #
    return $self->siteValue( 'fwsGUID' );
}


=head2 setFormValues

Gather the passed form values, and from it set the language formValue and the session formValue.

    #
    # get the array
    #
    $fws->setFormValues();

=cut

sub setFormValues {
    my ( $self ) =  @_;
    use CGI qw(:cgi);
    my $cgi = CGI->new();
    $CGI::POST_MAX=-1;
    foreach my $paramIn ( $cgi->param ) { $self->{form}{$paramIn} = $cgi->param( $paramIn ) }

    #
    # grab the one from the cookie if we have it
    #
    my $cookieSession = $cgi->cookie( $self->{sessionCookieName} );
    if ( $cookieSession  && !$self->{form}{session} ) { $self->{form}{session} = $cookieSession }

    #
    # if fws_lang is not set, lets set it
    #
    if ( $self->{form}{fws_lang} ) {
        $self->language( uc( $self->{form}{fws_lang} ) )
    }

    return;
}


=head2 setSession

Set the session for a FWS web based page rendering.

    #
    # Set the session
    #
    $fws->setSession();

=cut

sub setSession {
    my ( $self ) = @_;

    #
    # kill session was set,  lets make sure the session wasn't passed
    #
    if ( $self->formValue( 'killSession' ) ) {
        #
        # run the SQL to delete the session and then ditch the session id
        #
        $self->runSQL( SQL => "delete from fws_sessions where id='" . $self->safeSQL( $self->formValue( 'session' ) ) . "'" );
        $self->formValue( 'session', '' )
    }

    #
    # pull the current session
    #
    my ( $id, $fws_lang, $s_e, $s_a, $a_exp, $s_s, $s_b, $s_bs, $s_ip, $extra ) = @{$self->runSQL( SQL => "select id,fws_lang,e,a,a_exp,s,b,bs,ip,extra_value from fws_sessions where id='" . $self->safeSQL( $self->formValue( 'session' ) ) . "'" )};

    #
    # set the FWS_SESSION so we can see if it changed
    #
    $self->formValue( "FWS_SESSION", $s_b . "|" . $fws_lang . "|" . $s_bs . "|" . $s_ip . "|" . $s_e . "|" . $s_a . "|" . $a_exp . "|" . $s_s . "|" . $extra) ;

    #
    # if the session isn't in there, or the session is blank
    #
    if ( !$id || $ENV{REMOTE_ADDR} ne $s_ip || length( $self->formValue( 'session' ) ) != 33 ) {
        $s_b = $s_bs = $s_ip  = $s_e = $s_a = $s_s = $extra = '';
        $a_exp = '0';
        $self->adminLogOut();
        $self->userLogOut();
        $self->formValue( 'session', $self->createGUID( 'u' ) );
        $self->runSQL( SQL => "insert into fws_sessions ( id ) values ('" . $self->safeSQL( $self->formValue( 'session' ) ) . "')" );
    }

    #
    # read the extra and save it
    #
    my @extraSplit          = split( /\|/, $extra );
    my %saveWithSession     = $self->_saveWithSessionHash();
    while (@extraSplit) {
        my $fieldName   = shift( @extraSplit ); 
        my $fieldValue  = shift( @extraSplit );
        #
        # for security reasons lets make sure we aren't touching the major ones
        #
        if ( $fieldName !~ /^(p|b|s|bs|e|l|a|a2|fws_lang|id)$/ ) {
            #
            # only grab the one from the session, if we have not passed it to the script to change it
            #
            if ( $self->formValue( $fieldName ) eq '' ) { $self->formValue( $fieldName, $self->urlDecode( $fieldValue ) ) }
            $saveWithSession{$fieldName} = 1;
        }
    }

    $self->_saveWithSessionHash( %saveWithSession );

    #
    # set the goodies
    #
    if ( $self->formValue( 'b' ) eq '' )        { $self->{userLoginId} = $s_b; $self->formValue( 'b', $s_b ) }
    if ( $self->formValue( 'fws_lang' ) eq '' ) { $self->language( $fws_lang ) }
    if ( $self->formValue( 'editMode' ) eq '' ) { $self->formValue( 'editMode', $s_e ) }
    if ( $self->formValue( 'bs' ) eq '' )       { $self->{adminLoginId} = $s_bs;  $self->formValue( 'bs', $s_bs ) }
    if ( $self->formValue( 'a' ) eq '' )        { $self->formValue( 'a', $s_a ) }

    #
    # variablize time for consistancy
    #
    my $theTime = time();

    #
    # if we have an A value lets do some stuff with the aff exp
    #
    if ( $self->formValue( 'a' ) ne '' ) {

        #
        # this is a new affiliate or it has been switched lets reset tht time
        #
        if ( $self->formValue( 'a' ) ne $s_a ) { $a_exp = $theTime + $self->{affiliateExpMax} }

        #
        # if for whatever reason it has never been set, lets set it now before we do any calcs
        #
        if ( $a_exp < 1 ) { $a_exp = $theTime + $self->{affiliateExpMax} }

        #
        # check to see if what ever it is, is expired, if so, lets blank out the affiliateId
        #
        if ( $a_exp < $theTime ) {
            $self->formValue( 'a', '' );
            $a_exp = '0';
        }
    }

    #
    # if the affilaite has not been set, then make sure the a_exp is so no time gets slapped on to a new one
    #
    else { $a_exp = '0' }

    #
    # Set Affiliate ID: if it was set or derived and the exp date;
    #
    $self->{affiliateId}      = $self->formValue( 'a' );
    $self->{affiliateExp}     = $a_exp;
    $self->{adminSafeMode}    = $s_s ||= 0;

    return;
}


=head2 setSiteFriendly

Determine the site friendly url and set it.

    #
    # Set the site friendly URL
    #
    $fws->setSiteFriendly();

=cut

sub setSiteFriendly {
    my ( $self ) = @_;

    #
    # 404 page descisions
    #
    my $sid = $self->formValue( 's' );

    #
    # clean up the sid to make sure there is no funny business going on
    # its used pretty loosly so this will save some front end work
    #
    $sid =~ s/[^a-z0-9]//sgi;

    #
    # if sid is 404 or '' lets default out sid
    #
    if ( $sid eq '404' || $sid eq '' ) {

        #
        # for completeness lets set these to the admin user if they are not set
        #
        ( $sid ) = @{$self->runSQL( SQL=> "select sid from site where default_site = '1' limit 1" )};
        if ( $sid eq '' ) { $sid = 'admin' }
    }


    #
    # if p is not set, then lets figure out how to set it
    #
    if ( $self->formValue( 'p' ) eq '' && $self->formValue( 'pageAction' ) eq '' ) {

        #
        # set the friendlyURL from the URI
        #
        my $friendlyURL = $ENV{REQUEST_URI};
        $friendlyURL =~ s/^\///sg;
        $friendlyURL =~ s/\/$//sg;
        $friendlyURL =~ s/\?(.*)//sg;


        #
        # add any url params pass to the formValue pieces
        #
        my $urlParams = $1;
        my @pairs = split(/&/, $urlParams);
        foreach my $pair (@pairs){
            my ( $name, $value ) = split ( /=/, $pair );
            $self->formValue( $name, $value );
        }

        #
        # switch us to the fws site because we are looking for admin
        # and set the site ID to what it needs to be
        #
        if ( $self->formValue( 'p' ) eq 'admin' || $friendlyURL eq 'admin' ) {
            $self->formValue( 'p' , 'admin' );
        }
        else {
            #
            # get permalink ready for parsing to see if we need to do some exta form field settings
            # we ditch any extension to make it so people can imitate any type of document
            #
            ( my $guidBasedURL = $friendlyURL )     =~ s/\..*//sg;
            my ( $permPage, $permId )               = split( /\//, $guidBasedURL );


            #
            # Add to the union for potential tables that alos hold friendlies
            #
            my $addToUnion;
            my $adminCount = 3;
            for my $table ( keys %{$self->{dataSchema}} ) {
                if ( $table ne 'data' && $self->{dataSchema}{$table}{friendly_url}{type} ) {
                    $addToUnion .= "union SELECT " . $self->safeSQL( $table ) . ".guid," . $self->safeSQL( $table ) . ".page_friendly_url," . $self->safeSQL( $adminCount ) . " as ordering from " . $self->safeSQL( $table ) . " where friendly_url='" . $self->safeSQL ( $friendlyURL ) . "' ";
                    $adminCount++;
                }
            }


            #
            # got a match, siteGUID the siteGUID and and find a freidnly match
            #
            if ( $sid ne '' && $friendlyURL ne '' ) {
                my ( $p, $pageFriendlyURL, $theOrder ) = @{$self->runSQL( SQL =>
                "select data.guid,data.page_friendly_url,1 as ordering from data left join site on site.guid=data.site_guid where site.sid='" . $self->safeSQL( $sid ) . "' and friendly_url='" . $self->safeSQL( $friendlyURL ) . "' ".
                "union select data.guid,data.page_friendly_url,2 as ordering from data left join site on site.guid=data.site_guid where data.guid='" . $self->safeSQL( $permPage ) . "' or (site.sid='" . $self->safeSQL( $sid ) . "' and friendly_url='" . $self->safeSQL( $permPage ) . "') ".
                "union select data.guid,data.page_friendly_url,3 as ordering from data left join site on site.guid=data.site_guid where site.sid='fws' and friendly_url='" . $self->safeSQL ( $friendlyURL ) . "' ".
                $addToUnion.
                "union select '','',999 as ordering order by ordering" )};

                #
                # if order is two, set ID to what ever the second number is after the /
                #
                if ( $theOrder eq '2' ) { $self->formValue( 'id', $self->safeQuery( $permId ) ) }

                if ( $pageFriendlyURL ne '' ) {
                    #
                    # if this page came from a friendly but has pageFriendlyURL, this is special!
                    # it will use the pageFriendlyURL place of its intended page and set its ID to what page it would have been.
                    #
                    $self->formValue( 'id', $p );
                    ( $p ) = @{$self->runSQL( SQL => "select data.guid from data left join site on site.guid=data.site_guid where site.sid='" . $self->safeSQL( $sid ) . "' and friendly_url='" . $self->safeSQL( $pageFriendlyURL ) . "'" )};

                    #
                    # If its blank from the query, then we are talking about the guid from the post
                    #
                    if ( !$p ) { $p = $pageFriendlyURL }
                }
                if ( $p ne '' ) {

                    #
                    # the page does exist and it will show something.
                    # lets just set it the p value and content will
                    # figure out what to do with security in mind also.
                    # if not we will break out the home page of the site.
                    #
                    $self->formValue( 'p', $self->safeQuery( $p ) );
                }
            }
        }
    }

    #
    # at this point we will ne know the sid.  lets set it!
    #
    $self->{siteId} = $sid;
    $self->formValue( 's' , $self->safeQuery( $sid ) );

    return;
}


=head2 language

Get or set the current language.  If no language is currently set, the first entry in language will be used.  If languageArray has not be set, then 'EN' will be used.  The language can be set by being passed as a form value with the name 'fws_lang'.

    #
    # set the language
    #
    $fws->language( 'FR' );

    #
    # get the language
    #
    $valueHash{html} .= 'The current language is: ' . $fws->language() . '<br />';    

=cut

sub language {
    my ( $self, $lang ) = @_;
    if ( defined $lang) { $self->{_language} = $lang }
    if ( !$self->{_language} ) {
        my @langArray = $self->languageArray();
        $self->{_language} = $langArray[0];
    }
    if ( !$self->{_language} ) {  $self->{_language} = 'EN' }
    return uc( $self->{_language} );
}


=head2 languageArray

Set the languages the site will use.  The first one in the list will be considered default.  If languageArray is not set it will just contain 'EN'.

    #
    # set the languages available
    #
    $fws->languageArray( 'EN', 'FR', 'SP' );

=cut

sub languageArray {
    my ( $self, @languageArray ) = @_;
    if ( defined $languageArray[0] ) { $self->{_languageArray} = uc( join( '|', @languageArray ) ) }
    if ( !$self->{_languageArray} ) { return }
    return ( split( /\|/, $self->{_languageArray} ) );
}


=head2 processLogin

Process the web action for logins

    #
    # Run login
    #
    $fws->processLogin();

=cut

sub processLogin {
    my ( $self, $loginType ) = @_;

    $self->runScript( 'preLogin' );

    if ( $self->formValue( 'pageAction' ) eq 'logout' ) {
        $self->userLogOut();
    }

    if ( $self->formValue( 'pageAction' ) eq 'adminLogOut' ) {
        $self->adminLogOut();
        $self->formValue( 'editMode', 0 );
    }

    my $loginStatusNote;
    $loginStatusNote = $self->_localLogin();

    #
    # if statuNote is not blank we failed login criteria
    #
    if ( $loginStatusNote ne '' ) {
        my $pageActionSave = $self->formValue( 'pageActionSave' );
        if ( $pageActionSave eq '' ) {$self->formValue( 'pageActionSave', $self->formValue( 'pageAction' ) ) }
    }

    $self->runScript( 'postLogin' );

    return;
}


=head2 adminLogOut

Log out FWS admin user

    #
    # Log out currently logged in admin user
    #
    $fws->adminLogOut();

=cut

sub adminLogOut {
    my ( $self ) = @_;
    $self->{adminLoginId} = '';
    $self->formValue( 'bs_hold', $self->formValue( 'bs' ) );
    $self->formValue( 'bs', '' );
    return;
}


=head2 userLogOut

Log out FWS site user

    #
    # Log out currently logged in site user
    #
    $fws->userLogOut();

=cut

sub userLogOut {
    my ( $self ) = @_;
    $self->{userLoginId} = '';
    $self->formValue( 'b', '' );

    return;
}


=head2 cryptPassword

Crypt password passing the crypt mmethod you would like to use.  Set $fws->{FWSCrypt} to set method.  Current default is perl crypt.

Current Methods:
    crypt: Perl default crypt


Example: 
    #
    # Log out currently logged in site user
    #
    my $cryptedPass = $fws->cryptPassword( 'thePasswordYourCrypting' );

=cut


sub cryptPassword {
    my ( $self, $password, $cryptType ) = @_;

    #
    # only one exported to core at this point, no need to check
    #
    return substr( crypt( $password, substr( $password, 0 , 2  ) ), 2 );
}

sub _localLogin {
    my ( $self ) = @_;

    #
    # Login if the site critera works for an admin
    #
    if ( $self->formValue( 'bs' ) ne '' && $self->formValue( 'l_password' ) ne '' && $self->formValue( 'pageAction' ) ne 'adminLogOut' ) {
        my ( $adminPass ) = @{$self->runSQL( SQL => "select admin_user_password from admin_user where user_id='" . $self->safeSQL( $self->formValue( 'bs' ) ) . "'" )};

        #
        # take the admin user and crypt the password
        #
        my $formPassword = $self->cryptPassword( $self->formValue( 'l_password' ) );

        #
        # do a switcharoo if we are loggin in as admin
        # this is only used for site setup and will be disabled once a user
        # creates an admin account
        #
        if ( $self->formValue( 'bs' ) eq 'admin' ) {

            #
            # check if we have an isAdmin account.  so we can disable this password
            #
            my $noAdmin = 1;
            my @extraArray = @{$self->runSQL( SQL => "SELECT extra_value from admin_user" )};
            while (@extraArray) {
                #
                # combine the hashes together and check for isAdmin
                #
                my $extraValue = shift @extraArray;
                my %adminHash = $self->mergeExtra( $extraValue );
                if ( $adminHash{isAdmin} ) {
                    $adminPass  = '';
                    $noAdmin    = 0;
                }
            }

            #
            # there isn't an admin account yet,  we can still use the one in the go file
            #
            if ( $noAdmin ) {
                $formPassword   = $self->formValue( 'l_password' );
                $adminPass      = $self->{adminPassword};
            }
        }

        if ( $adminPass eq $formPassword && $adminPass ne '' ) {
            $self->{adminLoginId} = $self->formValue( 'bs' );
            if ( $self->formValue( 'p' ) eq $self->{adminURL} ) { $self->formValue( 'p', $self->homeGUID() ) }
        }
        else {
            $self->formValue( 'statusNote', $self->formValue( 'statusNote' ) . 'Your login criteria was incorrect.' );
            $self->adminLogOut();
        }
    }


    #
    # Login as a profile
    #
    if ( ( ( $self->formValue( 'b' ) ne '' && $self->formValue( 'password' ) ne '' ) )  && $self->formValue( 'pageAction' ) ne 'logout' ) {
        #
        # set the BH field in case we need to use it to show in the field
        #
        $self->formValue( 'bh', $self->formValue( 'b' ) );
        my ( $userGUID, $active, $passCheck, $googleAppsId ) = @{$self->runSQL( SQL => "select guid, active, profile_password, google_id from profile where email like '" . $self->safeSQL( $self->formValue( 'b' ) ) . "'" )};

        my $formPassword = $self->cryptPassword( $self->formValue( 'password' ) );
        if ( ( $passCheck eq $formPassword && $passCheck ne '' ) ) {

            if (!$active) {
                $self->formValue( 'statusNote', $self->formValue( 'statusNote' ) . 'Your account has been disabled.' )
            }
            else {

                $self->{userLoginId} = $self->formValue( 'b' );

                #
                # if for ever reason we are on the default login page, lets dump you to the home page
                # we don't want an endless loop
                #
                if ( $self->formValue( 'p' ) eq 'login' ) { $self->formValue( 'p', $self->homeGUID() ) }

                if ( $self->formValue( 'SAMLRequest' ) ne '' ) {
                    require Google::SAML::Response;
                    Google::SAML::Response->import();

                    if ( $googleAppsId eq '' ) { $self->formValue( 'statusNote', $self->formValue( 'statusNote' ) . 'Your account does not have a google id associated to it.  Contact your user administrator to add this to your account.' ) }
                    else {
                        my $saml = Google::SAML::Response->new( {
                                key     => $self->{googleAppsKeyFile},
                                login   => $googleAppsId,
                                request => $self->urlDecode( $self->formValue( 'SAMLRequest' ) )
                                } );
                        if ( $self->formValue( 'RelayState' ) ne '' ) {
                            $self->printPage( content => $saml->get_google_form( $self->urlDecode( $self->formValue( 'RelayState' ) ) ) );
                        }
                    }
                }
            }
        }
        else { $self->userLogOut() }
    }

    #
    # if we logged in as a admin user lets set our permissions
    #
    if ( $self->{adminLoginId} ) {

        my ( $extraValue ) = @{$self->runSQL( SQL => "SELECT extra_value from admin_user where user_id='" . $self->safeSQL( $self->{adminLoginId} ) . "'" )};

        #
        # combine the hashes together
        #
        my %adminHash = $self->mergeExtra( $extraValue );

        #
        # get the keys and and set them
        #
        for my $key ( keys %adminHash ) { $self->userValue( $key, $adminHash{$key} ) }

        #
        # if we logged in as admin - or we have isAdmin clicked.  lets give the full montie
        #
        if ( $self->{adminLoginId} eq 'admin' ||  $self->userValue( 'isAdmin' ) eq '1' ) {
            #
            # just to make sure, if did come in to 'admin' then mark isAdmin to 1
            #
            $self->userValue( 'isAdmin', 1 );

            #
            # Restrict the login if they came in on the adminSafePassword
            #
            if ( $self->{adminSafeMode} eq '1' ) {
                $self->userValue( 'showDeveloper', '0' );
                $self->userValue( 'showAdminUsers', '0' );
                $self->userValue( 'isAdmin', '0' );
            }
        }

        #
        # if we are not an admin person.  lets make sure we cant touch the admin table
        #
        else { $self->userValue( 'showAdminUsers', '0' ) }
    }

    #
    # we aren't logged in as an admin, lets ditch edit mode!
    #
    if ( !$self->{adminLoginId} ) { $self->formValue( 'editMode', 0 ) }


    #
    # we aren't logged in at all, lets ditch anything dangerous
    #
    #
    if ( !$self->{userLoginId} && !$self->{adminLoginId} ) {

        #
        # safe page actions its allowd to be set to. if not ditch the pageAction
        # this is an artifact of some old code pageAction code, and eventually should be removed
        #
        if ( $self->formValue( 'pageAction' ) !~ /^(\d+|addToNewsList|formMail|recoverPassword|updateCart|addProfile)$/) {
            $self->formValue( 'pageAction', '' )
        }
        if ( $self->formValue( 'l_password' ) ne '' ) { $self->formValue( 'editMode', 0 ) }
        if ( $self->formValue( 'password' ) ne '' || $self->formValue( 'l_password' ) ne '' ) {
            return 'Your password is invalid or expired';
        }
    }

    return;
}


=head2 saveFormValue

Mark a formValue to remain persistant with the session.  The return of this function will be the current saveWithSessionHash.
    
    #
    # This should go in a 'init' element or located int he go.pl file
    # at any point it can be referenced via formValue
    #
    $fws->saveFormValue( 'myCity' );

=cut

sub saveFormValue {
    my ( $self, $fieldName ) = @_;
    #
    # add to session
    #
    my %saveWithSession = $self->_saveWithSessionHash();
    $saveWithSession{$fieldName} = 1;
    return $self->_saveWithSessionHash( %saveWithSession );
}

=head2 saveSession

Commit the current session to the sessions table.   This is only needed if you need to cmmit the session before you perform a 302 redirect or if yuor immitating the pringPage() method with a custom one.   Not the session does actually do anything if its values have not chagned from its innital load from the session table.

    #
    # This should go in a 'init' element or located int he go.pl file
    # at any point it can be referenced via formValue
    #
    $fws->saveSession();

=cut

sub saveSession {
    my ( $self, $fieldName ) = @_;

    #
    # get the save with session hash put together
    #
    my $sessionScript = '';
    my %saveWithSessionHash = $self->_saveWithSessionHash();
    for my $sessionKey ( keys %saveWithSessionHash ) {
        my $keyValue = $self->formValue( $sessionKey );
        $sessionScript .= $sessionKey . '|' . $self->urlEncode( $keyValue ) . '|';
    }

    #
    # set the editMode in range if it is blank
    #
    if ( !$self->formValue( 'editMode' ) ) { $self->formValue( 'editMode', 0 ) }

    #
    # Set the cookie and update the session.. and other groovy header rutines
    # only if it is diffrent lets update it
    #
    if ( $self->formValue( 'FWS_SESSION' ) ne $self->{userLoginId} . '|' . $self->language() . '|' . $self->{adminLoginId} . '|' . $ENV{REMOTE_ADDR} . '|' . $self->formValue( 'editMode' ) . '|' . $self->{affiliateId} . '|' . $self->{affiliateExp} . '|' . $self->{adminSafeMode} . '|' . $sessionScript ) {
        #
        # run the SQL to update the session
        #
            $self->runSQL( SQL => "update fws_sessions set fws_lang='" . $self->safeSQL( $self->language() ) . "', b='" . $self->safeSQL( $self->{userLoginId} ) . "', s='" . $self->safeSQL( $self->{adminSafeMode} ) . "', bs='" . $self->safeSQL( $self->{adminLoginId} ) . "', ip='" . $self->safeSQL( $ENV{REMOTE_ADDR} ) . "', e='" . $self->safeSQL( $self->formValue( 'editMode' ) ) . "', a='" . $self->safeSQL( $self->{affiliateId} ) . "', a_exp='" . $self->safeSQL( $self->{affiliateExp} ) . "', extra_value='" . $self->safeSQL( $sessionScript ) . "' where id='" . $self->safeSQL( $self->formValue( 'session' ) ) . "'" );
    }
}


=head2 setSiteValues

Set default values derived from the site settings for a site.  This will also set the formValue 'p' to the homeGUID if no 'p' value is currently set.

    #
    # currently rendered site
    #
    $fws->setSiteValues();

    #
    # set site values for some other site
    #
    $fws->setSiteValues( 'othersite' );

=cut

sub setSiteValues {
    my ( $self, $siteId ) = @_;

    #
    # pre-set the valuse if they are not already
    #
    if ( $siteId ) { $self->{siteId} = $siteId }

    #
    # if for any reason this thing is still blank, lets use our default "site"
    #
    if ( !$self->{siteId} ) { $self->{siteId} = 'site' }

    #
    # get and set site assigned values
    #
    my $siteExtraValue;
    my $default_site;
    ( $self->{siteId}, $self->{languageArray}, $self->{siteName}, $self->{site}{cssDevel}, $self->{site}{jsDevel}, $self->{siteGUID}, $siteExtraValue, $default_site, $self->{gatewayUserID}, $self->{gatewayType}, $self->{email}, $self->{site}{homeGUID} ) = @{$self->runSQL( SQL => "select sid, language_array, name, css_devel, js_devel, guid, extra_value, default_site, gateway_user_id, gateway_type, email, home_guid from site where sid='" . $self->safeSQL( $self->{siteId} ) . "'" )};

    #
    # if we didn't get defined then then this is not the default site
    #
    $default_site ||= 0;
        
    #
    # if this is STILL blank, something bad happened, lets still set it to site
    #
    $self->{siteId} ||= 'site';

    #
    # move the lang into the useable array
    #
    $self->languageArray( split( ',', $self->{languageArray} ) ) if $self->{languageArray};

    #
    # if for any reason homeGUID is blank, lets make a new one and its page
    # but only do it, if we have a real site.  Just skip it because we could
    # be doing something else that isn't site rendering
    #
    if ( !$self->{site}{homeGUID} && $self->{siteGUID} ) {
        my $homeGUID = $self->{siteGUID};
        $homeGUID =~ s/^./h/sg;
        $self->siteValue( 'homeGUID', $homeGUID );
        $self->runSQL( SQL => "update site set home_guid='" . $self->safeSQL( $homeGUID ) . "' where guid='" . $self->safeSQL( $self->{siteGUID} ) . "'" );

        #
        # make the actual page
        # there isn't actually a type home, this is the flag that allows you to make a 
        # xref that does not have a parent it will be flipped to 'page' 
        #
        $self->saveData( type => 'home', parent => '', newGUID => $homeGUID );
    }

    #
    # check to see if there is no level... if so then we need create a new admin account
    #
    if ( !$self->{siteGUID} ) { print $self->createFWSDatabase() }

    #
    # convert the values and fields to global valuse
    #
    my %siteHash = $self->mergeExtra( $siteExtraValue );

    #
    # get the keys and and set them
    #
    for my $key ( keys %siteHash ) { $self->siteValue( $key, $siteHash{$key} ) }

    #
    # set the data cache hash
    #
    my @indexArray = split( /,/, $self->siteValue( 'dataCacheIndex' ) );
    while (@indexArray) { $self->{dataCacheFields}->{shift(@indexArray)} = 1 }

    #
    # if we are not the default site turn off friendlies
    #
    if ( $default_site ne '1' ) { $self->siteValue( 'noFriendlies', '1' ) }
    else { $self->siteValue( 'noFriendlies', '0' ) }

    #
    # Now that we have the session we can set the queryHead
    #
    $self->{queryHead} = "?fws_noCache=" . 
        $self->createPassword( composition => 'qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM',lowLength=>6,highLength=>6) . 
        "&session=" . $self->formValue( 'session' ) . 
        "&s=" . $self->{siteId} . "&";

    #
    # if p is still blank, lets set it
    #
    if ( $self->formValue( 'p' ) eq '' ) { $self->formValue( 'p', $self->siteValue( 'homeGUID' ) ) }

    #
    # set where we will get FWS files from
    #
    $self->{fileFWSPath} = $self->fileWebPath() . '/fws';

    return;
}


=head2 siteValue

Get or save a siteValue for the session.

    #
    # save something
    #
    $fws->siteValue( 'something', 'this is something' );

    #
    # get something
    #
    my $something = $fws->siteValue( 'something' );

=cut

sub siteValue {
    my ( $self, $field, $fieldVal ) =  @_;
    if ( defined $fieldVal ) { $self->{site}{$field} = $fieldVal }
    if ( !defined $self->{site}{$field} ) { $self->{site}{$field} = '' }
    return $self->{site}{$field};
}


=head2 userValue

Get an admin user value.  This is used mostly for security flags and is only used to get values FWS has set.   

    #
    # is the admin user a developer?
    #
    my $isDeveloper = $fws->userValue( 'isDeveloper' );

=cut

sub userValue {
    my ( $self, $field, $fieldVal ) =  @_;
    if ( defined $fieldVal ) { $self->{user}{$field} = $fieldVal }
    if ( !defined $self->{user}{$field} ) { $self->{user}{$field} = '' }
    return $self->{user}{$field};
}


sub _saveWithSessionHash {
    my ( $self, %saveWithSessionHash ) = @_;
    if ( keys %saveWithSessionHash ) { %{$self->{_saveWithSessionHash}} = %saveWithSessionHash }

    #
    # add the save with session site value directive also
    
    my @addSession = split( /,/, $self->siteValue( 'saveWithSession' ) );
    while ( @addSession ) { ${$self->{_saveWithSessionHash}}{ shift @addSession } = 1 }

    return %{$self->{_saveWithSessionHash}};
}




=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Session


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FWS-V2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FWS-V2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FWS-V2>

=item * Search CPAN

L<http://search.cpan.org/dist/FWS-V2/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::Session
