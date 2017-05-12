package FWS::V2::Admin;

use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';

=head1 NAME

FWS::V2::Admin - Framework Sites version 2 internal administration

=head1 VERSION

Version 1.13091122

=cut

our $VERSION = '1.13091122';


=head1 SYNOPSIS

    use FWS::V2;

    #
    # Create $fws
    #
    my $fws = FWS::V2->new();


=head1 DESCRIPTION

These methods are used by the FWS to perform web based admin features.  Most methods here are not for general use and can change at any time, reference these in plugins and element for experimental reasons only.

=cut


=head1 METHODS

These modules are used for FWS admin display and logic.   They should not be used outside of the context of FWS admin modules specific to the current build.

=cut


=head2 runAdminAction

Run admin actions.  This will be depricated once they are all moved into the FWS display elements.

=cut

sub runAdminAction {
    my ( $self ) = @_;
    if ( $self->isAdminLoggedIn() && !$self->{stopProcessing} ) { $self->_processAdminAction() }
    return;
}


=head2 adminPageHeader

Return a standard HTML admin header for admin elements that open in new pages.

    #
    # Header for an admin page that opens in a new window
    #
    $valueHash{html} .= $fws->adminPageHeader(    
        name            => 'Page Name in the upper right',
        rightContent    => 'This will show up on the right,' .
                           'usually its a saving widget',
        title           => 'This is title on the left, it will' .
                           'look just like a panel title',
        icon            => 'somethingInTheFWSIconDirectory.png');

NOTE: This should only be used in the context of the FWS Administration, and is only here as a reference for modifiers of the admin.

=cut

sub adminPageHeader {
    my ( $self, %paramHash ) = @_;
    my $bgIcon;
    my $headerHTML = "<div class=\"FWSAdminPageHeader\">";
    $headerHTML .= "<div class=\"FWSAdminPageHeaderPageTitle\">" . $paramHash{name} . "</div>";
    $headerHTML .= "<div class=\"FWSAdminPageHeaderTitle\">" . $paramHash{title} . "</div>";
    $headerHTML .= "<div class=\"FWSAdminPageHeaderContent\">" . $paramHash{rightContent} . "</div>";
    $headerHTML .= "</div>";

    return $headerHTML;
}


=head2 displayAdminLogin

Return the HTML used for a default FWS admin login.

=cut

sub displayAdminLogin {
    my ( $self, @tabList ) = @_;
    my $pageId = $self->formValue('p');

    my $loginForm = "<div class=\"FWSAdminLoginContainer\"><div id=\"FWSAdminLogin\">";
    $loginForm .= "<form method=\"post\" enctype=\"multipart/form-data\" action=\"" . $self->{scriptName} . "\">";

    $loginForm .= "<h2>FWS Administrator Login</h2>";

    $loginForm .= "<div class=\"FWSAdminLoginLeft\"><label for=\"FWSAdminLoginUser\">Username:</label><br/><input type=\"text\" name=\"bs\" id=\"FWSAdminLoginUser\" value=\"" . $self->formValue("bs_hold") . "\" /></div>";
    $loginForm .= "<div class=\"FWSAdminLoginRight\"><label for=\"FWSAdminLoginPassword\">Password:</label><br/><input id=\"FWSAdminLoginPassword\" type=\"password\" name=\"l_password\" /></div>";

    $loginForm .= "<div class=\"clear\"></div>";

    $loginForm .= "<input class=\"FWSAdminLoginButton\" type=\"submit\" title=\"Login\" value=\"Login\" />";

    $loginForm .= "<input type=\"hidden\" name=\"p\" value=\"" . $self->{adminURL} . "\"/>";
    $loginForm .= "<input type=\"hidden\" name=\"session\" value=\"" . $self->formValue("session") . "\"/>";
    $loginForm .= "<input type=\"hidden\" name=\"id\" value=\"" . $self->safeQuery( $self->formValue( "id" ) ) . "\"/>";
    $loginForm .= "<input type=\"hidden\" id=\"s\" name=\"s\" value=\"" . $self->formValue("s") . "\"/>";

    $loginForm .= "</form>";
    $loginForm .= "</div>";

    $loginForm .= "<div class=\"FWSAdminLoginLegal\">Powered by Framework Sites v" . $self->{FWSVersion} . "</div>";

    $loginForm .= "</div></div>";

    return $self->printPage( content => $loginForm, head => $self->_minCSS() );
}



=head2 editField

Some legacy fields still use this render drop downs.   For new code do not use this.

=cut

sub editField {
    my ( $self, %paramHash ) = @_;

    #
    # if elementId is not passed lets use the one was stored just before the eval was ran
    # this will be undocumented that you can set it... not sure if will come up for security or cross refrenced stuff
    # but it won't need coding if it makes sense later
    #
    $paramHash{elementId} ||= $self->formValue( 'FWS_elementId' );

    #
    # set context of the params to match the default interal stuff it will need
    #
    if ( $paramHash{guid} ) {
        $paramHash{ajaxUpdateTable}   = 'data';
        $paramHash{ajaxUpdateGUID}    = $paramHash{guid};
        $paramHash{updateType}        = $paramHash{elementId};
        $paramHash{pageAction}        = $paramHash{elementId};
    }

    #
    # Set the value
    #
    if ( $paramHash{fieldValue} eq '' && $paramHash{guid} ) {
        my %dataHash              = $self->dataHash( guid => $paramHash{guid} );
        $paramHash{fieldValue}    = $dataHash{$paramHash{fieldName}};
    }

    $paramHash{guid}              = $paramHash{fieldName};

    return $self->adminField(%paramHash);
}


=head2 tabs

Return jQueryUI tab html.  The tab names, tab content, tinyMCE editing field name, and any javascript for the tab onclick is passed as arrays to the method.

    #
    # add the data to the tabs and panels to the HTML
    #
    $valueHash{html} .= $self->tabs(
        id              => 'theIdOfTheTabContainer',
        tabs            => [@tabs],
        tabContent      => [@tabContent],
        tabJava         => [@tabJava],

        # html and file tab support
        tabType         => [@tabType],       # file, html or leave empty for standard panel
                                             # setting type will overwrite content and java provided

        tabFields       => [@tabFields],     # field your updating

        guid            => 'someGUID',       # guid your updating

        # optional if your talking to a non-data table
        tabUpdateType   => [@tabUpdateType], # defaults to AJAXExt
        table           => 'data',           # defaults to data

        # for file type only (required)
        currentFile     => [@currentFile],   #
    );

NOTE: This should only be used in the context of the FWS Administration, and is only here as a reference for modifiers of the admin.   In future versions this will be replaced with a hash array style paramater to make this less cumbersome, but this will be avaiable for legacy controls.

=cut

sub tabs {
    my ( $self, %paramHash ) = @_;

    #
    # this will be the counter we will use for inique IDs for each tab for referencing
    #
    my $tabCount = 0;

    #
    # seed our tab html and the div html that will hold the content
    #
    my $tabDivHTML;
    my $tabHTML = "<div id=\"" . $paramHash{id} . "\" class=\"FWSTabs tabContainer ui-tabs ui-widget ui-widget-content ui-corner-all\"><ul class=\"tabList ui-tabs ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all\">";

    while (@{$paramHash{tabs}}) {
        my $tabJava         = shift( @{$paramHash{tabJava}} );
        my $tabContent      = shift( @{$paramHash{tabContent}} );
        my $tabName         = shift( @{$paramHash{tabs}} );
        my $fieldName       = shift( @{$paramHash{tabFields}} );
        my $tabType         = shift( @{$paramHash{tabType}} );
        my $tabUpdateType   = shift( @{$paramHash{tabUpdateType}} );
        my $currentFile     = $self->urlEncode( shift( @{$paramHash{currentFile}} ) );

        #
        # set the default
        #
        $tabUpdateType ||= 'AJAXExt';

        #
        # pass all the info in as the id so we can save it later
        #
        my $editorName  = $paramHash{guid} . "_v_" . $fieldName . "_v_" . $paramHash{table} . "_v_" . $tabUpdateType;

        #
        # tab type overwrites tabJava and tabContent!
        #
        if ( $tabType eq 'file' ) {
            $tabContent = "<div id=\"dataEdit" . $fieldName . "\">Loading...</div>";
            $tabJava    = "if(\$('#dataEdit" . $fieldName . "').html().length < 50) {\$('#dataEdit" . $fieldName . "').FWSAjax({queryString: '" . $self->{queryHead} . "p=fws_fileManager&current_file=" . $currentFile . "&field_update_type=" . $tabUpdateType . "&field_table=" . $paramHash{table} . "&field_name=" . $fieldName . "&guid=" . $paramHash{guid} . "',showLoading: false});}";
        }

        if ( $tabType eq 'html' ) {
            $tabContent = "<div name=\"" . $fieldName . "\" id=\"" . $editorName . "\" class=\"HTMLEditor\" style=\"width:100%;height:445px;\">" . $tabContent . "</div><div style=\"display:none;\" id=\"" . $paramHash{guid} . "_v_" . $fieldName . "_v_StatusNote\"></div>";
        }

        #
        # this is the connector between the tab and its HTML
        #
        my $tabHRef     = $paramHash{id} . "_" . $tabCount . "_" . $self->createPassword( composition => 'qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM', lowLength => 6, highLength => 6 );

        #
        # if tiny mce is being used on a tab, lets light it up per the clicky
        # also tack on any tabJava we had passed to us
        #
        my $javaScript      = "FWSCloseMCE();";
        $javaScript        .= "if ( typeof(tinyMCE) != 'undefined' ) { tinyMCE.execCommand('mceAddControl', false, '" . $editorName . "'); }";
        $javaScript        .= "if ( typeof(\$.modal) != 'undefined' ) { \$.modal.update(); }";
        $javaScript        .= "if ( typeof(\$.modal) != 'undefined' ) { \$.modal.update(); }";
        $javaScript        .= $tabJava;
        $javaScript        .= "return false;";

        #
        # flag we are on the first one!... we want to hide the content areas if we are not
        #
        my $hideMe;
        if ( $tabCount > 0 ) { $hideMe = " ui-tabs-hide" }

        #
        # add to the tab LI and the HTML we will put below for each tab
        #
        $tabHTML        .= "<li class=\"tabItem tabItem ui-state-default ui-corner-top ui-state-hover\"><a onclick=\"" . $javaScript . "\" href=\"#" . $tabHRef . "\">" . $tabName . "</a></li>";
        $tabDivHTML     .= "<div id=\"" . $tabHRef . "\" class=\"ui-tabs-panel ui-widget-content ui-corner-bottom" . $hideMe . "\">" . $tabContent . "</div>";

        #
        # add another tabCount to make our next tab unique ( plus a unique 6 char key )
        #
        $tabCount++;
    }

    #
    # the tabs need this jquery ui stuff to work.  lets make sure they are here if they aren't laoded already
    #
    $self->jqueryEnable( 'ui-1.8.9' );
    $self->jqueryEnable( 'ui.widget-1.8.9' );
    $self->jqueryEnable( 'ui.tabs-1.8.9' );
    $self->jqueryEnable( 'ui.fws-1.8.9' );

    #
    # return the tab content closing the ul and div we started in tabHTML
    #
    return $tabHTML . '</ul>' . $tabDivHTML . '</div>';
}


=head2 importSiteImage

Unpack a agnostic DB and File administration packages via FWS administration distrubuted by framworksites.com.

=cut

sub importSiteImage {
    my ( $self, %paramHash ) = @_;

    my $image               = $paramHash{image};
    my $imageFile           = $paramHash{imageFile};
    my $imageURL            = $paramHash{imageURL};
    my $tableList           = $paramHash{tableList};
    my $deleteBeforeImport  = $paramHash{deleteBeforeImport};
    my $filesOnly           = $paramHash{filesOnly};
    my $dataOnly            = $paramHash{dataOnly};
    my $postField           = $paramHash{postField};

    my $importReturn;
    my %importTable;

    #
    # create a import file and start writing to it depending onhow we got the file in
    #
    my $importFile = $self->fileSecurePath() . "/import_" . $self->formatDate( format => 'number' ) . ".fws";

    open ( my $IFILE, ">", $importFile );

    #
    # we have an image string save it off so we can process it with the file handle
    #
    if ( $image ) { print $IFILE $image }

    #
    # if we got a URL get it!
    #
    if ( $imageURL ) {
        require LWP::UserAgent;
        my $browser         = LWP::UserAgent->new();
        my $response        = $browser->get( $imageURL );
        if (!$response->is_success ) { return "Error connecting to the FWS Module Server was found: " . $response->status_line }
        print $IFILE $response->content;
    }

    #
    # if it is ac existing site, use the admin password already there. if not leave it blank so it won't allow logins
    #
    my ( $siteActive, $siteGUID, $homeGUID ) = @{$self->runSQL( SQL => "select 1,site_guid,home_guid from site where sid = '" . $paramHash{newSID} . "'" )};

    #
    # get the tables we are going to import and set them to on.
    #
    my @tables = split( ',', $tableList );
    while ( @tables ) {
        my $theTable = shift( @tables );
        $importTable{$theTable} = 1;
    }

    #
    # read textImage if that was handed to us
    #
    if ( $postField ) {
        my $bytesread;
        my $buffer;
        while ( $bytesread = read( $self->formValue( $postField ), $buffer, 1024 ) ) {
            $buffer =~ s/[\x0A\x0D]+/\n/g;
            print $IFILE $buffer;
        }
    }

    #
    # read file if that was handed to us
    #
    if ( $imageFile ) {
        open ( my $FILE, "<", $imageFile );
        while ( my $inputLine = <$FILE> ) { print $IFILE $inputLine . "\n" };
        close $FILE;
    }


    #
    # close the import file down so we can reopen it for processing
    #
    close $IFILE;

    #
    # double check if the site is valid,  in case this is ran from a script
    # most importanly we want to make sure the site_guid isnt already there
    #

    #
    # if we are talking aout the admin import, or an elementOnly import let this ride
    #
    my $validSite = $self->_isValidSID( $paramHash{newSID} );


    #
    # set a flag for elementOnly
    #
    my $elementOnly = 0;
    if ( ( split(/\n/, $image ) )[0] eq "ELEMENT ONLY" )  {
        $importReturn = "Importing element to existing site ID:" . $paramHash{newSID};
        $elementOnly = 1;
    }

    if ( $validSite && $paramHash{newSID} ne 'zipcode' && $paramHash{newSID} ne 'admin' && !$elementOnly) { return " " .  $validSite . " No import was performed." }

    #
    # if it is an element Only import, make sure the site_guid is valid
    #
    if ( ( $elementOnly && !$siteActive ) || !$paramHash{newSID} ) { return "The FWS File is an element import file, and '" . $paramHash{newSID} . "' is not a valid Site ID.  No element import was performed." }

    if ( !-s $importFile ) { return "The FWS File is invalid.  No import was performed." }

    #
    # get the site GUID we are importing to
    #
    $siteGUID ||= $self->createGUID( 's' );

    #
    # if this is an fws import we need the fws id and import away
    #
    if ( $paramHash{newSID} eq 'fws' ) {
        $siteGUID = $self->safeSQL( $self->fwsGUID() );

        #
        # blow away all the stuff the is FWS so we can come in fresh
        #
        if ( $paramHash{removeCore} ) {
            $self->runSQL( SQL => "delete from data where guid like 'f%'" );
            $self->runSQL( SQL => "delete from element where guid like 'f%'" );
            $self->runSQL( SQL => "delete from guid_xref where site_guid = '" . $self->safeSQL( $siteGUID ) . "'" );
            $self->runSQL( SQL => "delete from data_cache where guid like 'f%'" );
        }
    }

    #
    # decompress and process
    #
    my $fileName;
    my $fileReading;
    my %tableSchema;
    my $keepAliveCount        = 0;
    $paramHash{keepAlive}   ||= 0;


    open( my $READ_FILE, "<", $importFile );

    while (my $line = <$READ_FILE>) {
            $line =~ s/\n$//g;
            $keepAliveCount++;
            if ( $line =~ /^FILE_END\|/ && !$dataOnly ) {
                #
                # get just the directory so we can make the dir in case it does not exist already
                #
                my $fileDir = $self->{filePath} . $fileName;
                my @splitDir = split( /\//, $fileDir );
                pop(@splitDir);
                my $justDirectory = join( "/", @splitDir );

                #
                # make sure nothing dangrous is in the dir
                #
                $justDirectory =~ s/\/\//\//sg;

                #
                # if we are not doing an element only, or the file starts with /admin save the file
                #
                if ( !$self->formValue( 'elementOnly' ) || $fileName =~ /^\/admin\// ) {
                    #
                    # create the directory to make sure its good
                    #
                    $self->makeDir( $justDirectory );

                    #
                    # save the file to that directory
                    #
                    $self->saveEncodedBinary( $self->{filePath} . $fileName, $fileReading );
                }

                #
                # reset so when we come around again we will no we are done.
                #
                $fileName = '';
                $fileReading = '';
            }

            #
            # if we have a file name,  we are currenlty looking for a
            # file.  eat those lines up and stick them in a diffrent var
            #
            elsif ( $fileName ) { $fileReading .= $line . "\n" }

            #
            # if this is a start of a file, lets get it set up and
            # define the file name, the next time we go around we
            # will be looking at the base 64
            #
            elsif ( $line =~ /^FILE\|/  && !$dataOnly ) {
                my @fileNameArray = split(/\|/,$line);
                $fileName = $fileNameArray[1];
                $fileName =~ s/#FWSSiteGUID#/$siteGUID/sg;
            }

            #
            # ALLLRIGHTY, this isn't a file, lets process it like it
            # it is a normal database row that needs to be processed
            #
            else {
                my @data = split( /\|/, $line );

                my $tableName = shift( @data );

                my @fieldList = split( ',', $tableSchema{$tableName} );
                my $numberOfFields = $#fieldList;

                #
                # if we havn't seen this table before that means its a schema
                #
                if ( !defined $tableSchema{$tableName} ) { $tableSchema{$tableName} =  shift(@data) }
                else {
                    my $cleanData;
                    my $dataCount  = 0;
                    my $skipComma  = 1;
                    my $skipInsert = 0;
                    my $fieldNames = $tableSchema{$tableName};

                    for( my $dataCount=0; $dataCount <= $numberOfFields; $dataCount++ ) {

                        #
                        # decode the data and flip stuf arround that needs to be groomed
                        #
                        $data[$dataCount] = $self->urlDecode( $data[$dataCount] );
                        
                        #
                        # Set the new sid
                        #
                        if ( $tableName eq 'site' && $fieldList[$dataCount] eq 'sid' ) { $data[$dataCount] = $paramHash{newSID} }

                        if ( $tableName eq 'site' && $fieldList[$dataCount] eq 'site_guid' ) {
                            #
                            # we need the admin guid for this install.
                            #
                            my ( $parentSID ) = @{$self->runSQL( SQL => "select guid from site where sid='admin'" )};
                            $data[$dataCount] = $parentSID;
                        }

                        #
                        # if we are importing stuff from the admin, we need these to be fws
                        #
                        if ( $paramHash{newSID} eq 'admin' ) {
                            if ( $tableName eq 'data'        && $fieldList[$dataCount] eq 'site_guid' ) {   $data[$dataCount] = 'fws'}
                            if ( $tableName eq 'guid_xref'   && $fieldList[$dataCount] eq 'site_guid' ) {   $data[$dataCount] = 'fws'}
                        }


                        #
                        # if we hvan't already skip the first comma, and then add the field
                        #
                        if (!$skipComma) { $cleanData .= ',' }


                        #
                        # clean and format the data from the import storage
                        #
                        $data[$dataCount] = $self->_convertImportTags( content => $data[$dataCount], siteGUID => $siteGUID, homeGUID => $homeGUID );

                        #
                        # convert safe text export back to the storable version
                        #
                        if ( $fieldList[$dataCount] eq 'extra_value' ) {
                            my @splitExtra = split(/\|/,$data[$dataCount]);
                            my %extraHash;
                            while (@splitExtra) {
                                my $field     = shift @splitExtra;
                                my $value     = shift @splitExtra;
                                $value        = $self->urlDecode( $value );
                                $value        = $self->_convertImportTags( content => $value, siteGUID => $siteGUID, homeGUID => $homeGUID );
                                $extraHash{$self->urlDecode( $field )} = $value;
                            }
                            use Storable qw(nfreeze thaw);
                            $data[$dataCount] = nfreeze(\%extraHash);
                        }

                        #
                        # add to the insert statement string
                        #
                        if ( $data[$dataCount] =~ /^null$/i ) { $cleanData .=  'null' }
                        else { $cleanData .= "'" . $self->safeSQL( $data[$dataCount] ) . "'" }

                        $skipComma = 0;

                    }

                    #
                    # process what we collected from th loop
                    #

                    #
                    # lets check to make sure we are only going to do elements if we are element only
                    #
                    if ( ( $tableName ne "element" && $self->formValue( "elementOnly" ) ) ) {
                        $skipInsert = 1;
                    }

                    #
                    # only add the data to the DB if the we are not set to fileOnly mode,
                    # and if we are not on special
                    # fields that do not have.
                    #
                    if (!$skipInsert && !$filesOnly ) {

                        my $siteCSS;
                        my $siteJavaScript;
                        my $pageJavaScript;
                        my $pageCSS;
                        $self->runSQL( SQL => "insert into " . $tableName . " (" . $fieldNames . ") values (" . $cleanData . ")" );

                    }
                }
            }
            if ( $keepAliveCount > $paramHash{keepAlive} ) {
                $keepAliveCount = 0;
                if ( $paramHash{keepAlive} ) { print " ." }
            }
        }
    close $READ_FILE;
    return $importReturn;
}
    

=head2 adminField

Return an edit field or field block for the FWS Admin.   The adminField method is a very configurable tool used by the FWS administration maintainers.

    #
    # Create a admin edit field
    #
    $valueHash{html} .= $fws->adminField( %paramHash );

NOTE: This should only be used in the context of the FWS Administration, and is only here as a reference for modifiers of the admin.

Passable Keys:
    fieldType
    fieldName
    fieldValue
    fieldOptions
    unilingual: [1|0]
    ajaxUpdateGUID
    ajaxUpdateParentId
    id
    class
    style
    onSaveComplete
    updateType
    guid
    onKeyDown
    note
    afterFieldHTML

=cut

sub adminField {
    my ( $self, %paramHash ) = @_;

    #
    # for language replication fields, hold the array here so we can use it clean
    #
    my %origHash = %paramHash;

    #
    # set the id if not already set or if we going to use ajax, lets make a
    # new id so we don't get dups from bad programming
    #
    if ( !$paramHash{id} || $paramHash{updateType} ) { $paramHash{id} = $paramHash{fieldName} }

    #
    # make the guid for ajax unique if needed
    #
    $paramHash{guid} ||= $paramHash{fieldName};

    #
    # Set the uniqueId to something other than guyid if its passed, for save icon references
    #
    $paramHash{uniqueId} ||= $paramHash{fieldName};

    #
    # if these are blank, add them to the unique to make it more unique
    #
    if ( $paramHash{ajaxUpdateGUID} )     { $paramHash{uniqueId} .= "_" . $paramHash{ajaxUpdateGUID} }
    if ( $paramHash{ajaxUpdateParentId} ) { $paramHash{uniqueId} .= "_" . $paramHash{ajaxUpdateParentId} }

    #
    # if we are talking about a date, we are recieving it in SQL format, lets flip it real quicik
    # before we display it
    #
    if ( $paramHash{fieldType} eq 'dateTime' && $paramHash{fieldValue} ne '') {

        #
        # convert from SQL format and spin it around for normal US date formats
        #
        if ( $paramHash{dateFormat} =~ /(sql|)/i ) {
            my ( $year, $month, $day, $hour, $minute, $second ) = split( /\D/, $paramHash{fieldValue} );
            $paramHash{fieldValue} = $month . "-" . $day . "-" . $year . " " . $hour . ":" . $minute . ":" . $second;
        }
    }

    #
    # if we are talking about a date, we are recieving it in SQL format, lets flip it real quicik
    # before we display it
    #
    if ( $paramHash{fieldType} eq 'date' && $paramHash{fieldValue} ne '' ) {

        #
        # convert from SQL format and spin it around for normal US date formats
        #
        if ( $paramHash{dateFormat} =~ /sql/i || !$paramHash{dateFormat} ) {
            my ( $year, $month, $day ) = split( /\D/, $paramHash{fieldValue} );
            $paramHash{fieldValue} = $month . "-" . $day . "-" . $year;
        }

        #
        # convert from number format to normal dates so the picker will love it
        #
        if ( $paramHash{dateFormat} =~ /number/i ) {
            my $year       = substr( $paramHash{fieldValue}, 0, 4 );
            my $month      = substr( $paramHash{fieldValue}, 4, 2 );
            my $day        = substr( $paramHash{fieldValue}, 6, 2 );
            $paramHash{fieldValue} = $month . "-" . $day . "-" . $year;
        }
    }

    #
    # this is the js needed to copy the date field to the SQL compatable hidden field
    #

    my $copyToHidden = "\$('#" . $paramHash{uniqueId} . "_ajax').val(\$('#" . $paramHash{uniqueId} . "').val());";

    if ( $paramHash{fieldType} eq 'date' ) {
        $copyToHidden = "if (document.getElementById('" . $paramHash{uniqueId} . "\').value != '') {var dateSplit=document.getElementById('" . $paramHash{uniqueId} . "\').value.split(/\\D/);while(dateSplit[1].length &lt; 2) { dateSplit[1] = '0'+dateSplit[1];}while(dateSplit[0].length &lt; 2) { dateSplit[0] = '0'+dateSplit[0];}document.getElementById('" . $paramHash{uniqueId} . "_ajax').value=dateSplit[2]+'-'+dateSplit[0]+'-'+dateSplit[1];}else {document.getElementById('" . $paramHash{uniqueId} . "_ajax').value='';}";
    }

    if ( $paramHash{fieldType} eq 'dateTime' ) {
        $copyToHidden = "if (document.getElementById('" . $paramHash{uniqueId} . "\').value != '') {var dateSplit=document.getElementById('" . $paramHash{uniqueId} . "\').value.split(/\\D/);while(dateSplit[1].length &lt; 2) { dateSplit[1] = '0'+dateSplit[1];}while(dateSplit[0].length &lt; 2) { dateSplit[0] = '0'+dateSplit[0];}document.getElementById('" . $paramHash{uniqueId} . "_ajax').value=dateSplit[2]+'-'+dateSplit[0]+'-'+dateSplit[1]+' '+dateSplit[3]+':'+dateSplit[4]+':'+dateSplit[5];}else {document.getElementById('" . $paramHash{uniqueId} . "_ajax').value='';}";
    }

    #
    # set the style if we have to something to give
    #
    my $styleHTML;
    if ( $paramHash{style} ) { $styleHTML = " style=\"" . $paramHash{style} . "\"" }

    #
    # Seed the save JS, we will build on this depending on what we have to work with
    #
    my $AJAXSave;

    #
    # radio boxes have there own transfer method
    #
    if ( $paramHash{fieldType} ne "radio" && $paramHash{fieldType} ne 'date' ) {
        $AJAXSave .= $copyToHidden;
    }

    #
    # seed the onSaveJS, we will seed this also and depdningon what we are doing, we might
    # need to do different onSaveJS functions
    #
    my $onSaveJS;

    #
    # if your a text area, update the text
    #
    if ( $paramHash{updateType} && $paramHash{fieldType} eq "textArea" ) {
        $onSaveJS .= "\$('#" . $paramHash{uniqueId} . "_status').css('visibility', 'hidden');"
    }

    #
    # if your a password, update the text
    #
    if ( $paramHash{updateType} && $paramHash{fieldType} eq "password") {
        $onSaveJS .= "\$('#" . $paramHash{uniqueId} . "_passwordStrong').hide();"
    }

    #
    # everyone gets the spinny
    #
    my $imageID;
    if ( $paramHash{updateType} ) {
        $imageID = "'#" . $paramHash{uniqueId} . "_img'";
        $onSaveJS .= "\$(" . $imageID . ").attr('src','" . $self->{fileFWSPath} . "/saved.gif');";
        $AJAXSave .= "\$(" . $imageID . ").attr('src','" . $self->loadingImage() . "');";
    }

    #
    # after the save is complete run this javascript
    #
    if ( $paramHash{onSaveComplete} ) {
        $onSaveJS .= $paramHash{onSaveComplete};
    }

    #
    #  tack in the onSave it was populated
    #
    if ( $onSaveJS ) { $onSaveJS = ",onSuccess: function() {" . $onSaveJS . "}" }

    #
    # the save everyone uses
    #
    if ( $paramHash{updateType} ) {
        if ( $paramHash{updateType} eq "AJAXUpdate" || $paramHash{updateType} eq "AJAXExt" ) {
            $AJAXSave .= "\$('<div></div>').FWSAjax({queryString:'s=" . $self->{siteId} . "&p=fws_dataEdit&guid=" . $paramHash{ajaxUpdateGUID} . "&parent=" . $paramHash{ajaxUpdateParentId} . "&table=" . $paramHash{ajaxUpdateTable} . "&field=" . $paramHash{fieldName} . "&value='+encodeURIComponent(\$('#" . $paramHash{uniqueId} . "_ajax').val())+'&pageAction=" . $paramHash{updateType} . "'" . $onSaveJS . ",showLoading:false});";
        }
        else {
            #TODO Validate if this other updateType ajax is even being used anymore
            $AJAXSave .= "\$('<div></div>').FWSAjax({queryString:'s=" . $self->{siteId} . "&guid=" . $paramHash{ajaxUpdateGUID} . "&parent=" . $paramHash{ajaxUpdateParentId} . "&field=" . $paramHash{fieldName} . "&value='+encodeURIComponent(\$('#" . $paramHash{uniqueId} . "_ajax').val())+'&pageAction=" . $paramHash{updateType} . "&p=" . $paramHash{updateType} . "'" . $onSaveJS . ",showLoading:false});";
        }
    }

    #
    # if this is a date fields, lets wrap this in the conditional not to save unless its groovy
    #
    if ( $paramHash{fieldType} eq 'date' || $paramHash{fieldType} eq 'dateTime' ) {
        my $reformatJS;
        $reformatJS .= "if (\$('" . $paramHash{uniqueId} . "_ajax').val() != '') {";
        if ( $paramHash{dateFormat} =~ /number/i ) {
            $reformatJS .= "var cleanDate;cleanDate = document.getElementById('" . $paramHash{uniqueId} . "_ajax').value.replace(/\\D/g,'');";
            $reformatJS .= "\$('#" . $paramHash{uniqueId} . "_ajax').val(cleanDate);";
        }
        $reformatJS .= '}';

        $AJAXSave = $copyToHidden . "var dateSplit=document.getElementById('" . $paramHash{uniqueId} . '_ajax\').value.split(/\\D/);if (document.getElementById(\'' . $paramHash{uniqueId} . '_ajax\').value == \'\' || (dateSplit[0].length==4 &amp;&amp; dateSplit[1] &gt; 0 &amp;&amp; dateSplit[1] &lt; 13 &amp;&amp;  dateSplit[2] &gt; 0 &amp;&amp; dateSplit[2] &lt; 32 )) { '. $reformatJS . $AJAXSave . '}';
    }

    #
    # change all carrage returns to safe ones that are compatable with ajax calls
    # only beat up the value field if we are talking about a value that will be injected into an element.  otherwise leave it alone
    # because we might be passing some sweet stuff to it that will have raw html
    #
    if ( $paramHash{fieldType} ) {
        $paramHash{fieldValue} =~ s/\n/&#10;/sg;
        $paramHash{fieldValue} =~ s/\r//sg;
        $paramHash{fieldValue} =~ s/"/&quot;/sg;
    }

    #
    # lets starting building the actual fieldHTML we will return
    # EVERYONE gets the hidden ajax guid
    #
    my $fieldHTML = "<input type=\"hidden\" name=\"" . $paramHash{uniqueId} . "_ajax\" id=\"" . $paramHash{uniqueId} . "_ajax\"/>";

    #
    # textArea starter with hidden save message only if we are going to update it
    #
    if ( $paramHash{updateType} && $paramHash{fieldType} eq "textArea") {
        $fieldHTML .= "<div id=\"" . $paramHash{uniqueId} . "_status\" style=\"color:#FF0000;visibility:hidden;\">";
        $fieldHTML .= "<img alt=\"save\" src=\"" . $self->{fileFWSPath} . "/saved.gif\" style=\"border:0pt none;\" id=\"" . $paramHash{uniqueId} . "_img\" onclick=\"" . $AJAXSave . "\"/>";
        $fieldHTML .= "&nbsp;Your content has not been saved";
        $fieldHTML .= "</div>";
    }

    #
    # text/password
    #
    if ( $paramHash{fieldType} =~ /^(text|password)$/ ) {
        $fieldHTML .= "<input type=\"" . $paramHash{fieldType} . "\" name=\"" . $paramHash{fieldName} . "\"  size=\"60\"" . $styleHTML . "  class=\"FWSFieldText " . $paramHash{class} . "\" value=\"" . $paramHash{fieldValue} . "\"";
    }

    #
    # currency,date and number
    #
    if ( $paramHash{fieldType} eq 'date' ) {
        $self->jqueryEnable( 'ui-1.8.9' );
        $self->jqueryEnable( 'ui.datepicker-1.8.9' );
        $paramHash{class} .= ' FWSDatePicker';
    }

    #
    # color picker
    #
    if ( $paramHash{fieldType} eq 'color') {
        $paramHash{class} .= " FWSColorPicker";
    }

    #
    # datetime
    #
    if ( $paramHash{fieldType} eq 'dateTime') {
        $self->jqueryEnable( 'ui-1.8.9' );
        $self->jqueryEnable( 'ui.widget-1.8.9' );
        $self->jqueryEnable( 'ui.mouse-1.8.9' );
        $self->jqueryEnable( 'ui.datepicker-1.8.9' );
        $self->jqueryEnable( 'ui.slider-1.8.9' );
        $self->jqueryEnable( 'timepickr-0.9.6' );
        $paramHash{class} .= " FWSDateTime";
    }

    if ( $paramHash{fieldType} =~ /^(currency|number|date|color|dateTime)$/ ) {

        if ( $paramHash{fieldType} eq 'color' ) { $styleHTML = " style=\"background-color: #" . $paramHash{fieldValue} . "\""; }

        if ( $paramHash{fieldType} eq 'dateTime' ) {
           $fieldHTML .= "<input type=\"text\" name=\"" . $paramHash{fieldName} . "\"  size=\"20\"" . $styleHTML . " class=\"" . $paramHash{class} . "\" value=\"" . $paramHash{fieldValue} . "\"";
        }
        else {
           $fieldHTML .= "<input type=\"text\" name=\"" . $paramHash{fieldName} . "\"  size=\"10\"" . $styleHTML . "  class=\"" . $paramHash{class} . "\" value=\"" . $paramHash{fieldValue} . "\"";
        }

        #
        # only allow numbers and such
        #
        $paramHash{onKeyDown} .= "var keynum; if(window.event) { keynum = event.keyCode } else if(event.which) {";
        $paramHash{onKeyDown} .= "keynum = event.which };";
        $paramHash{onKeyDown} .= "if ((";
        $paramHash{onKeyDown} .= "keynum&lt;48 || keynum&gt;105 || (keynum&gt;57 &amp;&amp; keynum&lt;95)";
        $paramHash{onKeyDown} .= ")";

        #
        # if I'm a color let people pick a-f
        #
        if ( $paramHash{fieldType} eq 'color' ) {
            $paramHash{onKeyDown} .= " &amp;&amp; keynum != 65 &amp;&amp; keynum != 66 &amp;&amp; keynum != 67 &amp;&amp; keynum != 68 &amp;&amp; keynum != 69 &amp;&amp; keynum != 70 ";
        }
        else {
            #
            # keypad and number: -
            #
            $paramHash{onKeyDown} .= " &amp;&amp; keynum != 45 &amp;&amp; keynum != 109 ";

            #
            # keypad: .
            #
            $paramHash{onKeyDown} .= " &amp;&amp; keynum != 45 &amp;&amp; keynum != 110 ";
        }

        $paramHash{onKeyDown} .= " &amp;&amp; keynum!=46  &amp;&amp; keynum!=189 &amp;&amp; keynum!=37 &amp;&amp; keynum!= 39 &amp;&amp; keynum!= 35 &amp;&amp; keynum!= 36 &amp;&amp; keynum!=8 &amp;&amp; keynum!=9 &amp;&amp; keynum!=190) { return false }";

    }

    #
    # dropDown
    #
    if ( $paramHash{fieldType} eq "dropDown" ) {
        $fieldHTML .= "<select name=\"" . $paramHash{fieldName} . "\"" . $styleHTML . " class=\"" . $paramHash{class} . "\"";
    }

    if ( $paramHash{fieldType} eq "birthday" ) {

        #
        # onchange bday js
        #
        my $bdayOnchange = "if (!isNaN(\$('#" . $paramHash{uniqueId} . "_year').val()) && !isNaN(\$('#" . $paramHash{uniqueId} . "_day').val()) && !isNaN(\$('#" . $paramHash{uniqueId} . "_month').val())) { \$('#" . $paramHash{uniqueId} . "_ajax').val(\$('#" . $paramHash{uniqueId} . "_year').val()+'-'+\$('#" . $paramHash{uniqueId} . "_month').val()+'-'+\$('#" . $paramHash{uniqueId} . "_day').val());}";
        #
        # month
        #
        $fieldHTML .= '<select class="FWSInputField" id="' . $paramHash{uniqueId} . '_month" name="' . $paramHash{uniqueId} . '_month" onchange="' . $bdayOnchange . '">';
        $fieldHTML .= '<option>- Month -</option>';
        $fieldHTML .= '<option value="01">January</option>';
        $fieldHTML .= '<option value="02">February</option>';
        $fieldHTML .= '<option value="03">March</option>';
        $fieldHTML .= '<option value="04">April</option>';
        $fieldHTML .= '<option value="05">May</option>';
        $fieldHTML .= '<option value="06">June</option>';
        $fieldHTML .= '<option value="07">July</option>';
        $fieldHTML .= '<option value="08">August</option>';
        $fieldHTML .= '<option value="09">September</option>';
        $fieldHTML .= '<option value="10">October</option>';
        $fieldHTML .= '<option value="11">November</option>';
        $fieldHTML .= '<option value="12">December</option>';
        $fieldHTML .= '</select>';

        #
        # Day
        #
        $fieldHTML .= '<select class="FWSInputField" id="' . $paramHash{uniqueId} . '_day" name="' . $paramHash{uniqueId} . '_day" onchange="' . $bdayOnchange . '">';
        $fieldHTML .= '<option>- Day -</option>';
        for ( my $count = 1; $count <= 31; $count++ ) {
            my $lead = '0'; 
            if ( $count > 9 ) { $lead = '' }
            $fieldHTML .= '<option value="' . $lead . $count . '">' . $count . '</option>';
        }
        $fieldHTML .= '</select>';

        #
        # year
        #
        $fieldHTML .= '<select class="FWSInputField" id="' . $paramHash{uniqueId} . '_year" name="' . $paramHash{uniqueId} . '_year" onchange="' . $bdayOnchange . '">';
        $fieldHTML .= '<option>- Year -</option>';
        my $year = $self->formatDate( format => 'year' );
        for ( my $count = $year-4; $count > $year-110; $count-- ) { $fieldHTML .= '<option value="' . $count . '">' . $count . '</option>' }
        $fieldHTML .= '</select>';
    }

    #
    # textArea
    #
    if ( $paramHash{fieldType} eq "textArea" ) {
        $fieldHTML .= "<textarea rows=\"8\" cols=\"70\" name=\"" . $paramHash{fieldName} . "\"" . $styleHTML . " class=\"" . $paramHash{class} . "\"";
    }


    #
    # all but checkboxes and radio buttons
    #
    if ( $paramHash{fieldType} =~ /^(dateTime|color|currency|number|text|password|textArea|dropDown|date)$/ ) {
        #
        # set the Id
        #
        $fieldHTML .= " id=\"".$paramHash{uniqueId}."\"";
        if ( $paramHash{readOnly} ) { $fieldHTML .= " disabled=\"disabled\"" }
    }



    #
    # if its a date, flip it around also update the ajax because it wont't do it on the save
    #
    if ( $paramHash{fieldType} =~ /^(date|color|dateTime)$/ ) {
        $fieldHTML .= " onkeyup=\"".$copyToHidden."\"";
    }

    if ( $paramHash{updateType} && $paramHash{fieldType} eq 'password')  {
        $fieldHTML .= ' onkeyup="';
        if ( $paramHash{strongPassword} ) {
            $fieldHTML .= 'if (document.getElementById(\'' . $paramHash{uniqueId} . '\').value.search(/(?=^.{7,}$)(?=.*\\d)(?=.*[A-Z])(?=.*[a-z]).*$/) != -1) {';
            $fieldHTML .= "\$('#" . $paramHash{uniqueId} . "_passwordWeak').hide();";
        }
        $fieldHTML .= "\$('#" . $paramHash{uniqueId} . "_passwordStrong').show();";
        if ( $paramHash{strongPassword} ) {
            $fieldHTML .= " } else {\$('#" . $paramHash{uniqueId} . "_passwordWeak').show();\$('#" . $paramHash{uniqueId} . "_passwordStrong').hide();}";
        }
        $fieldHTML .= '"';
    }

    #
    # run all these if on fields, even if ajax is not on
    #
    if ( ( $paramHash{fieldType} =~ /^(dateTime|color|currency|number|text|password|textArea|date)$/ ) ) {
        $fieldHTML .= " onfocus=\"" . $copyToHidden . $paramHash{onFocus} ."\"";
    }
        
    #
    # key down & context right clicking ajax image update
    #
    if ( $paramHash{updateType} && ( $paramHash{fieldType} =~ /^(color|dateTime|currency|number|text|password|date|textArea)$/ ) )  {

        #
        # choose a different icon
        #
        my $saveIcon = $self->{fileFWSPath} . "/save.gif";
        if ( $paramHash{saveIcon} ) { $saveIcon = $self->{fileFWSPath} . '/icons/' . $paramHash{saveIcon} }

        $fieldHTML .= " onkeydown=\"document.getElementById('" . $paramHash{uniqueId} . "_img').src='" . $saveIcon . "';";

        if ( $paramHash{updateType} && $paramHash{fieldType} eq 'textArea' )  {
            $fieldHTML .= "\$('#" . $paramHash{uniqueId} . "_status').css('visibility', 'visible');";
        }
        $fieldHTML .= $paramHash{onKeyDown};
        $fieldHTML .= "\" ";
    }


    #
    # set the onchange/onblur for the diffrent types
    #

    #
    # text/password
    #
    if ( $paramHash{fieldType} =~ /^(color|currency|dateTime|number|text|date)$/ ) {
        $fieldHTML .= " onblur=\"" . $paramHash{onChange} . $AJAXSave . "\"";
    }

    #
    # dropDown
    #
    if ( $paramHash{fieldType} =~ /^(dropDown|date|color|dateTime)$/ )  {
        $fieldHTML .= " onchange=\"" . $paramHash{onChange} . $AJAXSave . "\"";
    }

    #
    # if we are a radio button list, all other stuff is out the window, and this is the only thing that happens
    #
    if ( $paramHash{fieldType} eq 'radio' ) {
        #
        # clean these up in case peole did some formatting in the box
        #
        $paramHash{fieldOptions} =~ s/\n//sg;
        my @optionSplit = split( /\|/, $paramHash{fieldOptions} );
        my $matchFound = 0;
        $fieldHTML .= "<div class=\"FWSRadioButtonGroup\">";
        while (@optionSplit) {
            my $optionValue = shift @optionSplit;
            my $optionName  = shift @optionSplit;
            $fieldHTML .= "<input type=\"radio\" name=\"" . $paramHash{fieldName} . "\"" . $styleHTML . " class=\"" . $paramHash{class} . "\"";
            $fieldHTML .= " onclick=\"" . $paramHash{onChange};
            $fieldHTML .= "\$('#" . $paramHash{uniqueId} . "_ajax').val('" . $optionValue . "');";
            $fieldHTML .= $AJAXSave;
            $fieldHTML .= '"';
            if ( $paramHash{readOnly} ) { $fieldHTML .= " disabled=\"disabled\"" }
            if ( $optionValue eq $paramHash{fieldValue} || ( $#optionSplit < 1 && !$matchFound ) ) {
                $matchFound = 1;
                $fieldHTML .= " checked=\"checked\"";
            }
            $fieldHTML .= "/> ";
            $fieldHTML .= "<span class=\"FWSRadioButtonTitle\">" . $optionName . " &nbsp; </span>";
        }
        $fieldHTML .= "</div>";
    }
    #
    #
    # if we are a dropDown, put the options in and close the select
    #
    if ( $paramHash{fieldType} eq 'dropDown' ) {
        $fieldHTML .= ">";
        #
        # clean these up in case peole did some formatting in the box
        #
        $paramHash{fieldOptions} =~ s/\n//sg;
        my @optionSplit = split( /\|/, $paramHash{fieldOptions} );
        while (@optionSplit) {
            my $optionValue = shift( @optionSplit );
            my $optionName  = shift( @optionSplit );
            $fieldHTML .= "<option value=\"" . $optionValue . "\"";
            if ( $optionValue eq $paramHash{fieldValue} ) { $fieldHTML .= " selected=\"selected\"" }
            $fieldHTML .= ">" . $optionName . "</option>";
        }
        $fieldHTML .= "</select>";
    }

    if ( !$paramHash{fieldType} ) {
        $fieldHTML .= "<div class=\"FWSNoFieldType\"" . $styleHTML . ">" . $paramHash{fieldValue} . "</div>";
    }

    #
    # html
    #
    if ( $paramHash{fieldType} eq 'html' ) {
        $self->{tinyMCEEnable} = 1; 
    }

    #
    # textArea
    #
    if ( $paramHash{fieldType} eq 'textArea' ) {
        $fieldHTML .= ">" . $paramHash{fieldValue} . "</textarea>";
    }

    #
    # if we are not an dropDown or textarea, just close the input box
    #
    if ( $paramHash{fieldType} =~ /^(color|currency|number|dateTime|text|password|date)$/ ) {
        $fieldHTML .= "/>";
    }

    #
    # add autocomplete code
    #
    if ( $paramHash{autocompleteSource} ) {
        $fieldHTML .= '<script>$("#' . $paramHash{uniqueId} . '" ).autocomplete({';
        $fieldHTML .= 'source: ' . $paramHash{autocompleteSource} . ',';
        $fieldHTML .= 'search: function(event, ui) {$("#' . $paramHash{uniqueId} . '_img").attr("src","' . $self->loadingImage() . '");' . $paramHash{autocompleteSearch}  . '},';
        $fieldHTML .= 'open: function(event, ui) {$("#' . $paramHash{uniqueId} . '_img").attr("src","' . $self->{fileWebPath} . '/fws/icons/blank_16.png");' . $paramHash{autocompleteOpen} . '},';
        $fieldHTML .= 'select: function(event, ui) {' . $paramHash{autocompleteSelect} . '}';
        $fieldHTML .= '})';

        if ( $paramHash{autocompletePostHTML} ) {
            $fieldHTML .= '.data("autocomplete")._renderItem = function(ul, item) { return $("<li></li>")';
            $fieldHTML .= '.data("item.autocomplete", item).append("<a>" + item.value + \' ' . $paramHash{autocompletePostHTML} . '</a>\').appendTo(ul); }';
        }
        $fieldHTML .= ';</script>';
    }


    if ( $paramHash{updateType} && $paramHash{fieldType} eq "password" ) {
        if ( $paramHash{strongPassword} ) {
            $fieldHTML .= "<div id=\"" . $paramHash{uniqueId} . "_passwordWeak\" style=\"color:#FF0000;display:none;\">";
            $fieldHTML .= "Passwords must be at least 6 characters and contain a number, an upper case character, a lower case character.";
            $fieldHTML .= "</div>";
        }
        $fieldHTML .= "<div id=\"" . $paramHash{uniqueId} . "_passwordStrong\" style=\"color:#FF0000;display:none;\">";
        $fieldHTML .= "<img alt=\"save\" src=\"" . $self->{fileFWSPath} . "/saved.gif\" style=\"border:0pt none;\" id=\"" . $paramHash{uniqueId} . "_img\" onclick=\"" . $AJAXSave . "\"/>";
        $fieldHTML .= " Click the disk icon to commit your change";
        $fieldHTML .= "</div>";
    }

    #
    # stick the image in for saving if we are an updating field
    #
    if ( ( $paramHash{updateType} && ( $paramHash{fieldType} =~ /^(color|currency|dateTime|number|text|password|dropDown|date|radio)$/ ) ) || $paramHash{autocompleteSource} ) {
        $fieldHTML .= "<img alt=\"save\" src=\"" . $self->{fileFWSPath} . "/saved.gif\" style=\"border:0pt none;\" id=\"" . $paramHash{uniqueId} . "_img\"";
        if ( $paramHash{noAutoSave} ) { $fieldHTML .= " onclick=\"" . $AJAXSave . "\"" }
        $fieldHTML .= "/>";
    }

    #
    # if we are a text area, lets place lang id if needed
    #
    if ( $paramHash{fieldType} =~ /^(text|textArea)$/ ) {
        my $langId = $paramHash{fieldName};
        if ( $langId =~ /_(\w\w)$/ && $langId !~ /_id/i ) { $fieldHTML .= "[" . $1 . "]" }
    }

    #
    # if there is a title, wrap it with the GNF Field table!
    #
    if ( $paramHash{title} ) {

        my $FWSFieldTitle;
        my $FWSFieldValueWrapper;
        my $FWSFieldContainer;
        my $FWSFieldValue;
        if ( $paramHash{inlineCSS} ) {
            $FWSFieldTitle          = " style=\"float:left;text-align:right;;color:#000000;width:25%;\"";
            $FWSFieldValueWrapper   = " style=\"float:left;width:70%;\"";
            $FWSFieldContainer      = " style=\"width:95%\"";
        }

        my $html = "<div class=\"FWSFieldContainer\">";
        $html .= "<div ".$FWSFieldTitle."class=\"FWSFieldTitle\">";
        if ( $paramHash{updateType} && $paramHash{fieldType} eq "textArea") { $html .= "<br/>" }
        $html .= $paramHash{title} . "</div>";

        #
        # add precursor
        #
        $html .= "<div class=\"FWSFieldPreCursor\" style=\"width:10px;text-align:right;float:left;\">";
        if ( $paramHash{fieldType} eq 'currency' ) { $html .= "\$" }
        else { $html .= "&nbsp;"}
        $html .= "</div>";



        $html .= "<div " . $FWSFieldValueWrapper . "class=\"FWSFieldValueWrapper\">";
        $html .= "<div " . $FWSFieldValue . "class=\"FWSFieldValue\">" . $fieldHTML . $paramHash{afterFieldHTML} . "</div>";

        if ( ( $paramHash{fieldType} =~ /^text$/ || $paramHash{fieldType} =~ /^textArea$/) && !$paramHash{unilingual} && $paramHash{fieldName} ne 'name' ) {
            my @langArray = $self->languageArray();

            #
            # eat the default
            #
            shift @langArray;
            while (@langArray) {
                my $langId = shift( @langArray );
                my %langHash = %origHash;
                $langHash{updateType} = 'AJAXExt';
                $langHash{uniqueId}   = $langHash{fieldName} . '_' . $langHash{guid} . '_' . $langId;
                delete $langHash{title};
                $langHash{fieldName}  = $langHash{fieldName}."_".$langId;
                $langHash{fieldValue} = $langHash{$langHash{fieldName}};
                $html .= $self->adminField(%langHash);
            }
        }

        if ( $paramHash{note} ) { $html .= "<div class=\"FWSFieldValueNote help-block\">" . $paramHash{note} . "</div>" }
        $html .= "</div>";

        $html .= "<div style=\"clear:both;\"></div>";
        $html .= "</div>";
        return $html;
    }

    return $fieldHTML;
}
    

=head2 systemInfo

Return the system info page accessed by clicking "System" from the admin menu.

=cut

sub systemInfo { 
    my ( $self ) = @_;
    my $coreVersion     = '-';
    my $adminInstalled  = 0;    
    my $systemInfo;
    my $errorReturn;

    #
    # if we are looking at systemInfo lets make sure we have a fws guid
    # this will make a new one if its not there for an install process
    #
    $self->fwsGUID();

    #
    # run directory checks
    #
    $errorReturn = "";
    $systemInfo .= "<b>File Directory Check:</b><br/>";
    $systemInfo .= "<ul>";
    $errorReturn .= $self->_systemInfoCheckDir( $self->{filePath} );
    $errorReturn .= $self->_systemInfoCheckDir( $self->{fileSecurePath} );
    
    #
    # show this, if the rest works
    #
    if ( !$errorReturn ) { $errorReturn .= $self->_systemInfoCheckDir( $self->{filePath} . "/fws") }
    if ( !$errorReturn ) { $errorReturn .= $self->_systemInfoCheckDir( $self->{filePath} . "/fws/jquery") }
    if ( !$errorReturn ) {
        $errorReturn = "<li>All directories are present with suitable permissions.</li>"; 
        $adminInstalled = 1;
    }

    $systemInfo .= $errorReturn . "</ul>";
        
    #
    # run Module Checks
    #
    $errorReturn = '';
    $systemInfo .= '<b>Perl Module Check:</b><br/>';
    $errorReturn .= $self->_checkIfModuleInstalled( 'Captcha::reCAPTCHA' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'MIME::Base64' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'CGI::Carp' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'File::Copy' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'File::Find' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'Time::Local' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'File::Path' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'Google::SAML::Response' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'LWP::UserAgent' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'Crypt::SSLeay' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'Crypt::Blowfish' );
    $errorReturn .= $self->_checkIfModuleInstalled( 'GD' );
    if ( !$errorReturn ) { $systemInfo .= '<ul><li>All required Perl Modules are present.</li></ul>' }    
    else { $systemInfo .= $errorReturn . '<br/>' }
    
    #
    # run go file checks
    #
    $errorReturn = '';
    $systemInfo .= '<b>Script compatibility Check:</b><br/>';
    $errorReturn .= $self->_checkScript();
    if ( !$errorReturn ) { $systemInfo .= '<ul><li>All script compatability checks passed.</li></ul>' }
    else { $systemInfo .= $errorReturn  }


    #
    # Database Checks
    #
    $systemInfo .= '<b>Database Table And Index Check:</b><br/>';
    $errorReturn = $self->updateDatabase();
    if ( !$errorReturn ) { $systemInfo .= '<ul><li>All tables and indexes are correct.</li></ul>' }    
    else {$systemInfo .= $errorReturn . '<br/>' }

    if ( $adminInstalled )  {
        $systemInfo .= "<input style=\"width:300px;\" type=\"button\" onclick=\"location.href='" . $self->{scriptName} . "?s=site';\" value=\"View Site\"/>";
    }
            
    return $systemInfo;
}


=head2 aceTextArea

Create an ace editor UI componate.

=cut

sub aceTextArea {
    my ( $self, %paramHash ) = @_;

    my $statusContainer = 'scriptChangedStatus';

    if ( $paramHash{statusContainer} ) { $statusContainer = $paramHash{statusContainer} }
    
    #
    # load the JS for for ace... but only ONCE!
    #    
    if ( !$self->{FWSAceJSLoaded} ) {
        $self->addToFoot(    
            "<script src=\"" . $self->{fileFWSPath}."/ace-1.1.01/ace.js\" type=\"text/javascript\" charset=\"utf-8\"></script>\n" .
            "<script src=\"" . $self->{fileFWSPath}."/ace-1.1.01/theme-" . $self->{aceTheme} . ".js\" type=\"text/javascript\" charset=\"utf-8\"></script>\n" .
            "<script src=\"" . $self->{fileFWSPath}."/ace-1.1.01/mode-javascript.js\" type=\"text/javascript\" charset=\"utf-8\"></script>\n" .
            "<script src=\"" . $self->{fileFWSPath}."/ace-1.1.01/mode-html.js\" type=\"text/javascript\" charset=\"utf-8\"></script>\n" .
            "<script src=\"" . $self->{fileFWSPath}."/ace-1.1.01/mode-perl.js\" type=\"text/javascript\" charset=\"utf-8\"></script>\n" .
            "<script src=\"" . $self->{fileFWSPath}."/ace-1.1.01/mode-css.js\" type=\"text/javascript\" charset=\"utf-8\"></script>\n"
        );
        $self->{FWSAceJSLoaded}++;
    }


    #
    # set the modes if we have them
    #
    my $modeScript;
    if ( $paramHash{mode} eq 'html' ) {
        $modeScript = "var HTMLScriptMode = require(\"ace/mode/html\").Mode;" . $paramHash{name} . ".getSession().setMode(new HTMLScriptMode());";
    }
    if ( $paramHash{mode} eq 'javascript' ) {
        $modeScript = "var JSScriptMode = require(\"ace/mode/javascript\").Mode;" . $paramHash{name} .".getSession().setMode(new JSScriptMode());";
    }
    if ( $paramHash{mode} eq 'perl' ) {
        $modeScript = "var HTMLScriptMode = require(\"ace/mode/perl\").Mode;" . $paramHash{name} . ".getSession().setMode(new HTMLScriptMode());";
    }
    if ( $paramHash{mode} eq 'css' ) {
        $modeScript = "var CSSScriptMode = require(\"ace/mode/css\").Mode;" . $paramHash{name} . ".getSession().setMode(new CSSScriptMode());";
    }

    $self->addToFoot( "<script type=\"text/javascript\">" .
                    "\$(document).ready(function() {" .
                    "window." . $paramHash{name} . " = ace.edit(\"" . $paramHash{name} . "\");" .
                    $paramHash{name} . ".setTheme(\"ace/theme/" . $self->{aceTheme} . "\");" .
                    $paramHash{name} . ".getSession().setUseWrapMode(true);" .
                    $paramHash{name} . ".setShowPrintMargin(false);" . $modeScript .
                    $paramHash{name} . ".getSession().on('change', function () {document.getElementById('" . $statusContainer . "').innerHTML='[Not Saved]';});" .
                    "});" .
                    "</script>\n");

    #
    # clean up thing that need to be escaped for ace
    #
    $paramHash{value} =~ s/&/&amp;/sg;
    $paramHash{value} =~ s/\</&lt;/sg;

    #
    # create the line that will actually be rendered to the screen
    #
    return "<pre style=\"position: absolute; padding: 0; right: 0; bottom: 0; left: 0;display:none;\" id=\"" . $paramHash{name} . "\" class=\"FWSScriptEditContainer ui-widget ui-state-default ui-corner-bottom\">" . $paramHash{value} . "</pre>";
}


=head2 onOffLight

Return an on off lightbulb.

=cut 

sub onOffLight {
    my ( $self, $status, $guid, $style ) = @_;
    return $self->activeToggleIcon( guid => $guid, style => $style, active => $status );
}


=head2 editBox

Return a edit box for the passed element hash;

=cut

sub editBox {    
    my ( $self, %editHash ) = @_;

    my $editHTML;
    #my $ajaxID = '#editModeAJAX_' . $self->formValue( 'FWS_elementId' );
    my $ajaxID = '#editModeAJAX_' . $editHash{guid};

    #
    # default always show to off if its not passed
    #
    $editHash{alwaysShow} ||= 0;

    #
    # default color
    #
    $editHash{editBoxColor} ||= '#008000;';

    #
    # Define things to blank that might not be passed that we will
    # use
    #
    $editHash{siteGUID} ||= '';
    $editHash{name}     ||= '';
    $editHash{type}     ||= '';

    #
    # if we are in edit mode, make buttons and container
    # 
    if ( ( $self->formValue( 'editMode' ) || $editHash{alwaysShow} ) ) {

         if ( $self->{siteGUID} eq $editHash{siteGUID} || !$editHash{siteGUID} ||  $editHash{alwaysShow} ) { 
    
            #
            # Edit Bar Open Div Container
            #
            if ( !$editHash{editBoxJustButtons} ) {
                my $bgColor     = $self->_getHighlightColor( $editHash{editBoxColor} );
                my $divStyle    = "color:" . $editHash{editBoxColor} . ";background-color:".$bgColor.";border:dotted 1px " . $editHash{editBoxColor} . ";border-bottom:dotted 1px " . $editHash{editBoxColor} . ";text-align:right;";
    
                $editHTML .=  "<div style=\"" . $editHash{AJAXDivStyle} . "\" id=\"editModeAJAX_" . $editHash{guid} . "\">";
                $editHTML .=  "<div style=\"" . $divStyle . "\" class=\"FWSEditBoxControls\">";
                $editHTML .=  $editHash{name} . " ";
            }
            #
            # check to see if this could have children
            #
            my $showOrderButton = 0;
            my %elementHash = $self->_fullElementHash( typeAlso => 1 );
            for my $type ( keys %elementHash ) {
                if ( defined $elementHash{$type}{parent} ) {
                    if ( defined $editHash{type} ) {
                         if ( $elementHash{$type}{parent} eq $editHash{type} ) {  $showOrderButton = 1 }
                    }
                    if ( defined $elementHash{$editHash{type}}{guid} ) {
                        if ( $elementHash{$type}{parent} eq $elementHash{$editHash{type}}{guid} ) { $showOrderButton = 1 }
                    }
                } 
            }
    
            my $layoutFlag;
            my $pageFlag;
    
            #
            # if this is a column header edit box it will not have a type, which means we have to pass layout
            #
            if ( !$editHash{type} ) { $layoutFlag = "&layout=" . $editHash{layout} }
        
            if ( $editHash{pageOnly} ) { 
                $showOrderButton    = 1; 
                $pageFlag           = '&pageOnly=1';
                $layoutFlag         = '&layout=' . $editHash{layout};
            }
    
            if ( ( $showOrderButton || $editHash{orderTool} ) && !$editHash{disableOrderTool} ) {
                $editHTML .= $self->FWSIcon(    
                                icon        => "add_reorder_16.png",
                                onClick     => $self->dialogWindow(queryString=>"p=fws_dataOrdering&guid=" . $editHash{guid} . $pageFlag . $layoutFlag),
                                alt         => "Add And Ordering",
                                width       => "16");
            }
        
            #
            # Check to see if we should put the delete trash can icon
            #
            if ( ( $editHash{deleteTool} || ( $self->{siteGUID} eq $editHash{guid_xref_site_guid} ) || $editHash{forceDelete} ) && !$editHash{disableDeleteTool} ) {
        
                #
                # set up som vars for the post,  we want to do this differntly if we are talking about
                # a base element, or a sub element
                #
                #my $baseClear = "\$('#delete_" . $editHash{guid} . "').parent().parent().parent().parent().parent().hide();";
        
                #
                # If the parent isn't a page, that means we are talking about a sub element of an element.
                # we need to make sure the ajaxID is the parent of this element and then refresh the element in place.
                #
                # if it is a sub elemenet of an element, we also need to disable the "display none" it dosn't look goofy
                #
                #if ( $self->formValue( "FWS_pageId" ) eq $editHash{parent} && !$self->formValue( "FWS_editModeUpdate" ) ) { 
                #    $ajaxID = '<div></div>';
                #}
                #else { $baseClear = "" }
        
                $editHTML .= $self->FWSIcon(
                    icon    => "delete_16.png",
                    onClick => "\$('" . $ajaxID . "').FWSDeleteElement({pageGUID: '" . $self->formValue( 'FWS_elementId' ) . "',parentGUID: '" . $editHash{parent} . "', guid: '" . $editHash{guid} . "'});", 
                    alt     => "Delete",
                    width   => "16",
                    id      => "delete_" . $editHash{guid},
                );
            }
    
            #
            # add and order Tool Button
            #
            if ( !$editHash{disableEditTool} && $editHash{type} ne 'page') {
                $editHTML .= $self->FWSIcon(     
                    icon    => "properties_16.png",
                    onClick => $self->dialogWindow( queryString => "p=fws_dataEdit&guid=" . $editHash{guid} . "&parentId=" . $editHash{parent} ),
                    alt     => "Edit",
                    width   => "16",
                );
            }
        
            #
            # ON/OFF cotnrol
            #
            if ( !$editHash{disableActiveTool} && $editHash{guid} ne $self->homeGUID() ) { $editHTML .= $self->onOffLight( $editHash{active}, $editHash{guid} ) }
        
            #
            # close the edit bar container
            #    
            if ( !$editHash{editBoxJustButtons} ) { $editHTML .= '</div>' }
    
            $editHTML .= $editHash{editBoxContent};   
            $editHTML .= $editHash{editBox};
        
            #
            # close the delete ajax container
            #    
            if ( !$editHash{editBoxJustButtons} ) { $editHTML .= '</div>' }
        }
    }

    #
    # edit mode is not on, just show the content and call this good
    #
    else { $editHTML .= $editHash{editBoxContent} . $editHash{editBox} }
    return $editHTML;
}    
    
 
=head2 FWSMenu

Return the FWS top menu bar.

=cut

sub FWSMenu {
    my ( $self, %paramHash ) = @_;

    #
    # because we have a menu, it might need tiny mce
    #
    $self->{tinyMCEEnable} = 1;
            
    my $linkSpacer = " &nbsp;&middot;&nbsp; ";
    my $FWSMenu;
    

    #
    # create a correct label for fws/devel link to know what we have access too
    #
    if ( $self->userValue( 'isAdmin' ) || $self->userValue( 'showDeveloper' ) )  {
        $FWSMenu .= $self->popupWindow( queryString => "p=fws_systemInfo", linkHTML => "System" );
        $FWSMenu .= $linkSpacer;
    }

    #
    # get the FWSMenu taged elements and add them to the list
    #
    my @elementArray    = $self->elementArray( tags => 'FWSMenu' );
    @elementArray       = $self->sortDataByNumber( 'ord', @elementArray );
    for my $i (0 .. $#elementArray) {

        #
        # blank out the adminGroup if we have access so we can pass by the security check
        #
        map { if ( $self->userValue( $_ ) eq 1 ) { $elementArray[$i]{adminGroup} = '' } } split( /,/, $elementArray[$i]{adminGroup} );

        #
        # if we have access or we are super user show it
        #
        if ( !$elementArray[$i]{adminGroup} || $self->userValue( 'isAdmin' ) ) {
    
            #
            # convert to our friendly name format
            #
            ( my $fwsLink = $elementArray[$i]{type} ) =~ s/^FWS/fws_/sg;
    
            #
            # if this is not a friendly type version menu item then use the guid
            #
            $fwsLink ||= 'fws_' . $elementArray[$i]{guid};

            my $queryString = "FWS_pageId=" . $paramHash{pageId} . "&p=" . $fwsLink . "&FWS_showElementOnly=";
            if ( $elementArray[$i]{rootElement} ) { $FWSMenu .= $self->popupWindow( queryString => $queryString . "0", linkHTML => $elementArray[$i]{title} ) }
            else { $FWSMenu .= $self->dialogWindow( queryString => $queryString . "1", linkHTML => $elementArray[$i]{title} ) }
            $FWSMenu .= $linkSpacer;
        }
    }

    if ( $self->formValue( "p" ) =~ /^fws_/ ) {
        $FWSMenu .= $self->_selfWindow( "", "View Site" );
        $FWSMenu .= $linkSpacer;
    }
    
    #    
    # ALWAYS ON
    #
    if ( $self->userValue( 'isAdmin' ) || $self->userValue( 'showDesign' ) || $self->userValue( 'showContent' ) || $self->userValue( 'showDeveloper' ) )  {
        $FWSMenu .= $self->_editModeLink( '', $linkSpacer );
    }

    $FWSMenu .= $self->_logOutLink();
    
    if ( $self->userValue( 'isAdmin' ) || $self->userValue( 'showDesign' ) || $self->userValue( 'showContent' ) || $self->userValue( 'showDeveloper' ) )  {

        #
        # just in case we havn't installed FWS core yet, lets make sure the image is there before we 
        # try to display it.
        #
        if ( -e $self->{filePath} . '/fws/icons/add_reorder_16.png' ) {
            $FWSMenu .= $linkSpacer;
            $FWSMenu .= $self->FWSIcon( 
                icon    => 'add_reorder_16.png',
                onClick => $self->dialogWindow( queryString => 'p=fws_dataOrdering&guid=' . $paramHash{pageId} . '&pageOnly=1' ),
                alt     => 'Add And Ordering',
                width   => '16',
            );
        }
    }

    $FWSMenu .= $linkSpacer;

    return $FWSMenu;
}


=head2 panel

FWS panel HTML:  Pass title, content and panelStyle keys.

=cut

sub panel {
    my ( $self, %paramHash ) = @_;
    
    my $panel;

    if ( $paramHash{inline} ) {
        $panel .= "<div style=\"width:95%;font-size:12px;margin-top:10px;padding-bottom:10px;margin-bottom:10px;border: 1px solid #d3d3d3; padding:10px;background: #ffffff; -moz-border-radius: 4px; -webkit-border-radius: 4px; border-radius: 4px; font-weight: normal; color: #555555;" . $paramHash{panelStyle} . "\" class=\"FWSPanel ui-widget ui-widget-content ui-corner-all\">";
        $panel .= "<div style=\"padding:5px 15px 15px 15px;font-weight:800;font-size:14px;color:#2B6FB6;\" class=\"FWSPanelTitle\">" . $paramHash{title} . "</div>";
        $panel .= "<div steyl=\" padding:5px 15px 15px 15px;font-size:12px;\" class=\"FWSPanelContent\">" . $paramHash{content} . "</div>";
        $panel .= "</div>";
    }
    else {
        $panel .= "<div ";
        if ( defined $paramHash{panelStyle} ) { $panel .= "style=\"" . $paramHash{panelStyle} . "\" " }
        $panel .= "class=\"FWSPanel ui-widget ui-widget-content ui-corner-all\">";
        $panel .= "<div class=\"FWSPanelTitle\">" . $paramHash{title} . "</div>";
        $panel .= "<div class=\"FWSPanelContent\">" . $paramHash{content} . "</div>";
        $panel .= "</div>";
    }
    return $panel;
}


=head2 displayAdminPage

Run the lookup and display admin pages wrapped in security precautions.

=cut

sub displayAdminPage {
    my ( $self ) = @_;

    #
    # mimic the normal element processing controls
    #
    my $pageHTML; 
    my $showElementOnly = 0;
    my $quitPageProcessing = 0;
    my $pageId = $self->safeSQL( $self->formValue( 'p' ) );
        
    if ( $self->isAdminLoggedIn() ) {
        $self->jqueryEnable( 'simplemodal-1.4.4' );
        $self->jqueryEnable( 'ui.core-1.8.9' );
        $self->jqueryEnable( 'ui.widget-1.8.9' );
        $self->jqueryEnable( 'ui.tabs-1.8.9' );
        $self->jqueryEnable( 'ui.fws-1.8.9' );
        $self->jqueryEnable( 'fileupload-ui-4.4.1' );
        $self->jqueryEnable( 'fileupload-4.5.1' );
        $self->jqueryEnable( 'fileupload-uix-4.6' );

        #
        # see if we looking at a dynamicly created admin page
        #
        if ( $pageId =~ /^fws_/ ) { 
            my %elementHash = $self->_fullElementHash();
            for my $guid ( sort { $elementHash{$a}{alphaOrd} <=> $elementHash{$b}{alphaOrd} } keys %elementHash ) {

                #
                # trim up what these actually look like to match naming
                #
                ( my $fwsElementType = $pageId ) =~ s/fws_//sg;
                $fwsElementType = 'FWS' . ucfirst( $fwsElementType );

                if ( $self->{_fullElementHashCache}->{$guid}{type} eq $fwsElementType || "fws_" . $guid eq $pageId ) {
                
                    my %elementHash = $self->elementHash( guid => $guid );
    
                    #
                    # blank out the adminGroup if we have access so we can pass by the security check
                    #
                    map { if ( $self->userValue( $_ ) eq 1 ) { $elementHash{adminGroup} = '' } } split( /,/, $elementHash{adminGroup} );
            
                    #
                    # if we have access or we are super user show it
                    #
                    if ( !$elementHash{adminGroup} || $self->userValue( 'isAdmin' ) ) {
                       
                        my %valueHash;
                        $valueHash{pageId}          = $pageId;
                        $valueHash{elementId}       = $guid;
                        $valueHash{elementWebPath}  = $self->fileWebPath() . "/" . $elementHash{siteGUID} . "/" . $valueHash{elementId};
    
                        my $fws = $self;
    
                        ## no critic
                        eval $elementHash{scriptDevel};
                        ## use critic
                        my $errorCode = $@;
                        if ( $errorCode ) {
                            $valueHash{html} .= "<div style=\"border:solid 1px;font-weight:bold;\">FrameWork Element Error:</div><div style=\"font-style:italic;\">".$errorCode."</div>";
                        }
    
                        #
                        # now put it back
                        #
                        $self = $fws;
   
                        #
                        # set head and foot from cache so we can use it for our admin page
                        #
                        $self->{tinyMCEEnable} = 1;
                        $self->{bootstrapEnable} = 1;
                        $self->setPageCache();
    
                        #
                        # just in case we havn't rendered yet, here we go!  if we have already rendered  (like we should have
                        # than this just gets passed by
                        #
                        #$self->printPage( content => $valueHash{html} . $fws->{ 'pageFoot' } , head => $self->FWSHead() );
                    #    $self->printPage( content => $valueHash{html} . $fws->{ 'pageFoot' } , head => $self->{pageHead} );
                        $self->printPage( content => $valueHash{html}, head => $self->FWSHead(), foot => $self->siteValue( 'pageFoot' )  );
                    }
                }
            }
        }

            
        #
        # this one does not run in an element, because it installs the elements!
        #
        if ( $pageId eq 'fws_systemInfo' ) {
                
            my $coreElement;
            if ( !$self->{hideFWSCoreUpgrade} ) {
                $coreElement .= "<br/><input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('This could take several moments after you click ok.";
                $coreElement .= " Do you want to continue?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=installCore';}\" value=\"Install Full Core Element &amp;&nbsp;File Package\"/> ";
                $coreElement .= ' Use for new installs or if your having FWS related javascript errors.';
                $coreElement .= "<div class=\"FWSStatusNote\">".$self->formValue("coreStatusNote")."</div>";
            }



            my $log = "<input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('Are you sure you clear the FWS log file?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=clearFWSLog';}\" value=\"Clear FWS Log\"/> ";
            my $FWSLogSize = -s $self->{fileSecurePath} . '/FWS.log';
            $log .=  'FWS.Log ' . sprintf( "%0.1f", $FWSLogSize/1000 ). 'K size <a target="_blank" href="' . $self->{scriptName} . $self->{queryHead} . 'p=fws_log&lines=50">View</a>';
            $log .= "<div class=\"FWSStatusNote\">".$self->formValue("logStatusNote")."</div>";


            my %sessionInfo = $self->_sessionInfo();
            my $sess = "<input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('Are you sure you delete all sessions?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=flushSessions&months=0';}\" value=\"Delete All Sessions\"/> ";
            $sess .= $sessionInfo{total}." sessions total<br/>"; 
            $sess .= "<input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('Are you sure you delete sessions more than 1 month old?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=flushSessions&months=1';}\" value=\"Delete All Sessions More Than 1 Month Old\"/> ";
            $sess .= $sessionInfo{1}." sessions over 30 days old<br/>";
            $sess .= "<input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('Are you sure you delete sessions more than 3 months old?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=flushSessions&months=3';}\" value=\"Delete All Sessions More Than 3 Months Old\"/> ";
            $sess .= $sessionInfo{3}." sessions over 90 days old";
            $sess .= "<div class=\"FWSStatusNote\">".$self->formValue("sessionStatusNote")."</div>";

            my $backup;
            $backup = "Backup file name:<br/>";
            $backup .= "<input style=\"width:150px;\" type=\"text\" name=\"backupName\" id=\"backupName\" />";
            $backup .= "<input style=\"width:150px;\" type=\"button\" onclick=\"if(confirm('This could take several minutes depending on the size of your data.";
            $backup .= " Do you want to continue?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . " p=fws_systemInfo&excludeSiteFiles='+document.getElementById('excludeSiteFiles').checked+'&backupName='+escape(document.getElementById('backupName').value)+'&pageAction=FWSBackup';}\" value=\"Backup Now\"/> ";
            $backup .= ' This will make a backup of your FWS Site files,&nbsp;plugins,&nbsp;and database';
            $backup .= "<div class=\"FWSExcludeBackup\"><input type=\"checkbox\" name=\"excludeSiteFiles\" id=\"excludeSiteFiles\" /> Do not backup web accessible site uploaded files</div>";
            $backup .= "<div class=\"FWSStatusNote\">".$self->formValue("backupStatusNote")."</div>";

            $backup .= "Restore file name:<br/>";
            $backup .= "<input style=\"width:150px;\" type=\"text\" name=\"restoreName\" id=\"restoreName\" />";
            $backup .= "<input style=\"width:150px;\" type=\"button\" onclick=\"if(confirm('WARNING!!!  This will ovewrite your database and files.";
            $backup .= " Do you want to continue?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&restoreName='+escape(document.getElementById('restoreName').value)+'&pageAction=FWSRestore';}\" value=\"Restore Now\"/> ";
            $backup .= ' Overwrite your database,&nbsp;files,&nbsp;and plugins with a backup';
            $backup .= "<div class=\"FWSStatusNote\">".$self->formValue("restoreStatusNote")."</div>";

            my $publish = "<input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('Are you sure you flush your search cache? (Depending on the size of your site this could take several minutes)')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=flushSearchCache';}\" value=\"Rebuild Search Cache\"/>";
            $publish .= " Replace all search cache, and update parent page references. (This will be slow on large sites)<br/>";
            $publish .= "<input style=\"width:300px;\" type=\"button\" onclick=\"if(confirm('Are you sure you flush your web cache?')) {location.href='" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo&pageAction=flushWebCache';}\" value=\"Flush Web Cache\"/>";
            $publish .= " Remove all combined js and css files, and recreate them as needed.";
            $publish .= "<div class=\"FWSStatusNote\">" . $self->formValue("statusNote") . "</div>";

            #
            # DB Pakckages
            #
            my $dbPackages;
            $dbPackages .= "<table border=\"1\" cellspacing=\"0\" style=\"margin-left:40px;width:90%;".$self->fontCSS()."\">";
            $dbPackages .= "<tr>";
            $dbPackages .= "<th>Module or Element Name</th>";
            $dbPackages .= "<th>Your Version</th>";
            $dbPackages .= "<th>Current Version</th>";
            $dbPackages .= "<th>&nbsp;</th>";
            $dbPackages .= "</tr>";
            $dbPackages .= $self->_packageLine( "US Zip Code Package", ( $self->_versionData( 'local', 'zipcode' ) )[0],( $self->_versionData( 'live', 'zipcode' ) )[0], "fws_installZipcode" );
            $dbPackages .= $self->_packageLine( "Country Package", ( $self->_versionData( 'local', 'country' ) )[0], ( $self->_versionData( 'live', 'country' ) )[0], "fws_installCountry" );
            $dbPackages .= "</table>";


            $pageHTML .= "<div style=\"width:90%;margin:auto;padding:10px;text-align:right;color:#ff0000;\">FrameWork&nbsp;Sites&nbsp;Version&nbsp; " . $self->{FWSVersion} . "</div>";
            $pageHTML .= $self->panel( title => "FWS Installation And Health"      ,content => $self->systemInfo() . $coreElement );
            $pageHTML .= $self->panel( title => "Session Maintenance"              ,content => $sess);
            $pageHTML .= $self->panel( title => "Log Files"                        ,content => $log);
            $pageHTML .= $self->panel( title => "FWS Site Backups"                 ,content => $backup);
            $pageHTML .= $self->panel( title => "Flush Cache Engines"              ,content => $publish);
            $pageHTML .= $self->panel( title => "Core Database Packages"           ,content => $dbPackages);
            $self->siteValue("pageHead","");
            $self->siteValue("pageKeywords","");
            $self->siteValue("pageDescription","");

            $self->printPage( title => "FrameWork&nbsp;Sites&nbsp;Version&nbsp; " . $self->{FWSVersion} . " System Info", content => $pageHTML, head=> $self->_minCSS() );
        }

        #
        # do install subroutines
        #
        if ( $pageId eq 'fws_installCountry' ) { $pageHTML .= $self->_installCountry() }
        if ( $pageId eq 'fws_installZipcode' ) { $pageHTML .= $self->_installZipcode() }

    }

    #
    # Show the admin login if we didn't meet isAdminLoggedIn
    #
    else { $self->displayAdminLogin() }

    return;
}


=head2 GNFTree

Tree render componate.  At some point this will be rewritten using a JQuery tree and migrate away from this server side rendering method.

=cut

sub GNFTree {
    my ( $self, %paramHash ) = @_;

    #
    # parentId is implied usually via formValue parentId, but if your passing it, lets use that one
    #
    $paramHash{parentId} ||= $self->formValue( 'parentId' );

    #
    # if this is not in a modal pass noModal
    #
    $paramHash{noModal} ||= 0;

    #
    # remove any reference to id_ - this is legacy
    #
    $paramHash{id} =~ s/^id_//sg;    

    #
    # create the depth lines,  if there is a line map use this way if there is a depth use the other
    #
    my $lineHTML;
    if ( $paramHash{lineMap} ne '' ) { $lineHTML = $self->_createLineMap( %paramHash ) }

    #
    # create the depth lines,  if there is a line map use this way if there is a depth use the other
    #
    if ( $paramHash{depth} > 0 ) { 

        # Add the lines for how deep it is
        #
        for (my $count = 0; $count < ( $paramHash{depth} -1 ); $count++ ) {
            $lineHTML .= "<img class=\"FWSTreeEventRowImage\" alt=\"\" src=\"" . $self->{fileFWSPath} . "/line.gif\"/>";
        }

        if ( $paramHash{expandQuery} ) { 
            if ( $paramHash{lastInList} ) {
                $lineHTML .= "<img class=\"FWSTreeEventRowImage\" src=\"" . $self->{fileFWSPath} . "/plus.gif\" id=\"tree" . $paramHash{id} . "\"/>";
            }
            else {
                $lineHTML .= "<img class=\"FWSTreeEventRowImage\" src=\"" . $self->{fileFWSPath} . "/plusbottom.gif\" id=\"tree" . $paramHash{id} . "\"/>";
            }
        }
        else {
            $lineHTML .= "<a href=\"#\" name=\"parentAnchor" . $paramHash{categoryId} . "\"></a>";
            if ( $paramHash{lastInList} ) {
                $lineHTML .= "<img class=\"FWSTreeEventRowImage\" src=\"" . $self->{fileFWSPath} . "/join.gif\" id=\"tree" . $paramHash{id} . "\"/>";
            }
            else {
                $lineHTML .= "<img class=\"FWSTreeEventRowImage\" src=\"" . $self->{fileFWSPath} . "/joinbottom.gif\" id=\"tree" . $paramHash{id} . "\"/>";
            }
        }
    }


    #
    # create the table the line item will sit in
    #
    my $treeHTML = "<div id=\"block_" . $paramHash{id} . "\">";
    $treeHTML .= "<div class=\"FWSTreeEventRow " . $paramHash{class} . "\" onmouseover=\"this.className='FWSTreeEventRow " . $paramHash{class} . " FWSTreeEventRowHighlight';\" onmouseout=\"this.className='FWSTreeEventRow';\" id=\"row_" . $paramHash{id} . "\">";
    
    #my $treeHTML .= "<div class=\"FWSTreeEventRow " . $paramHash{class} . "\" onmouseover=\"this.className='FWSTreeEventRowHighlight';\" onmouseout=\"this.className='FWSTreeEventRow';\" id=\"block_" . $paramHash{id} . "\">";

    #
    # add the + - thing
    #
    $treeHTML .= "<span class=\"FWSTreeLeft\"";
    if ( $paramHash{expandQuery} ) { 
        $treeHTML .= " style=\"cursor:pointer;\" ";
        $treeHTML .= "onclick=\"GNFTreeUpdate('" . $paramHash{id} . "','" . $self->{scriptName} . "','" . $self->{queryHead} . $paramHash{expandQuery} . "',0,0," . ( $paramHash{lastInList} + 0 ) . "," . $paramHash{noModal} . ");return false;\"";
    }
    $treeHTML .= ">";

    #
    # do the line art to the left of the content title of the line
    #    
    $treeHTML .= $lineHTML;

    #
    # add the icon
    #
    my $checkedOutClass;
    if ( $paramHash{icon} =~ /lock/i ) { $checkedOutClass = "checkedOutTip "; }
    
    $treeHTML .= "<img class=\"" . $checkedOutClass . "FWSTreeEventRowImage\" alt=\"\" src=\"" . $self->{fileFWSPath} . "/" . $paramHash{icon} . "\"/>";
             
    $treeHTML .= '<div class="FWSTreeLineTitle">';
    $treeHTML .= "&nbsp;" . $paramHash{name};
    $treeHTML .= "</div>";

    $treeHTML .= "</span>";

    #
    # if this is an add line do a add td sequence, and close table
    #
    if ( $paramHash{addField1} || $paramHash{addCustom1} ) {
        #
        # if there is a hidden field toss it in
        #
        if ( $paramHash{addHiddenField1} ) {
            $treeHTML .= "<input value=\"" . $paramHash{addHiddenFieldValue1} . "\" type=\"hidden\" id=\"add_" . $paramHash{addHiddenField1}  . "_" . $paramHash{parentId} . "\" name=\"add_" . $paramHash{addHiddenField1} . "_" . $paramHash{parentId} . "\"/>";
        }

        #
        # add up to 10 fields if needed
        #
        
        for ( my $i = 1; $i < 10; $i++ ) {
            if ( $paramHash{'addField' . $i} || $paramHash{'addCustom' . $i} ) {
                $treeHTML .= "<div class=\"FWSTreeAddField\">" . $paramHash{'addLabel' . $i}  . "<br/>";

                #
                # set the default addType to text
                #
                $paramHash{'addType' . $i} ||= 'text';

                if ( defined $paramHash{'addCustom' . $i} ) { $treeHTML .= $paramHash{'addCustom' . $i} }
                else {
                    $treeHTML .= "<input value=\"" . $self->formValue( $paramHash{'addField' . $i} ) . "\" type=\"" . $paramHash{'addType' . $i} . "\" style=\"" . $paramHash{'addFieldStyle' . $i} . "\" id=\"add_" . $paramHash{'addField' . $i}  . "_" . $paramHash{parentId} . "\" name=\"" . $paramHash{'addField' . $i}  . "_".$paramHash{parentId} . "\"/>";
                }
                $treeHTML .= "</div>";
            }
        }
       
    
        #
        # set the addPageAction field
        #
        my $addPageField = 'pageAction';
        if ( $paramHash{addPageField} ) { $addPageField = $paramHash{addPageField} }

        #
        # add the "go" button
        #
        $treeHTML .= "<div class=\"FWSTreeAddField\"><br/>";
        my $onClickGo;
        if ( $paramHash{addHiddenField1} ) {
            $onClickGo .= "&" . $paramHash{addHiddenField1} . "='+escape(document.getElementById('add_" . $paramHash{addHiddenField1} . '_' . $paramHash{parentId} . "').value)+'";
        }
        for ( my $i = 1; $i < 10; $i++ ) {
            if ( $paramHash{'addField' . $i} ) {
                $onClickGo .= "&" . $paramHash{'addField' . $i} . "='+escape(document.getElementById('add_" . $paramHash{'addField' . $i} . '_' . $paramHash{parentId} . "').value)+'";
            }
        }
        if ( $onClickGo ) {
            $treeHTML .= " " . $self->FWSIcon( icon    =>"go_16.png",
                             onClick => "this.src='" . $self->loadingImage() . "';\$('#cat" . $paramHash{parentId} . "').FWSAjax({queryString: '" . $self->{queryHead} . "&guid=" . $self->formValue("id") . "&id=" . $self->formValue("id") . "&parentId=" . $paramHash{parentId} . "&p=" . $self->formValue("p") . "&".$addPageField . "=" . $paramHash{'addPageAction'} . "&depth=" . $self->formValue("depth") . $onClickGo . "',showLoading:false});return false;",
                             alt     =>"go",
                             width   =>"16",
                             style   =>"padding-left:3px;vertical-align:middle;");

            }
        $treeHTML .= "</div>";
    }


    #
    # make an easy access to see if it has labels
    #
    my $hasLabel = 0;
    if ( $paramHash{label1} || $paramHash{label2} || $paramHash{label3} || $paramHash{label4} || $paramHash{label5} || $paramHash{label6} || $paramHash{label7} || $paramHash{label8} || $paramHash{label9} || $paramHash{label10} || $paramHash{label11} || $paramHash{label12} || $paramHash{label13} || $paramHash{label14} || $paramHash{label15} || $paramHash{label16} ) { $hasLabel = 1 } 

    #
    # this isn't an "add line" finish out the standard tree
    #
    if ( $paramHash{searchOnClick} || $paramHash{actionHTML} || $hasLabel) {
        if ( $paramHash{searchOnClick} || $hasLabel ) {
            $treeHTML .= "<div class=\"FWSTreeSearch\">";
            $treeHTML .= $self->FWSIcon( 
                icon    => "go_16.png",
                onClick => $paramHash{onClick1} . $paramHash{searchOnClick},
                id      => "sel_" . $paramHash{id} . "_" . $paramHash{parentId},
                alt     => "go",
                width   => "16",
                style   => "padding-left:3px;vertical-align:middle;"
            );
            $treeHTML .= "</div>";    
        }
        
        $treeHTML .= "<div class=\"FWSTreeSearch\">";
        if ( $paramHash{actionHTML} ) { $treeHTML .= $paramHash{actionHTML} }

        if ( $hasLabel ) {
            $treeHTML .= "<select style=\"width:180px;\" onchange=\"";

            for ( my $i = 1; $i < 17; $i++ ) {
                if ( $paramHash{'onClick' . $i} ) {$treeHTML .= "if (this.value == $i) {document.getElementById('sel_" . $paramHash{id} . "_" . $paramHash{parentId} . "').onclick=function() {" . $paramHash{'onClick' . $i} . "return false;}}" }
             }
            $treeHTML .= "\">";
    
            for ( my $i = 1; $i < 17; $i++ ) { if ( $paramHash{'label' . $i} ) {$treeHTML.="<option value=\"" . $i . "\">" . $paramHash{'label' . $i}."</option>"} }
            $treeHTML.= "</select>";
        }
        if ( $paramHash{searchOnClick} ) {
            $treeHTML .= "<input style=\"width:175px;\" type=\"text\" id=\"" . $paramHash{searchField} . "\" name=\"" . $paramHash{searchField} . "\"/>";
        }
        $treeHTML .= "</div>";    
        
    }
    else {
        #
        # we don"t have a dropdown slector, use the tool set view
        # Page View Tool
        #

        $treeHTML .= "<div class=\"FWSActionButton\">";
        if ( $paramHash{viewTool} ) {
            my $editURL = $self->{scriptName} . $self->{queryHead};
            $editURL .= "&editMode=1";
            $editURL .= "&p=" . $paramHash{id};
            $treeHTML .= "<img alt=\"Open Page\" onclick=\"location.href='" . $editURL . "';\" title=\"" . $paramHash{id} . "\" style=\"cursor:pointer;display:inline;border:0pt none;\" src=\"" . $self->{fileFWSPath} . "/icons/go_16.png\"/>";
            }
        else { $treeHTML .= "&nbsp;" };
        $treeHTML .= "</div>";
            
        #
        # The Delete Tool
        #
        $treeHTML .= "<div class=\"FWSActionButton\">";
        if ( $paramHash{deleteTool} ) {
            $treeHTML .= $self->FWSIcon(     
                icon    => "delete_16.png",
                onClick => "if (confirm('Are you sure you want to delete this item and all of its related sub items? (Non-reversable)'" .
                           ")){FWSAjax('" . $self->{scriptName} . "','" . $self->{queryHead} . 
                           "p=fws_dataEdit&pageAction=deleteElement&parent=" . $paramHash{parentId} . 
                           "&guid=" . $paramHash{id} . "');" . 
                           "\$('#block_" . $paramHash{id} . "').hide('slow');}return false;",
                alt     => "Delete",
                width   => "16",
            );
        }
        elsif ( $paramHash{emailDeleteTool} ) {
            $treeHTML .= $self->FWSIcon(    
                icon    =>"delete_16.png",
                onClick => "if (confirm('Are you sure you want to delete this message? (Non-reversable)'" . 
                           ")){FWSAjax('" . $self->{scriptName} . "','" . $self->{queryHead} .
                           "&pageAction=deleteMessage" .
                           "&guid=" . $paramHash{id} . "');" . 
                           "\$('#block_" . $paramHash{id} . "').hide('slow');}return false;",
                alt     => "Delete",
                width   => "16",
            );
        }
        else { $treeHTML .= "&nbsp;" };
        $treeHTML .= "</div>";

            
        #
        # 3dit tool
        #
        $treeHTML .= "<div class=\"FWSActionButton\">";
        if ( $paramHash{emailEditTool} ) {
            $treeHTML .= $self->FWSIcon(    
                icon    => "properties_16.png",
                onClick => $self->dialogWindow( queryString => "p=fws_messageEdit&guid=" . $paramHash{id} ),
                alt     => "Edit",
                width   => "16",
            );
        }    
        if ( $paramHash{pageTool} ) {
            $treeHTML .= $self->FWSIcon(
                icon    => "properties_16.png",
                onClick => $self->popupWindow( queryString => "p=fws_pageEdit&FWS_pageId=" . $paramHash{guid} . "&FWS_showElementOnly=0" ),
                alt     => "Edit",
                width   => "16",
                id      => "edit_".$paramHash{id}, 
            );
        }    
        else { 
            $treeHTML .= "&nbsp;" 
        }
        
        $treeHTML .= "</div>";

        #
        # on off tool
        #
        $treeHTML .= "<div class=\"FWSActionButton\">";
        if ( $paramHash{activeTool} ) { 
            $treeHTML .= $self->onOffLight( $paramHash{active}, $paramHash{guid} );
        } 
        else { 
            $treeHTML .= "&nbsp;";
        }
        
        $treeHTML .= "</div>";
            
        #
        # template Tool
        # 
        if ( $paramHash{templateTool} ) {
            if ( !$self->formValue( "templateList" ) ) {

                $self->formValue( "templateList", "0|Default Template|" );

                #
                # get the array of all the templates availalbe
                #
                my @templateArray = $self->templateArray();

                #
                # loop through them and create a pipe delimited list
                #
                for my $i (0 .. $#templateArray) {
                    $self->formValue( "templateList", $self->formValue( "templateList" ) . $templateArray[$i]{guid} . "|" . $templateArray[$i]{title} . "|" );
                }
            }

            $treeHTML .= "<div style=\"float:right;\">" . $self->adminField(
                fieldType           => 'dropDown',
                fieldValue          => $paramHash{layout},
                style               => 'width:200px;',
                fieldName           => 'layout',
                fieldOptions        => $self->formValue( 'templateList' ),
                updateType          => 'AJAXUpdate',
                ajaxUpdateTable     => 'guid_xref',
                ajaxUpdateParentId  => $paramHash{parentId},
                ajaxUpdateGUID      => $paramHash{guid}
            );

            $treeHTML .= "</div>"; 
            $treeHTML .= "<div style=\"float:right;\">";
            if ( !$paramHash{id} ) { 
                $treeHTML .= "Home Page ";
            }
            $treeHTML .= "Template:";
            $treeHTML .= "</div>";
                  
        }    
    }
    $treeHTML .= "<div style=\"float:right;\" class=\"FWSTreeSearch\">";
    $treeHTML .= $paramHash{searchLabel};
    $treeHTML .= '</div>';


    if ( $paramHash{dateRange} ) {

        $paramHash{fromLabel} ||= 'From: ';

        my $fromId  = $paramHash{dateRange} . "From";
        my $toId    = $paramHash{dateRange} . "To";
        $treeHTML  .= "<div style=\"float:right;margin-right:10px;\" class=\"FWSDateRange\">" . $paramHash{fromLabel};

        #
        # set some smart starts and ends
        #
        my $fromDate    = $self->formatDate( format => 'SQL', monthMod => -1 );
        my $toDate      = $self->formatDate( format => 'SQL' );
        if ( $paramHash{dateRange} eq 'onlyLate' ) { 
            $fromDate     = '0000-00-00';
        }
        if ( $paramHash{dateRange} eq 'check' ) { 
            $toDate     = $self->formatDate( format => 'SQL', monthMod => 1 );
            $fromDate   = $self->formatDate( format => 'SQL' );
        }
            
        $treeHTML .= $self->adminField(
            fieldType     => 'date',
            fieldValue    => $fromDate,
            fieldName     => $fromId,
            id            => $fromId,
            style         => 'width:70px;',
        );

        $treeHTML .= "&nbsp;To: ";

        $treeHTML .= $self->adminField(
            fieldType     => 'date',
            fieldValue    => $toDate,
            fieldName     => $toId,
            id            => $toId,
            style         => 'width:70px;',
        );
        $treeHTML .= "</div>";
    
    }

    #
    # close the the DIV send a clear and return the html
    #
    $treeHTML .= "</div>";
    $treeHTML .= "<div style=\"clear:both;\"></div>";
    return $treeHTML . "<div style=\"\" id=\"cat" . $paramHash{id} . "\"></div></div>";
}

sub _selfWindow {
    my ( $self, $queryString, $linkHTML, $extraJava ) = @_;
    return "<span style=\"cursor:pointer;\" class=\"FWSAjaxLink\" onclick=\"location.href='" . $self->{scriptName} . $self->{queryHead} . $queryString . "';" . $extraJava . "\">" . $linkHTML . "</span>";
}

sub _isSiteUsed {
    my ( $self, $fieldValue ) = @_;
    my ( $siteUsed ) = @{$self->runSQL( SQL => "select 1 from site where site.sid='" . $self->safeSQL( $fieldValue ) . "'" )};
    if ( $siteUsed ) { return 1 }
    return 0;
}

sub _isValidSID {
    my ( $self, $siteValid ) = @_;
    my $returnStatus;
    if ( $siteValid =~ /[^a-z]/ ) {
        $returnStatus .= "The Site ID must only contain lower case characters without any spaces or symbols. ";
    }
    if ( length( $siteValid ) < 4 && $siteValid ne 'fws' ) {       
        $returnStatus .= "The Site ID must be at least 4 characters long. ";
    }
    if ( length( $siteValid ) > 8 ) {      
        $returnStatus .= "The Site ID must be 8 characters or less. ";
    }
    if ( $self->_isSiteUsed( $siteValid ) && $siteValid &&  $siteValid ne 'fws' ) {
        $returnStatus .= "The Site ID has already been taken. ";
    }
    return $returnStatus;
}

sub _processAdminAction {
    my ( $self ) = @_;

    my $guid   = $self->safeSQL( $self->formValue( 'guid' ) );

    #
    # To prevent recursive saves we have to update elements insdie the core
    #
    if ($self->userValue( 'isAdmin') || $self->userValue('showDeveloper')) {
        if ( $self->formValue( 'pageAction' )  eq 'updateScript' ) {
            my %valueHash;
            my $fws = $self;
            ## no critic
            eval $self->formValue( 'script' );
            ## use critic
            if ( $@ ) { $self->formValue( 'statusNote', '<textarea style="width:800px;height:67px;font-size:10px;">'.$@.'</textarea><br/>' ) }
            else {
                my $script = $self->safeSQL( $self->formValue( "script" ) );
                my $schema = $self->safeSQL( $self->formValue( "schema" ) );
                my $checkedOut = $self->safeSQL($self->formValue("checkout"));
                $self->runSQL(SQL=>"update element set schema_devel='".$schema."',  script_devel='".$script."', checkedout='".$checkedOut."' where guid='" . $self->safeSQL( $self->formValue( 'guid' ) )  . "'");
                $self->_saveElementFile( $self->formValue( 'guid' ), $self->formValue('site_guid'), 'element', 'css', $self->formValue("css") );
                $self->_saveElementFile( $self->formValue( 'guid' ), $self->formValue('site_guid'), 'element', 'js', $self->formValue("javaScript") );
                $self->formValue( 'statusNote', '' );
            }
        }
        
        if ( $self->formValue( 'pageAction' ) eq "FWSRestore") {
            $self->restoreFWS( id => $self->formValue( 'restoreName' ) );
            $self->formValue( 'restoreStatusNote', 'Restore completed' );
        }

    
    }
    if ($self->userValue( 'isAdmin') || $self->userValue('showDeveloper') || $self->userValue('showDesigner') ) {
        
        if ( $self->formValue( 'pageAction' ) eq "installCore") {
        
            #
            # We only want the end part of the package for the file name
            #
            my $distFile     = 'V2.pm';
            my $newV2File    = $self->{fileSecurePath} . "/FWS/" . $distFile;
        
            #
            # get the stuff ready for the backup copy info
            #
            require File::Copy;
            File::Copy->import();
            my $currentTime = $self->formatDate( format => 'number' );
        
            $self->FWSLog("Backing up FWS core: " . $newV2File . " - Backup File Is Now: " . $newV2File . "." . $currentTime);
            copy( $newV2File, $newV2File . "." . $currentTime );

            my ( $updateString, $majorVer, $minorVer, $build ) = $self->_versionData( 'live', 'core', 'fws_installCore' );

            #
            # set the base URL for where the dist files are pulled from
            #
            my $imageBaseURL = $self->{FWSServer} . '/fws_' . $majorVer;

            #
            # get the core Script
            #
            if ( $self->_pullDistFile( $imageBaseURL . '/current_frameworksitescom.pm', $self->{fileSecurePath} . '/FWS', $distFile, "package FWS::V2;\n" ) ) {
                
                #
                # import the new core admin
                #
                $self->_importAdmin( 'current_core' );
                $self->FWSLog( 'FWS core element packages updated' );
                $self->formValue( 'coreStatusNote', 'Current FWS Core element and file packages has been updated' );
               
                #
                # flg our sucess swo we can save versionData
                # 
                $self->_versionData( 'live', 'core', 'fws_installCore', 1 );

                #
                # add the fwsdemo files if they are not there already
                #
                my $demoFile =  $self->{fileSecurePath} . '/backups/fwsdemo';
                if ( !-e $demoFile . '.sql' ) {
                    $self->_pullDistFile( $imageBaseURL . '/fwsdemo.sql', $self->{fileSecurePath} . '/backups', 'fwsdemo.sql', '' );
                }
                if ( !-e $demoFile . '.files' ) {
                    $self->_pullDistFile( $imageBaseURL . '/fwsdemo.files', $self->{fileSecurePath} . '/backups', 'fwsdemo.files', '' );
                }
               
                #
                # delete cache directory
                #
                $self->flushWebCache();

                #
                # get rid of any orphaned data from the install process
                #
                $self->_deleteOrphanedData( "data", 'guid', "guid_xref", "child");

                #
                # if there is no elements on the site yet lets install our demo site
                #
                if ( !@{$self->runSQL( SQL => "select 1 from data where site_guid not like 'f%' and guid not like 'h%'" )} ) {
                    $self->restoreFWS( id => 'fwsdemo' );
                    print "Status: 302 Found\n";
                    print "Location: " .  $self->{scriptName} . "\n\n";

                }
            }
        }


        if ( $self->formValue( 'pageAction' ) eq "FWSBackup") {

            my $backupID = $self->backupFWS( 
                excludeSiteFiles    => ( $self->formValue('excludeSiteFiles') eq 'true' ) ? 1 : 0,
                id                  => $self->formValue('backupName'),
                excludeTables       => 'zipcode,country,cart,geo_block,' . $self->{FWSBackupExcludeTables}, 
            );

            $self->formValue('backupStatusNote','Backup completed using backup name '.$backupID);
        }

        if ( $self->formValue( 'pageAction' ) eq "clearFWSLog") {
            unlink $self->{fileSecurePath} . '/FWS.log';
            $self->formValue("logStatusNote", "The FWS.log file was cleared");
        }

        if ( $self->formValue( 'pageAction' ) eq "flushSessions") {
            if ( $self->formValue( 'months' ) ne '' ) { 
                $self->runSQL( SQL => "delete from fws_sessions where created < '" . $self->formatDate( format => 'SQL', monthMod => -( $self->formValue( 'months' ) ) ) . "'");
                if ( $self->DBType() =~ /^mysql$/i ) { $self->runSQL( SQL => "optimize table fws_sessions" ) }
                $self->formValue( "sessionStatusNote", "Your sessions table was optimized" );
            }
        }

        if ( $self->formValue( 'pageAction' ) eq "flushSearchCache") { 
            my ( $dataUnits ) = $self->flushSearchCache( $self->{siteGUID} ) ;
            $self->formValue( "statusNote", "Your search cache was rebuilt using a total of " . $dataUnits . " records.");
        }
    
        if ( $self->formValue( 'pageAction' ) eq "flushWebCache") { 
            $self->flushWebCache();
            $self->formValue( "statusNote", "Your web search cache was emptied" );
        }
    
    }        

    return;    
}

sub _pullDistFile {
    my ( $self, $imageURL, $directory, $distFile, $preContent ) = @_;

    require LWP::UserAgent;
    my $browser = LWP::UserAgent->new();
    my $response = $browser->get( $imageURL );
    if (!$response->is_success ) {
        $self->FWSLog( "FWS server connection error: " . $response->status_line );
        $self->formValue( 'coreStatusNote', "A network error in connecting to FWS Server:" . $response->status_line );
        return 0;
    }

    #
    # we got it! lets save it
    #
    $self->makeDir( $directory );
    open ( my $FILE, ">", $directory . '/' . $distFile );
    print $FILE $preContent . $response->content;
    close $FILE;
        
    $self->FWSLog( "FWS secure distributed file saved: " . $directory . '/' . $distFile );
    return 1;
}

sub _addTemplate {
    my ( $self, $siteGUID, $title, $templateDevel, $cssDevel, $jsDevel, $default_template ) = @_;
    #
    # switch the title to sql frienldy, and then insert the data
    # switch the css, and java on the fly, because we don't want it changed before we save it to
    # a file
    #
    $title = $self->safeSQL( $title );
    my $guid = $self->createGUID( 't' );
	
	#
	# set defaults
	#
	$default_template ||= 0;
	
    $self->runSQL( SQL => "insert into templates (guid,site_guid,title,template_devel,default_template) values ('" . $guid . "','" . $self->safeSQL($siteGUID) . "','" . $title . "','" . $self->safeSQL($templateDevel) . "','" . $self->safeSQL($default_template) . "')" );

    #
    # create the files if we need to
    #
    if ( $jsDevel ) { 
        $self->_saveElementFile( $guid, $siteGUID, 'template', 'js', $jsDevel );
    }
    if ( $cssDevel ) { 
        $self->_saveElementFile( $guid, $siteGUID, 'template', 'css', $cssDevel );
    }
    return $guid;
}

sub _getHighlightColor {
    my ( $self, $inColor, $percent ) = @_;
    $percent ||= 90;
    $percent = $percent / 100;
    $inColor =~ s/[^0-9a-fA-F]//sg;
    my @colorArray = split( //, $inColor );
    my $RC = hex( $colorArray[0] . $colorArray[1] );
    my $GC = hex( $colorArray[2] . $colorArray[3] );
    my $BC = hex( $colorArray[4] . $colorArray[5] );
    $RC = sprintf( "%x", int( ( 255 - $RC ) * $percent) + $RC );
    $GC = sprintf( "%x", int( ( 255 - $GC ) * $percent) + $GC );
    $BC = sprintf( "%x", int( ( 255 - $BC ) * $percent) + $BC );
    return "#" . $RC . $GC . $BC;
}

#
# easy reuse optoin sub for the fws_data_edit
#
sub _createOptionGroup {
    my ( $self, $optLabel, $ordMin, $ordMax, %elementHash ) = @_;

    #
    # for elements in there twice because they are present via the guid, and the elementType lets hold a hash so we don't dup them
    #
    my %elementDisplayed; 
    my $optionFullHTML = "<optgroup label=\"" . $optLabel . "\">";
    for my $guid ( sort { $elementHash{$a}{alphaOrd} <=> $elementHash{$b}{alphaOrd} } keys %elementHash) {
        if ( !$elementDisplayed{$elementHash{$guid}{guid}} && ( !$elementHash{$guid}{parent} || $elementHash{$guid}{rootElement} ) && $elementHash{$guid}{ord} > $ordMin && $elementHash{$guid}{ord} <= $ordMax ) {
            $optionFullHTML .= "<option value=\"" . $guid . "\">" . $elementHash{$guid}{title} . "</option>";
            
            #
            # set the flag that we have seen this one aready,  we don't need two of them!
            #
            $elementDisplayed{$elementHash{$guid}{guid}} = 1;
        }
    }
    $optionFullHTML .= "</optgroup>";
    return $optionFullHTML;
}

        
sub _createLineMap {
    my ( $self, %paramHash ) = @_;
    my $lineHTML;
    #
    # Split up the map into an array and set the default icon
    #
    my @lineMap = split(//,$paramHash{lineMap});

    while (@lineMap) {
        my $idHTML;
        my $icon        = "blank.gif";
        my $lineChar    = shift(@lineMap);

        #
        # set the default icons
        #
        if ( $lineChar eq '|' ) { $icon = 'line.gif' }
        if ( $lineChar eq '+' ) { $icon = 'joinbottom.gif' }
        if ( $lineChar eq 'L' ) { $icon = 'join.gif'; $paramHash{lastInList} = 1 }

        #
        # if there is an expand use these icons, and set the anchor wrapper
        #
        if ( $paramHash{expandQuery} ) {
            if ($lineChar eq '+') { $icon = 'plusbottom.gif' }
            if ($lineChar eq 'L') { $icon = 'plus.gif'}
            if ($lineChar eq 'L' || $lineChar eq '+') { 
                $idHTML = "id=\"tree" . $paramHash{id} . "\"";
            }
        }
        $lineHTML .= "<img class=\"FWSTreeEventRowImage\" alt=\"\" src=\"" . $self->{fileFWSPath} . "/" . $icon . "\" " . $idHTML . "/>";
    }
    return $lineHTML
}

sub _editModeLink {
    my ( $self, $conName, $linkSpacer ) = @_;
    my $hideConCSSJS = "\$('#" . $conName . "').hide('slow');";
    if ( $self->formValue( "p" ) !~ /^fws_/) {
    return $self->_selfWindow( "editMode=" . ( $self->formValue( 'editMode' ) ? 0 : 1 ) . "&p=" . $self->formValue( "p" ) . "&id=" . $self->formValue( "id" ), ( $self->formValue( 'editMode' ) ? 'Live' : 'Edit' ) . "&nbsp;Mode", $hideConCSSJS ) . $linkSpacer;
    }
}

sub _logOutLink {
    my ( $self, $conName ) = @_;
    my $hideConCSSJS = "\$('#" . $conName . "').hide('slow');";
    return $self->_selfWindow( "pageAction=adminLogOut&p=0", "Log&nbsp;Out", $hideConCSSJS );
}

sub _packageLine {
    my ( $self, $name, $currentVer, $newVer, $script ) = @_; 
    my $line    = "<tr>";
    my $upText  = "Upgrade";

    if ( !$currentVer ) {           $currentVer = "Not Installed"; $upText = "Install" }
    if ( $currentVer eq $newVer ) { $upText = "Re-Install" }
    $line .= "<td>" . $name . "</td>";

    $line .= "<td style=\"text-align:center;width:200px;\">" . $currentVer . "</td>";
    $line .= "<td style=\"text-align:center;width:200px;\">" . $newVer . "</td>";  
    $line .= "<td style=\"text-align:center;width:100px;\"><a href=\"" . $self->{scriptName} . $self->{queryHead} . "p=" . $script . "\">" . $upText . "</a>"; 
    $line .= "</tr>";
    return $line;
}


sub _checkScript {
    my ( $self, $moduleName ) = @_;
    my $errorReturn;

    if ( !$self->{FWSScriptCheck}->{registerPlugins} ) { $errorReturn .= '<li>Your script file is missing $fws->registerPlugins(); this should be added.</li>' }

    if ( $errorReturn ) { $errorReturn = '<ul>' . $errorReturn . '</ul>' }
    return $errorReturn;
}



sub _checkIfModuleInstalled {
    my ( $self, $moduleName ) = @_;
    my $errorReturn;

    ## no critic
    eval "use " . $moduleName;
    ## use critic

    if ( $@ ) { 
        my $bump;
        if ($moduleName eq "Google::SAML::Response") {  $bump = $moduleName . " is used for Single Sign On Google Apps integration.  If your not using this website for Google SSO then you will not need this." }
        if ($moduleName eq "Crypt::SSLeay") {           $bump = $moduleName . " is used for secure transactions to payment gateways.  If your not using eCommerce real time payment gateways this module may not be necessary." }
        if ($moduleName eq "Captcha::reCAPTCHA") {      $bump = $moduleName . " is used for captcha support.  If you are not using captchas for human form postings validation then this is not required." }
        if ($moduleName eq "Crypt::Blowfish") {         $bump = $moduleName . " is used to encrypt tranasactional data.  If your not using eCommerce real time payment gateways this module may not be necessary." }
        $errorReturn .= "<ul><li>" . $moduleName . " Perl module missing.  Your site may not run correctly without it. " . $bump . "<br/><br/><ul><li>To install it if you have shell access you can do the following:<br/>server prompt> cpan<br/>CPAN> install " . $moduleName . "<br/><i>Note: You must be logged in as root to use cpan, if you are unfamiliar with using cpan it might be best to have a system adminstrator do this for you.</i></li><li>To install it from CPanel do the following:<br/>Perl Modules -> Install a Perl Module: " . $moduleName . "</li><li>If these methods are unavailable you may need your server administrator to install it for you.</li></ul></li></ul><br/>" }

    return $errorReturn;
}

sub _systemInfoCheckDir {
    my ( $self, $newDir ) = @_;

    my $errorReturn;
    my $documentRoot     = $ENV{DOCUMENT_ROOT};
    my $scriptFilename   = $ENV{SCRIPT_FILENAME};

    if ( !-e $newDir ) {
        if ( $newDir =~ /\/fws/ ) {
            if ( !$self->{hideFWSCoreUpgrade} ) {
                $errorReturn .= "Your core element and file package is not installed yet.<br/>";
                $errorReturn .= '<a href="' . $self->{scriptName} . '?p=fws_systemInfo&pageAction=installCore">Click here to install your core element and file package</a><br/>';
                $errorReturn .= '<i>Depending on your connection speed and server performance, your page may take a few minutes to load after clicking the link below.</i>';
            }
        }
        else {
            $errorReturn .= "<ul><li>The directory '" . $newDir . "' does not exist";
            $self->makeDir( $newDir );
            if ( !-e $newDir ) {
                $errorReturn .= ". The webserver does not have permissions to create this directory.<br/>Create this directory by hand, and make it web server writable.  <ul><li>Sometimes large ISP might have complex directories.  Usually it will match in part with one of these, but not always:<br/>Document Root: " . $documentRoot . "<br/>Script Root Path: " . $scriptFilename . "</li><li>You can change your file permissions from your server console using: chmod 755 " . $newDir . "<br/>This can also be done though web based server administration programs or even FTP if your security settings will allow it.</li></ul>";
            }
            else {
                $errorReturn .= ',&nbsp;but was created automaticly.</br> <a href="' . $self->{scriptName} . '?p=fws_systemInfo">Click here to continue system health check</a>';
            }
        }
        $errorReturn .= "</li></ul><br/>";
    }
    else {
        if ( !$self->_testDirWritePermission( $newDir ) ) {
            $errorReturn .= "<ul><li>The directory '" . $newDir . "' is not web server writable.<br/>";
            $errorReturn .= "<ul><li>Usually this means changing your file permissions for this directly using: chmod 755 " . $newDir . "</li><li>chmod style permissions can also be done though web based server administration programs or even FTP if your security settings will allow it.</li><li>Some configurations my require an administrator to change the ownership of this directory to the webserver by using: chown nobody:nobody " . $newDir . " ('nobody:nobody' is a default web server user and group, it could be 'www:www' or something different)</li></ul>";
        $errorReturn .= "</li></ul><br/>";
        }
    }
    return $errorReturn;
}

sub _testDirWritePermission {
    my ( $self, $testFile ) = @_;
    $testFile .= "/testfile.tmp";
    open ( my $FILE, ">", $testFile );
    print $FILE "TEST FILE";
    close $FILE;
    if ( -e $testFile ) { 
        unlink $testFile;
        return 1;
    }
    return 0;
}

sub _sessionInfo {
    my ( $self, %paramHash ) = @_;
    my %returnHash;
    ( $returnHash{total} ) =  @{$self->runSQL( SQL => "select count(1) from fws_sessions" )};
    ( $returnHash{1} ) =      @{$self->runSQL( SQL => "select count(1) from fws_sessions where created < '" . $self->formatDate( format => 'SQL', monthMod=>-1 ) . "'" )};
    ( $returnHash{3} ) =      @{$self->runSQL( SQL => "select count(1) from fws_sessions where created < '" . $self->formatDate( format => 'SQL', monthMod=>-3 ) . "'" )};
    return %returnHash;
}


sub _importAdmin {
    my ($self,$adminFile) = @_;
    my $removeCore = 0;
    my $keepAlive = 500;
    if ( $adminFile eq 'current_core' ) { 
        $removeCore = 1;
        $keepAlive  = 0;
    }
    return $self->importSiteImage( 
        newSID      => "fws",
        imageURL    => "http://www.frameworksites.com/downloads/fws_" . $self->{FWSVersion} . "/" . $adminFile . ".fws",
        removeCore  => $removeCore,
        parentSID   => "admin",
        keepAlive   => $keepAlive,
    );
}


sub _installZipcode {
    my ( $self ) = @_;

    #
    # make stdout hot! and start sending to browser
    #
    local $| = 1;
    print $self->_installHeader( 'Zipcode' );

    $self->runSQL(SQL=>"delete from zipcode");  

    print "<br/>Downloading and Installing";
    
    my $importReturn = $self->_importAdmin( 'current_zipcode' );
    
    print "<br/>" . $importReturn;

    print $self->_installFooter( 'Zipcode' );
    
    if ( $importReturn !~ /error/i ) { $self->_versionData( 'live', 'zipcode', "fws_installZipcode", 1 ) }
       
    $self->{stopProcessing} = 1;

    return;
}
    
sub _installCountry {
    my ( $self ) = @_;
    
    #
    # make stdout hot! and start sending to browser
    #
    local $| = 1;
    print $self->_installHeader( 'Country' );
    
    $self->runSQL( 'delete from country' );
    
    print "<br/>Downloading and Installing";

    my $importReturn = $self->_importAdmin( 'current_country' );
    
    print $self->_installFooter( 'Country' );
    
    if ( $importReturn !~ /error/i ) { $self->_versionData( 'live', 'country', "fws_installCountry", 1 ) }
    
    $self->{stopProcessing} = 1;

    return;
}

sub _installHeader {
    my ( $self, $name ) = @_;
    return "Content-Type: text/html; charset=UTF-8\n\n<html><head><title>Installing New " . $name . " Package</title>" . 
    "</head>".
    "<body><h2>Installing New " . $name . " Package</h2><br/>".
    "<b>" . $name . " Package</b><hr/>".
    "Doing pre install cleanup";
}

sub _installFooter {
    my ( $self, $name ) = @_;
    return "<br/><br/>Finished: <a href=\"" . $self->{scriptName} . $self->{queryHead} . "p=fws_systemInfo\">Click here to continue</a></body></html>";
}

=head2 uploadSiteFile

Execute a file upload from a form post.

=cut

sub uploadSiteFile {
    my ( $self, %paramHash ) = @_;

    #
    # move the passed vars into regular vars because we might want to use this paramHash to do a saveData
    # and don't want any relics
    #
    my $secureFile          = $paramHash{FWSSecureFile};
    my $uploadFileField     = $paramHash{FWSUploadFileField};
    my $uploadField         = $paramHash{FWSUploadField};
    delete $paramHash{FWSUploadFileField};
    delete $paramHash{FWSUploadField};
    delete $paramHash{FWSSecureFile};

    #
    # get the file name and also name the "name" file that.  The "name" could be
    # replaced with the name extField if it is not blank.  But this will ensure
    # that the name is populated with at least something
    #
    my @fileArray = $self->formValue( $uploadFileField );

    #
    # set site guid if it wasn't passed
    #
    $paramHash{siteGUID} ||= $self->{siteGUID};

    #
    # process each one (I think this doesn't actually send more than one because of the uploader we use
    # , but hey, might as well!
    #
    foreach my $fileHandle ( @fileArray ) {

        my $runFileCleanup = 0;

        #
        # clean up the file name, and make sure the dirs are safe before we do anything with them
        #
        $paramHash{name}  = $self->justFileName( $self->formValue( $uploadFileField ) );
        $paramHash{name}  = $self->safeDir( $paramHash{name} );

        #
        # we have a parent... but we don't ahve a guid, this is a subrecord
        #
        if ( $paramHash{parent} && !$paramHash{guid} ) {
            #
            # save the record so we have a guid
            #
            %paramHash = $self->saveData( %paramHash );

            #
            # now that we know the guid, lets set the file name
            #
            $paramHash{$uploadField}    = $self->{fileWebPath} . '/' . $self->{siteGUID} . '/' . $paramHash{guid} . '/' . $paramHash{name};
            %paramHash                  = $self->saveData(%paramHash);

            #
            # because we are saving a record lets flag this so we do image cleanup at the end
            #
            $runFileCleanup = 1;
        }

        #
        # set the directory
        #
        my $directory = '/' . $paramHash{siteGUID} . '/' . $paramHash{guid} . '/';
        if ( $secureFile ) { $directory = $self->{fileSecurePath} . '/files/' . $directory }
        else { $directory = $self->{filePath} . $directory }
        $directory = $self->safeDir( $directory );

        #
        # make the directory if its not already there
        #
        $self->makeDir( $directory );
        $self->uploadFile( $directory, $fileHandle, $paramHash{name} );

        #
        # comptabality keys to match those in fileArray
        #
        $paramHash{fullFile} = $directory . '/' . $paramHash{name};
        $paramHash{file} = $paramHash{name};

        #
        # if we are adding new records redo any of the image thumbs and such and lets delete the guid so we can get a fresh one if there is another pass
        #
        if ( $runFileCleanup ) {
            $self->createSizedImages( guid => $paramHash{guid} );
            delete $paramHash{guid};
        }
    }
    return %paramHash;
}

sub _convertImportTags {
    my ( $self, %paramHash ) = @_;

    my $conversionString    = $paramHash{content};
    my $siteGUID            = $paramHash{siteGUID};
    my $scriptName          = $self->{scriptName};
    my $domain              = $self->{domain};
    my $secureDomain        = $self->{secureDomain};
    my $fileWebPath         = $self->{fileWebPath};

    #
    # clean and format the data from the import storage
    #
    $conversionString =~ s/#FWSSiteGUID#/$siteGUID/sg;
    $conversionString =~ s/#FWSDomain#/$domain/sg;
    $conversionString =~ s/#FWSScriptName#/$scriptName/sg;
    $conversionString =~ s/#FWSSecureDomain#/$secureDomain/sg;
    $conversionString =~ s/#FWSFileWebPath#/$fileWebPath/sg;
    return $conversionString;
}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Admin


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

1; # End of FWS::V2::Admin
