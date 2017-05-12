package FWS::V2::Display;

use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';

=head1 NAME

FWS::V2::Display - Framework Sites version 2 web display methods

=head1 VERSION

Version 1.13091122

=cut

our $VERSION = '1.13091122';


=head1 SYNOPSIS

    use FWS::V2;

    my $fws = FWS::V2->new();


=head1 DESCRIPTION

FWS version 2 core web display methods

=head1 METHODS

=head2 addToFoot

Add content to the html just above the body tag.

=cut

sub addToFoot {
    my ( $self, $addToFootVar ) = @_;
    $self->siteValue( 'pageFoot', $addToFootVar . $self->siteValue( 'pageFoot' ) );
    return;
}


=head2 addToHead

Add content to the html head area.

=cut

sub addToHead {
    my ( $self, $addToHeadVar ) = @_;
    $self->siteValue( 'pageHead', $addToHeadVar . $self->siteValue( 'pageHead' ) );
    return;
}


=head2 FWSHead

Return the head html for a fws page rendering.

=cut

sub FWSHead {
    my ( $self ) = @_;

    my $pageTitle = $self->siteValue( 'pageTitle' );

    if ( !$pageTitle && $self->formValue( 'p' ) =~ /^fws_/ ) {
        $pageTitle = 'FrameWork Sites ' . $self->{FWSVersion};
        $self->jqueryEnable( 'ui-1.8.9' );
        $self->jqueryEnable( 'ui.widget-1.8.9' );
        $self->jqueryEnable( 'ui.mouse-1.8.9' );
        $self->jqueryEnable( 'ui.dialog-1.8.9' );
        $self->jqueryEnable( 'ui.datepicker-1.8.9' );
        $self->jqueryEnable( 'ui.slider-1.8.9' );
        $self->jqueryEnable( 'timepickr-0.9.6' );
        $self->jqueryEnable( 'ui.position-1.8.9' );
    }

    my $html = '<title>' . $pageTitle . "</title>\n";
    if ( $self->siteValue( 'pageKeywords' ) )     { $html .= '<meta name="keywords" content="' . $self->siteValue( 'pageKeywords' ) . "\"/>\n" }
    if ( $self->siteValue( 'pageDescription' ) )  { $html .= '<meta name="description" content="' . $self->siteValue( 'pageDescription' ) . "\"/>\n" }


    #
    # Load jquery in head if it is flagged to, if not it will be lazy loaded
    #
    my %jqueryHash = %{$self->{_jqueryHash}};
    if ( keys %jqueryHash && $self->{loadJQueryInHead} ) {
        $html .= "<script type=\"text/javascript\" src=\"" . $self->{fileFWSPath} . "/jquery/jquery-1.7.1.min.js\"></script>\n";
    }


    return $html . $self->siteValue( 'pageHead' ) . $self->siteValue( 'templateHead' );
}


=head2 FWSJava

Return the lazy loaded JavaScript including anything added to the pageFoot.

=cut

sub FWSJava { 
    my ( $self ) = @_;
     
    #
    # add tinyMCE if needed fixes a FF bug if we lazy load it.
    #
    my $pageJava;
    if ( $self->siteValue( 'urchinId' ) && !$self->formValue( 'editMode' ) ) {
        $pageJava .= "<script type=\"text/javascript\">\n";
        $pageJava .= "var gaJsHost = ((\"https:\" == document.location.protocol) ? \"https://ssl.\" : \"http://www.\");\n";
        $pageJava .= "document.write(unescape(\"%3Cscript src='\" + gaJsHost + \"google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E\"));\n";
        $pageJava .= "</script>\n";
        $pageJava .= "<script type=\"text/javascript\">\n";
        $pageJava .= "var pageTracker = _gat._getTracker(\"" . $self->siteValue( 'urchinId' ) . "\");\n";
        $pageJava .= "pageTracker._initData();\n";
        $pageJava .= "pageTracker._trackPageview();\n";
        $pageJava .= "</script>\n";
    }
   
  
    #
    # at some point landingId should be settable in site settings
    #
    if ( $self->siteValue( 'facebookAppId' ) ) {
    
        my $landingId = $self->safeQuery( $self->formValue( 'p' ) );
        if ( $self->formValue( 'id' ) ) { $landingId .= '&id=' . $self->safeQuery( $self->formValue( 'id' ) ) }

        $pageJava .= '<div id="fb-root"></div><script>';

        #
        # tell FB we are french if we are
        #
        my $FBLang = 'en_US';
        if ( $self->language() =~ /fr/i ) { $FBLang = 'fr_CA' }

        #
        # leave this split up goofy for now.  The code compressor freaks out a bit on
        # on this when it is formated better, so it is this way on pupose.  I need to update
        # the compressor first before we can pretty this up
        #
        $pageJava .= 
            'window.fbAsyncInit = function () {' .
                "FB.init({ appId: '" . $self->siteValue( 'facebookAppId' ) . "', oauth: true, cookie: true, status: true, xfbml: true" . '}); ' .
                'FB.getLoginStatus(function (response) {' .
                    "if (response.session) {\$('#loginFBLoginBox').hide(); } " .
                    "else {\$('#loginFBLoginBox').show(); } " .
                '}); ';

        #
        # prevent recursive FB Redirects
        #
        if ( !$self->isUserLoggedIn() ) {
            $pageJava .=
                "FB.Event.subscribe('auth.login', function () {" .
                    "window.location = '" . $self->{scriptName} . '?s=' . $self->{siteId} . '&p=' . $landingId . "&FBRedirect=1'; " .
                '}); ';
        }

        $pageJava .=
            '}; ' .
            '(function () {' .
                "var e = document.createElement('script'); e.async = true; " .
                'e.src = document.location.protocol + ' .
                "'//connect.facebook.net/" . $FBLang . "/all.js'; " .
                "document.getElementById('fb-root').appendChild(e); " .
            ' }());' ;
    
            if ( $self->formValue( 'FBRedirect' ) ) {
                $pageJava .= "window.location = '" . $self->{scriptName} . '?s=' . $self->{siteId} . '&p=' . $landingId ."'; ";
            }
            $pageJava .= '</script>';
    }
   

    $pageJava .= $self->siteValue( 'pageFoot' );
    return $pageJava;
}


 

=head2 displayContent

Return the full web rendering for a FWS Page.   This includes the Content-Type HTML headers.   preContent hook element can be added to a site that will run before any rendering takes place.

=cut

sub displayContent {
    my ( $self ) = @_;
#$self->setPageCache();

    $self->runScript( 'preContent' );

    #
    # return just statusNote formfield created by the actions.  Useful mostly in ajax calls
    #
    if ( $self->formValue( 'returnStatusNote' ) ) {
        print "Content-Type: text/html; charset=UTF-8\n\n";
        print $self->formValue( 'statusNote' );
    }

    #
    # if returnAndDoNothing is specified as a formValue get the hell out of here and .... do nothing!
    # TODO Think returnAndDoNothing isn't needed anymore
    #
    elsif ( $self->formValue( 'returnAndDoNothing' ) ne '1' ) {

        #
        # all is good and lets just make sure this flag wasn't set by a element and print the page
        #
        if ( $self->formValue( 'returnAndDoNothing' ) ne '1') {  
            $self->printPage( content => $self->_FWSContent() );
        }
    }
    return;
}


=head2 printPage

Return the processed FWS Page,  this can be used for any content type and is not prefaced with any specific web headers  During this process the session will be updated if it was changed from when it was received .

=cut

sub printPage {
    my ( $self, %paramHash ) = @_;

    #
    # default stop processing to off
    #
    $self->{stopProcessing} ||= 0;



    if ( !$self->{stopProcessing} ) {

        #
        # set default content dispoistion
        #
        $paramHash{contentDisposition}    ||= 'attachment';

        #
        # set the content type if we didn't get it in
        #
        $paramHash{contentType}           ||= 'text/html; charset=UTF-8';

        #
        # TODO don't think returnAdnDoNothing is needed anymore
        # bust out of here if there is nothing to do
        #
        if ( $self->formValue( 'returnAndDoNothing' ) ) { return }

        #
        # do reverse friendly logic to turn friendly URLs to non friendlies
        #
        if ( $self->siteValue( 'noFriendlies' ) && $self->formValue( 'p' ) !~ /^fws_/ ) {
            my @friendlyArray = @{$self->runSQL( SQL => "SELECT friendly_url FROM data WHERE site_guid='" . $self->{siteGUID} . "'  and (element_type='page')" )};
            while (@friendlyArray) {
                my $FURL = shift @friendlyArray;
                my $nonFURL = $self->{scriptName} . $self->{queryHead} . 'p=' . $FURL;
                $paramHash{content} =~ s/"\/$FURL"/"$nonFURL"/g;
            }
        }

        $self->saveSession();


        #
        # Return HTTP
        # Trim the domain name so it only ahs this.com without the host name.  this will fix stuff to make these all the same cookie
        # www.gnetworks.com secure.gnetworks.com www2.gnetworks.com cricket.gnetworks.com......
        #
        my $cookieDomain;
        my $cookie;
        if ( $self->{cookieDomainName} ) {
            $cookieDomain = ' domain=' . $self->{cookieDomainName} . ';';
        }
        
        #
        # if domainName doesn't have more than two dots in it, it is invalid by browsers
        # so lets kill it if thats the case so it will use a null/empty type value
        #
        if ( ($cookieDomain =~ tr/\.//) < 2 ) { $cookieDomain = '' }

        #
        # build the cookies for display
        #
        $cookie .= 'Set-Cookie: ' . $self->{sessionCookieName} . '=' . $self->formValue( 'session' ) . ';' . $cookieDomain . ' Path=/;' . ' Expires=' . $self->formatDate( format => 'cookie', monthMod => 1 ) . "\n";
        $cookie .= 'Set-Cookie: fbsr_' . $self->siteValue( 'facebookAppId' ) . '=deleted; Path=/;' . " Expires=Thu, 01-Jan-1970 00:00:01 GMT\n";

        #
        # simple page rendering
        #
        if ( $paramHash{head} ) {
            $paramHash{content} = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">\n<head>\n" . $paramHash{head} . "</head>\n<body>\n" . $paramHash{content} . "\n" . $paramHash{foot} . "\n</body>\n</html>";
        }

        #
        # always return a 200
        #
        my $theHeader   = "Status: 200 OK\n";

        #
        # if the contentType doesn't have HTML in it, lets not pass the cookies
        #
        if ( $paramHash{contentType} =~ /html/i )   { $theHeader .= $cookie }
                                                      $theHeader .= "Accept-Ranges: bytes\n";
        if ( $paramHash{contentLength} )            { $theHeader .= 'Content-Length: ' . $paramHash{contentLength} . "\n" }
        if ( $paramHash{accessControlAllowOrigin} ) { $theHeader .= 'Access-Control-Allow-Origin: ' . $paramHash{accessControlAllowOrigin} . "\n" }
        if ( $paramHash{fileName} )                 { $theHeader .= 'Content-disposition: ' . $paramHash{contentDisposition} . ';' . ' filename="' . $paramHash{fileName} . "\"\n" }
                                                      $theHeader .= 'Content-Type: ' . $paramHash{contentType} . "\n\n";

        #
        # in case this was sent via a eval from an eplement, lets set the formvalue
        #
        $self->formValue( 'FWS_showElementOnly', 1 );

        if ( $self->formValue( 'redirect' ) ) {
            print "Status: 302 Found\n";
            print 'Location: ' . $self->urlDecode( $self->formValue( 'redirect' ) ) . "\n\n";
        }
        else { 
            print $theHeader  . $paramHash{content};
        }

        #
        # process our queue for every page we render
        # 
        $self->processQueue();

        #
        # shut off processing so we never do this more than once
        #
        $self->{stopProcessing} = 1;
    }
    return;
}


sub _FWSContent {
    my ( $self ) = @_;


    my $pageHTML;

    if ( !$self->{stopProcessing} ) {
    
    

        my $pageId = $self->safeSQL( $self->formValue( 'p' ) );

        #
        # this flag will suppress any access wrapping around the element
        #
        my $showElementOnly = 0;

        #
        # if this is an admin url move to a adminLogin
        #
        if ( $pageId eq $self->{adminURL} ) { $self->displayAdminLogin() }

        #
        # if this is an ispadmin contorl process the page differntly
        #
        if ( $pageId =~ /^fws_/ ) { $self->displayAdminPage() }

        if ( $pageId eq 'favicon.ico' ) {
            print "Status: 404 Not Found\n";
            print "Connection: close\n";
            print "Content-Type: text/html\n\n";
            print "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">\n";
            print "<HTML><HEAD>\n<TITLE>404 Not Found</TITLE>\n</HEAD><BODY>\n<H1>Not Found</H1>\n<P>The requested file is not available or does not exist.</P>\n</BODY></HTML>";
            $self->{stopProcessing} = 1;
        }

        if ( $pageId eq "robots.txt" ) {
            if( !$self->siteValue( 'robots.txt' ) ) {
                $self->siteValue( 'robots.txt', "User-agent: *\nDisallow: " . $self->{scriptName} . "\nAllow: /\n" );
            }
            my $robotsContent = $self->siteValue( 'robots.txt' );
            print "Status: 200 OK\n";
            print "Accept-Ranges: bytes\n";
            print "Content-Length: " . length( $robotsContent ) . "\n";
            print "Content-Type:text/plain\n\n";
            print $robotsContent;
            $self->{stopProcessing} = 1;
        }

        if ( !$self->{stopProcessing} ) {

            my $addToUnion;
            for my $table ( keys %{$self->{dataSchema}} ) {
                if ( $table ne 'data' && $self->{dataSchema}{$table}{friendly_url}{type} ) {
                    $addToUnion .= "union SELECT 1,'',''," . $self->safeSQL( $table ) . ".friendly_url,'" . $self->safeSQL( $self->{siteGUID} ) . "',data.guid," . $self->safeSQL( $table ) . ".page_friendly_url,'' from " . $self->safeSQL( $table ) . " left join data on data.friendly_url=" . $self->safeSQL( $table ) . ".page_friendly_url where " . $self->safeSQL( $table ) . ".friendly_url='" . $pageId . "' ";
                }
            }

            #
            # set page defaults if we have them
            #
            my @pageArray = @{$self->runSQL( SQL => "select 0,extra_value,title,friendly_url,site_guid,guid,element_type,name from data where (friendly_url like '" . $self->safeSQL( $pageId ) . "' or guid = '" . $self->safeSQL( $pageId ) . "') and (site_guid='" . $self->safeSQL( $self->{siteGUID} ) . "') union select 0,extra_value,title,friendly_url,site_guid,guid,element_type,name from data where (friendly_url like '" . $self->safeSQL( $pageId ) . "' or guid = '" . $self->safeSQL ( $pageId ) . "') and (site_guid='" . $self->safeSQL( $self->fwsGUID() ) . "')" . $addToUnion )};

            #
            # shave off the first one in case there is two
            #
            my %pageHash;
            my $dynamicFriendly           = shift @pageArray;
            my $pageExtraValue            = shift @pageArray;
            $pageHash{title}              = shift @pageArray;
            $pageHash{friendlyURL}        = shift @pageArray;
            $pageHash{siteGUID}           = shift @pageArray;
            $pageHash{guid}               = shift @pageArray;
            $pageHash{type}               = shift @pageArray;
            $pageHash{name}               = shift @pageArray;
            %pageHash = $self->mergeExtra( $pageExtraValue, %pageHash );

            #
            # if this is blank, that means we are talking about a homepage that does not exist yet
            #
            if ( !$pageHash{guid} ) {
                if ( $self->siteValue( 'homeGUID' ) eq $pageId ) {
                    %pageHash = $self->saveData(
                            guid    => $pageId,
                            active  => '1',
                            name    => '',
                            type    => 'page',
                            parent  => ''
                            );
                }
                else {
                    #
                    # the page we are looking for does not exist.  Lets get back and show some home page!
                    #
                    %pageHash   = $self->dataHash( guid => $self->siteValue( 'homeGUID' ) );
                    $pageId     = $self->siteValue( 'homeGUID' );
                    $self->formValue( 'p', $pageId );
                }
            }

            #
            # if we DO have a guid, then lets set pageId to what the guid is in case we came in from a p=friendlyurl
            #
            else { $pageId = $pageHash{guid} }

            #
            # set the intial page type to be used to determin if we should be putting columns
            #
            my $pageHead;
            my $somethingIsOnThePage = 0;
            my %templateHash         = $self->templateHash( pageGIUD => $pageId );

            #
            # lets not change this stuff around if we are on an aadmin page of some sort
            #
            if ( $pageId !~ /^fws_/ ) {
                #
                # ONLY if these things aren't set by elements,  then set them by the page defaults... if not pass them by and accept what it already is
                #
                if ( !$self->siteValue( 'pageTitle' ) )         { $self->siteValue( 'pageTitle'         , $self->{siteName} . ' - ' . $pageHash{title} ) }
                if ( !$self->siteValue( 'pageKeywords' ) )      { $self->siteValue( 'pageKeywords'      , $pageHash{pageKeywords} ) }
                if ( !$self->siteValue( 'pageDescription' ) )   { $self->siteValue( 'pageDescription'   , $pageHash{pageDescription} ) }
            }

            #
            # set the dir\filename it will be the same for all these files,
            #
            my $fileDir = $self->{fileWebPath} . "/" . $self->{siteGUID} . "/";

            #
            # Template level CSS
            #
            if ( $templateHash{css} > 0 ) {
                $self->_cssEnable( $self->{siteGUID} . "/" . $templateHash{guid} . "/FWSElement-" . $templateHash{css} );
                $somethingIsOnThePage = 1;
            }
            if ( $templateHash{js} > 0 ) {
                $self->_jsEnable( $self->{siteGUID} . "/" . $templateHash{guid} . "/FWSElement-" . $templateHash{js} );
                $somethingIsOnThePage = 1;
            }

            #
            # site level css and js
            #
            $pageHead .= $self->siteValue( 'siteHead' );
            if ( $self->siteValue( 'cssDevel' ) > 0 ) {
                $self->_cssEnable( $self->{siteGUID} . "/assets/FWSElement-" . $self->siteValue( 'cssDevel' ) );
                $somethingIsOnThePage = 1;
            }
            if ( $self->siteValue( 'jsDevel' ) > 0 ) {
                $self->_jsEnable( $self->{siteGUID} . "/assets/FWSElement-" . $self->siteValue( 'jsDevel' ) );
                $somethingIsOnThePage = 1;
            }

            #
            # Page level CSS
            #
            $pageHead .= $pageHash{pageHead};
            if ( $pageHash{cssDevel} > 0 ) {
                $self->_cssEnable( $self->{siteGUID} . "/" . $pageId . "/FWSElement-" . $pageHash{cssDevel} );
                $somethingIsOnThePage = 1;
            }
            if ( $pageHash{jsDevel} > 0 ) {
                $self->_jsEnable( $self->{siteGUID} . "/" . $pageId . "/FWSElement-" . $pageHash{jsDevel} );
                $somethingIsOnThePage = 1;
            }

            #
            # set page head
            #
            $self->siteValue( 'pageHead', $pageHead );

            #
            # if the pageTitle ends with ' - ' then eat it
            #
            ( my $cleanTitle = $self->siteValue( 'pageTitle' ) ) =~ s/\s*(-|\|)\s*$//g;
            $self->siteValue( 'pageTitle', $cleanTitle );

            my @elements = $self->openRS("select distinct d1.extra_value, d1.site_guid, x2.layout, d1.active, x1.ord+(d1.default_element*100000) as real_ord, x1.layout, d1.disable_edit_mode, d1.groups_guid, d1.guid, d1.element_type, d1.name, d1.title, d1.show_resubscribe, d1.show_login, d1.show_mobile, d1.lang, d1.friendly_url, d1.page_friendly_url, d1.default_element, d1.disable_title, d1.nav_name  from data d1 LEFT JOIN guid_xref x1 ON (d1.guid = x1.child) left join guid_xref x2 on (x2.child = x1.parent) left join data d2 on (x2.child=d2.guid) where (d1.site_guid = '" . $self->safeSQL( $self->{siteGUID} ) . "' or d1.site_guid = '" . $self->safeSQL( $self->fwsGUID() ) . "') and d1.element_type <> 'data' and d1.element_type <> 'url' and d1.element_type <> 'page' and (x1.parent='' or d1.guid='" . $self->safeSQL( $pageId ) . "' or (d2.element_type='page')) and (((x1.parent='" . $self->safeSQL( $pageId ) . "') or d1.default_element <> '0') or d1.guid='" . $self->safeSQL( $pageId ) . "') order by x1.layout, real_ord", 1);

            #
            # set the pageTitle Hash into a fws var
            #
            $self->formValue( 'fws_pageTitle'                , $pageHash{pageTitle} );
            $self->formValue( 'fws_pageNavigationName'       , $pageHash{name} );
            $self->formValue( 'fws_pageReferenceId'          , $pageHash{name} );
            $self->formValue( 'fws_pageId'                   , $pageHash{guid} );
            $self->formValue( 'fws_secureDomain'             , $self->{secureDomain} );
            $self->formValue( 'fws_domain'                   , $self->{domain} );

            #
            # Mech to figure out what number layout in the list we are so we can set class based on location ancestory
            #
            my %layoutCountHash;


            my $columnWrapperStartFlag  = 0;
            my $columnWrapperStopFlag   = 0;
            my $lastLayoutId            = 0;
            my $elementTotal            = 0;
            my %columnContent;
            my %columnCount;
            my $FWSMenu;

            #
            # set the hash we use to ensure we don't use an default element more than once on the same page
            #
            my %elementUsed;

            #
            # here is some js and css hashs so we don't add multipuls to each page if ther eis more than one element that has the same file on one page
            #
            my %JSHash;
            my %CSSHash;

            while ( @elements ) {
                #
                # start with ext hash, and then overwrite if there is conflicts
                #
                my $extraValue                = shift @elements;
                my %valueHash                 = $self->mergeExtra( $extraValue );

                $valueHash{siteGUID}          = shift @elements;
                my $elementTemplateId         = shift @elements;
                $valueHash{active}            = shift @elements;
                $valueHash{ord}               = shift @elements;
                $valueHash{layout}            = shift @elements;
                $valueHash{disableEditMode}   = shift @elements;
                $valueHash{userGroup}         = shift @elements;
                $valueHash{guid}              = shift @elements;
                $valueHash{type}              = shift @elements;
                $valueHash{name}              = shift @elements;
                $valueHash{title}             = shift @elements;
                $valueHash{showResubscribe}   = shift @elements;
                $valueHash{showLogin}         = shift @elements;
                $valueHash{showMobile}        = shift @elements;
                $valueHash{lang}              = shift @elements;
                $valueHash{friendlyURL}       = shift @elements;
                $valueHash{pageFriendlyURL}   = shift @elements;
                $valueHash{defaultElement}    = shift @elements;
                $valueHash{disableTitle}      = shift @elements;
                $valueHash{navigationName}    = shift @elements;
 
                #
                # make sure userGroup is numeric
                #
                $valueHash{userGroup} ||= 0;

                #
                # if title is blank, lets use name
                #
                $valueHash{title} ||= $valueHash{name};

                #
                # a couple of presets we will need
                #
                $valueHash{editBoxColor}    = "#FF0000";

                #
                # This should be legacy at some point and replaced with pageGUID... we will address later
                #
                $valueHash{parent}          = $pageId;

                #
                # by defult lets give a delete button to everything
                #
                $valueHash{deleteTool}      = 1;

                #
                # figure out the layout area and tweek for normilization
                #
                my $layoutCount             = $layoutCountHash{$valueHash{layout}};
                $layoutCountHash{$valueHash{layout}}++;
                if ( $elementTemplateId eq '') {     $elementTemplateId = $templateHash{homeGUID} }
                if ( $elementTemplateId eq '0') {    $elementTemplateId = $templateHash{defaultGUID} }

                #
                # make sure we are talking about the element on a compatable page... or we are cool if the element is the dirived element because it was
                # accessed via p=theElementId or p=theFriendlyUrl or /theElementsFriendlyURL
                #    
                # And Check to see if we already spit out this element to the page
                #
                if ( ( $elementTemplateId eq $templateHash{guid} || $valueHash{guid} eq $pageId ) && !$elementUsed{$valueHash{guid}} ) {

                    #
                    # set the flag so we don't use it more than once
                    #
                    $elementUsed{$valueHash{guid}} = 1;

                    #
                    # is active or not
                    #
                    if (( $valueHash{active} || ( $self->formValue( 'editMode' ) ) ) ) {

                        $valueHash{layout} ||= 1;

                        #
                        # LOGIN GROUP KEY
                        #
                        # 0     No login required
                        # 1     Show if logged in as a site user
                        # -101  Show if logged in as a admin user
                        # -103  Show if logged in as a subscriber
                        # -1    Do not show if logged in as a site user
                        # -102  Do not show if logged in as a admin user
                        # -104  Do not show if logged in as a subscriber';

                        #
                        # if userGroup ne 0 then we need to be logged in or supress
                        #
                        if ( $valueHash{userGroup} ne '0' ) {
                            my %userHash  = $self->userHash();

                            #
                            # if If group ID is "-1" then all I need to be is just logged in
                            # Special login code group flag checker
                            #
                            %userHash = $self->runScript( 'login', 
                                %userHash,
                                'userGroup'             => $valueHash{userGroup},
                                'type'                  => $valueHash{type},
                                'showLogin'             => $valueHash{showLogin},
                                'showResubscribe'       => $valueHash{showResubscribe},

                                # LEGACY NAMES
                                'elementType'           => $valueHash{type},
                                'show_login'            => $valueHash{showLogin},
                                'show_resubscribe'      => $valueHash{showResubscribe},
                            );

                            #
                            # se the login mod stuff back in case it changed form the script
                            #
                            $valueHash{type}      = $userHash{elementType};

                            #
                            # you must be admin logged in to see it.
                            #
                            if ( $userHash{userGroup} eq '-101' && !$self->isAdminLoggedIn() ) {
                                $valueHash{type} = '';
                            }

                            #
                            # you must be admin logged in to see it.
                            #
                            if ( $userHash{userGroup} eq '-102' && $self->isAdminLoggedIn() ) {
                                $valueHash{type} = '';
                            }

                            #
                            # you can't be logged in to see it. supress the element
                            #
                            if ( $userHash{userGroup} eq '-1' && $userHash{active} ) { 
                               $valueHash{type} = '';
                            }


                            #
                            # if this is set to 0 then negative the login because it must have been set that way
                            # from the loginMod,  This is a string and can contain guids, so we can't use math here
                            #
                            if ( $userHash{userGroup} !~ /^-/ || $userHash{userGroup} eq '0') {

                                #
                                # If group ID is "1" then all I need to be is just logged in
                                #
                                if ( $userHash{userGroup} eq '1' && $userHash{active} ) {
                                    #DON't panic.  we good to go! we won't switch anyting
                                }

                                #
                                # If we have a spacific group, figure it out and do it
                                #
                                elsif ( $userHash{group}{$userHash{userGroup}} && $userHash{active} ) {
                                    #Nice! we are gtg, don't do anything
                                }

                                #
                                # Set elementType  your not set to see, set login or blank the element
                                #
                                else {
                                    if ( $userHash{show_login} ) { 
                                        $valueHash{type} = 'FWSLogin';
                                    }
                                    else {
                                        $valueHash{type} = '';
                                    }
                                }
                            }
                        }

                        #
                        # If your a mobile device, and your mobile is set to (2) show desktop only then eat the type
                        #
                        if ( $ENV{HTTP_USER_AGENT} =~ /mobile/i && $valueHash{showMobile} eq '2' ) {
                            $valueHash{type} = '';
                        }

                        #
                        # If your NOT a mobile device, and your mobile is set to (1) show mobile only then eat the type
                        #
                        if ( $ENV{HTTP_USER_AGENT} !~ /mobile/i && $valueHash{showMobile} eq '1' ) {
                            $valueHash{type} = '';
                        }

                        #
                        # set defaults and get the editBox going
                        #
                        my $html;

                        #
                        # set elementId in a formValue so the FWS can use it when working with adminField function
                        #
                        $self->formValue( 'FWS_elementId', $valueHash{guid} );
                        $self->formValue( 'FWS_pageId', $pageId );

                        #
                        # Get the element
                        #
                        my %elementHash = $self->elementHash( guid => $valueHash{type} );

                        #
                        # add css or js if its needed
                        #
                        if ( !$JSHash{$valueHash{type}} && $elementHash{jsDevel} ) {
                            $JSHash{$valueHash{type}} = 1;
                            $self->_jsEnable( $elementHash{siteGUID} . "/" . $valueHash{type} . "/FWSElement-" . $elementHash{jsDevel},-1000 );
                        }
                        if ( !$CSSHash{$valueHash{type}} && $elementHash{cssDevel} ) {
                            $CSSHash{$valueHash{type}} = 1;
                            $self->_cssEnable( $elementHash{siteGUID} . "/" . $valueHash{type} . "/FWSElement-" . $elementHash{cssDevel},-1000 );
                        }

                        #
                        # convert the code to the fws friendly version
                        #
                        $elementHash{scriptDevel} =~ s/self-/fws-/g;

                        #
                        # copy the GNF object to fws
                        #
                        my $fws = $self;

                        #
                        # set the valueHash for value conduit style programming
                        #
                        #my %valueHash;
                        $valueHash{pageId}            = $pageId;
                        $valueHash{elementId}         = $valueHash{guid};
                        $valueHash{elementWebPath}    = $self->{fileWebPath} . "/" . $elementHash{siteGUID} . "/" . $valueHash{type};

                        #
                        # set this so its available in the elementStart via the FWS_elementClassPrefix, and valueHash
                        #
                        $self->formValue( 'FWS_elementClassPrefix', $elementHash{classPrefix} );
                        $valueHash{classPrefix} = $elementHash{classPrefix};

                        #
                        #
                        # run the script and inject it into the html for the node
                        #
                        my $htmlHold = $html;
                        $html = '';
                        ## no critic qw(RequireCheckingReturnValueOfEval ProhibitStringyEval)
                        eval $elementHash{scriptDevel};
                        ## use critic
                        my $errorCode = $@;
                        if ( $errorCode ) {
                            $valueHash{html} .= "<div style=\"border:solid 1px;font-weight:bold;\">FrameWork Element Error:</div><div style=\"font-style:italic;\">" . $errorCode . "</div>";
                        }

                        #
                        # now put it back
                        #
                        $self = $fws;
                        $html = $valueHash{html};

                        #
                        # if we are updating a element from editModeUpdate - then just do that only
                        #
                        if ( $self->formValue( 'FWS_editModeUpdate' ) && $pageId eq $valueHash{guid} ) {
                            #
                            # make sure debug is turned off, because that would look silly in fws devel mode
                            #
                            return $self->editBox(%valueHash) . $html
                        }
                        else {
                            #
                            # if this is a showElementOnly then ditch the current page up to this point
                            # and also ditch out of the element loop
                            #
                            if ( $showElementOnly || $self->formValue( 'FWS_showElementOnly') ) { return $html }
                            else { $html = $htmlHold . $html }
                        }

                        #
                        # start the top of the element if its new
                        #
                        if ( !$columnContent{$valueHash{layout}} ) {
                            $columnCount{$valueHash{layout}} = 0;
                        }

                        #
                        # increment the column count
                        #
                        $columnCount{$valueHash{layout}}++;

                        #
                        # create the edit control if we are supposed to
                        #
                        my $editBox;

                        $columnContent{$valueHash{layout}} .= "<div" . $editBox . " class=\"" . $valueHash{layout} . "_element element_" . $valueHash{guid} . "\" id=\"" . $valueHash{layout} . "_element_" . $columnCount{$valueHash{layout}} . "\">";

                        if ( ( $self->{adminLoginId} && $valueHash{siteGUID} eq $self->{siteGUID} && !$self->formValue( 'FWS_showElementOnly' ) && !$showElementOnly && !$valueHash{disableEditMode} && $self->formValue( 'editMode' ) ) )  {
                            $columnContent{$valueHash{layout}} .= $self->editBox( %valueHash, AJAXDivStyle => 'border: solid 1px #FF0000;border-top: 0;', editBoxContent => $html );
                        }
                        else {
                            $columnContent{$valueHash{layout}} .= $html;
                        }

                        $elementTotal++;
                        $columnContent{$valueHash{layout}} .= "</div>";
                    }
                }
            }

            #
            # check if this is the home page, with no stuff on it,  if not we need to dump to login, or redirect to fws_systemInfo
            # only do this for the site though, if your making blank other sites for other reasons lets just let that happen
            #
            if ( $elementTotal < 1 && $pageId eq $self->homeGUID() && !$somethingIsOnThePage && $self->formValue( 's' ) eq 'site' ) {
                if ( $self->{adminLoginId} ) {
                    print "Status: 302 Found\n";
                    print "Location: " . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo\n\n";
                }
                else {
                    $self->displayAdminLogin();
                }
            }
            

            if ( !$showElementOnly ) {
    
                $pageHTML = $templateHash{template};
    
                #
                # Put in the edit mode box if we are in edit mod and loged in as the correct user for this site
                #
    
                if ( $self->{adminLoginId} ) {
                    #
                    # set all the things we could need
                    #
                    $self->{tinyMCEEnable} = 1;
                    $self->jqueryEnable( 'ui-1.8.9' );
                    $self->jqueryEnable( 'ui.widget-1.8.9' );
                    $self->jqueryEnable( 'ui.mouse-1.8.9' );
                    $self->jqueryEnable( 'ui.datepicker-1.8.9' );
                    $self->jqueryEnable( 'ui.slider-1.8.9' );
                    $self->jqueryEnable( 'timepickr-0.9.6' );
                    $self->jqueryEnable( 'ui.tabs-1.8.9' );
                    $self->jqueryEnable( 'simplemodal-1.4.4' );
                    $self->jqueryEnable( 'fileupload-ui-4.4.1' );
                    $self->jqueryEnable( 'fileupload-4.5.1' );
                    $self->jqueryEnable( 'fileupload-uix-4.6' );
                    $self->jqueryEnable( 'ui.fws-1.8.9' );
    
                    if ( $pageId eq $self->homeGUID() ) { $pageHash{disableDeleteTool} = 1 }
                    $pageHash{layout}             = 'FWSPageMenu';
                    $pageHash{guid}               = $pageId;
                    $pageHash{FWSMenuTool}        = 1;
                    $pageHash{pageOnly}           = 1;
                    $pageHash{alwaysShow}         = 1;
                    $pageHash{disableActiveTool}  = 1;
                    $pageHash{disableOrderTool}   = 1;
                    if ( $pageHash{siteGUID} eq $self->{siteGUID} ) {
                        $pageHash{name} = $self->FWSMenu( pageId => $pageId ) . $pageHash{name};
                    }
                    else {
                        $pageHash{addElementTool}     = 0;
                        $pageHash{disableDeleteTool}  = 1;
                        $pageHash{disableEditTool}    = 1;
                        $pageHash{disableActiveTool}  = 1;
                        $pageHash{disableOrderTool}   = 1;
                        $pageHash{name} = "Default FWS Page - To override this page create a new page with the friendly url of [ " . $pageHash{friendlyURL} . " ]";
                    }
    
    
                    #
                    # if we are not able to see the buttons lets kill them
                    #
                    if ( ( !$self->userValue( 'showDesign' ) && !$self->userValue( 'showContent' ) && !$self->userValue( 'showDeveloper' ) ) || ( $pageHash{siteGUID} ne $self->{siteGUID} ) ) {
                        $pageHash{addElementTool}       = 0;
                        $pageHash{disableDeleteTool}    = 1;
                        $pageHash{disableEditTool}      = 1;
                        $pageHash{disableActiveTool}    = 1;
                        $pageHash{disableOrderTool}     = 1;
                    }
    
                    $pageHash{editBoxColor} = '#000000';
                    $FWSMenu .= $self->editBox( %pageHash );
                }
    
                #
                # before we print head and foot css and js we need to compile and set cache
                #
                $self->setPageCache();

                #
                # add the head where it goes
                #
                my $FWSHead = $self->FWSHead();
                $pageHTML   =~ s/#FWSHead#/$FWSHead/g;
    
                #
                # add the menu
                #
                $pageHTML =~ s/#FWSMenu#/$FWSMenu/g;
    
                #
                # Clean up the adminLoggedIn stuff
                #
                $pageHTML =~ s/#FWSAdminLoggedIn#//g;
                $pageHTML =~ s/#FWSAdminLoggedInEnd#//g;
    
                #
                # but all non-main info in the page
                #
                while ( $templateHash{template} =~ /#FWSShow-(.*?)#/g ) {
                    my $layout = $1;
                    if ( $layout ne 'main' ) {
        
                        #
                        # add it to the page
                        #
                        $pageHTML = $self->_replaceContentColumn(
                            layout          => $layout,
                            html            => $pageHTML,
                            content         => $columnContent{$layout},
                            guid            => $pageId,
                            contentType     => 'FWSShow',
                            pageType        => $pageHash{type},
                            siteGUID        => $pageHash{siteGUID},
                        );
        
                        #
                        # delete it so we don't add it to main in the next section
                        #
                        delete $columnContent{$layout};
                    }
                }
    
                #
                # but all non-main info in the page
                #
                while ( $templateHash{template} =~ /#FWSShowNoHeader-(.*?)#/g ) {
                    my $layout = $1;
                    if ( $layout ne 'main' ) {
    
                        #
                        # add it to the page
                        #
                        $pageHTML = $self->_replaceContentColumn(
                            layout          => $layout,
                            html            => $pageHTML,
                            content         => $columnContent{$layout},
                            guid            => $pageId,
                            contentType     => 'FWSShowNoHeader',
                            pageType        => $pageHash{type},
                            siteGUID        => $pageHash{siteGUID},
                        );
    
                        #
                        # delete it so we don't add it to main in the next section
                        #
                        delete $columnContent{$layout};
                    }
                }
    
                #
                # add the rest to main
                #
                for my $columnKey ( keys %columnContent ) {
                    if ( $columnContent{$columnKey} ne '' && $columnKey ne 'main' ) {
                        $columnContent{main} .= $columnContent{$columnKey};
                    }
                }
    
                #
                # add main to the page
                #
                while ( $templateHash{template} =~ /#FWSShow-main#/g ) {
                    $pageHTML = $self->_replaceContentColumn(
                            layout          => 'main',
                            html            => $pageHTML,
                            content         => $columnContent{main},
                            guid            => $pageId,
                            contentType     => 'FWSShow',
                            pageType        => $pageHash{type},
                            siteGUID        => $pageHash{siteGUID},
                    );
                }
   
   
                my $FWSJava = $self->FWSJava(); 
                $pageHTML =~ s/#FWSJavaLoad#/$FWSJava/g;
    
    
                my $FWSLink = "<a href=\"http://www.frameworksites.com/poweredByFrameWorkSites\"><img style=\"border: 0 none;\" src=\"https://www.frameworksites.com/poweredByFrameWorkSites.jpg\" alt=\"This site was built using FrameWork Sites!\"/></a>";
                $pageHTML =~ s/#FWSLink#/$FWSLink/g;
                while ( $pageHTML =~ /#FWSField-(.*?)#/g ) {
                    my $formField = $1;
                    my $changeFrom = '#FWSField-' . $formField . '#';
                    my $changeTo = $self->removeHTML( $self->formValue( $formField ) );
                    $pageHTML =~ s/$changeFrom/$changeTo/g;
                }
            }
        }
    }
    return $pageHTML;
}



sub _replaceContentColumn {
    my ( $self, %editHash ) = @_;

    $editHash{id}                 = $editHash{guid};
    $editHash{type}               = '';
    $editHash{editBoxColor}       = '#2b6fb6';
    $editHash{layoutTitle}        = 1;
    $editHash{addSubElementTool}  = 0;
    $editHash{disableEditTool}    = 1;
    $editHash{disableActiveTool}  = 1;
    $editHash{orderTool}           = 1;
    $editHash{name}               = '| ' . $editHash{layout} . ' |';
    my $changeFrom                = '#' . $editHash{contentType} . '-' . $editHash{layout} . '#';
    my $changeTo                  = '<div class="FWSLanguage-' . uc( $self->language() ) . '" id="' . $editHash{layout} . '">';

    if ( $editHash{siteGUID} ne $self->fwsGUID() || $self->{showFWSInSiteList} ) {
        if ( $self->formValue( 'editMode' ) && $editHash{contentType} ne 'FWSShowNoHeader' && $editHash{pageType} eq 'page' && !$self->{hideEditModeHeaders} ) {
            $changeTo .= $self->editBox( %editHash );
        }
    }

    $changeTo          .= $editHash{content} . '</div>';
    $editHash{html}    =~ s/$changeFrom/$changeTo/msg;

    return( $editHash{html} );
}

=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Display


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

1; # End of FWS::V2::Display
