package FWS::V2::Format;

use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';

=head1 NAME

FWS::V2::Format - Framework Sites version 2 text and html formatting

=head1 VERSION

Version 1.13091122

=cut

our $VERSION = '1.13091122';

=head1 SYNOPSIS

    use FWS::V2;
    
    my $fws = FWS::V2->new();

    my $tempPassword = $fws->createPassword( lowLength => 6, highLength => 8);

    my $newGUID = $fws->createGUID();



=head1 DESCRIPTION

Framework Sites version 2 methods that use or manipulate text either for rendering or default population.

=head1 METHODS


=head2 anOrA

Return an 'a' or an 'an' based on what the next word is.

    #
    # retrieve a guid
    #
    print "This is " . $fws->anOrA( 'antalope' ) . " antalope or " . $fws->anOrA( 'cantalope' ) . " cantalope.\n':

    # return: This is an antalope or a cantalope.

=cut

sub anOrA {
    my ( $self, $postWord ) = @_;
    if ( $postWord =~ /^[aeiou]/i ) { return 'an' } else  { return 'a' }
}

=head2 createGUID

Return a non repeatable Globally Unique Identifier to be used to populate the guid field that is default on all FWS tables.

    #
    # retrieve a guid to use with a new record
    #
    my $guid = $fws->createGUID();

In version 2 all GUID's have a prefix, if not specified it will be set to 'd'.  There should be no reason to use another prefix, but if you wish you can add it as the only parameter it will be used.  In newer versions of FWS the prefix will eventually be deprecated and is only still present for compatibility.

=cut

sub createGUID {
    my ( $self, $guid ) = @_;

    #
    # Version 2 guids are always prefixed with a character, if you don't pass one
    # lets make it 'd'
    #
    if ( !$guid ) { 
        $guid = 'd';
    }

    use Digest::SHA1 qw(sha1);
    return $guid . join( '', unpack( 'H8 H4 H4 H4 H12', sha1( shift() . shift() . time() . rand() . $< . $$ ) ) );
}

=head2 activeToggleIcon

Create a on off admin lightbulb for an item that will work if you are logged in as an edit mode editor role.  Pass a data hash, and append ajaxUpdateTable if it is not updating the standard data table.

=cut

sub activeToggleIcon {
    my ( $self, %paramHash ) = @_;

    my $table = 'data';
    if ( $paramHash{ajaxUpdateTable} ) { $table = $paramHash{ajaxUpdateTable} }

    if ( !$paramHash{active} ) {
        return $self->FWSIcon(
              icon    => "lightbulb_off_16.png",
              onClick => "var currentState = 1; if (this.src.substr(this.src.length-9,2) == 'on')" .
                         "{this.src='" . $self->{fileFWSPath} .
                         "/icons/lightbulb_off_16.png'; currentState = 0; } else { this.src='".$self->{fileFWSPath} .
                         "/icons/lightbulb_on_16.png';};\$('<div></div>').FWSAjax({queryString:'" .
                         "p=fws_dataEdit&value='+currentState+'&guid=" . $paramHash{guid} .
                         "&table=" . $table . "&field=active&pageAction=AJAXUpdate',showLoading:false});",
              title   => "Active Toggle",
              alt     => "Active Toggle",
              style   => $paramHash{style},
              width   => "16",
        );
    }
    else {
        return $self->FWSIcon(    
              icon    => "lightbulb_on_16.png",
              onClick => "var currentState = 1; if (this.src.substr(this.src.length-9,2) == 'on')" .
                         "{this.src='" . $self->{fileFWSPath} .
                         "/icons/lightbulb_off_16.png'; currentState = 0; } else { this.src='" . $self->{fileFWSPath} .
                         "/icons/lightbulb_on_16.png';};\$('<div></div>').FWSAjax({queryString:'" .
                         "p=fws_dataEdit&value='+currentState+'&guid=" . $paramHash{guid} .
                         "&table=" . $table . "&field=active&pageAction=AJAXUpdate',showLoading:false});",
              style   => $paramHash{style},
              title   => "Active Toggle",
              alt     => "Active Toggle",
              width   => "16",
        );
    }
}


=head2 applyLanguage

Apply the langague to a hash, so it will return as if the current sessions language is returned as the default keys.

    #
    # retrieve a guid to use with a new record
    #
    %dataHash = $fws->applyLanguage( %dataHash );

=cut


sub applyLanguage {
    my ( $self, %langHash ) = @_;

    #
    # init the return hash
    #
    my %returnHash;

    #
    # go though each one
    #    
    foreach my $key (keys %langHash) {

        #
        # if it doesn't eend with a language notation, then run the field
        #
        if ( $key !~ /_\w\w$/ && $key !~ /_id/i ) {
            $returnHash{$key} = $self->field( $key, %langHash );
        }
        else {
            $returnHash{$key} = $langHash{$key};
        }
    }
    #
    # return our hash we created
    #
    return %returnHash;
}


=head2 captchaHTML

Return the default captcha html to be used with isCaptchaValid on its return.

=cut

sub captchaHTML {
    my ( $self ) = @_;
    my $publicKey = $self->siteValue( 'captchaPublicKey' );
    my $returnHTML;
    if ( $publicKey ) {
        $returnHTML .= "<script type=\"text/javascript\" src=\"https://www.google.com/recaptcha/api/challenge?k=" . $publicKey . "\"></script>\n";
        $returnHTML .= "<noscript><iframe src=\"https://www.google.com/recaptcha/api/noscript?k=" . $publicKey . "\" height=\"300\" width=\"500\" frameborder=\"0\"></iframe><br><textarea name=\"recaptcha_challenge_field\" rows=\"3\" cols=\"40\"></textarea><input type=\"hidden\" name=\"recaptcha_response_field\" value=\"manual_challenge\"></noscript>";
        $self->addToHead( "<script type=\"text/javascript\">var RecaptchaOptions={theme:\"clean\"};</script>\n" );
    }
    return $returnHTML;
}

=head2 CCTypeFromNumber

This will be moved to legacy.  Do not use.

=cut

sub CCTypeFromNumber {
    my ( $self, $format, $CCNumber ) = @_;

    if ( $format eq 'singleChar' ) {
        if ( $CCNumber =~ /^4/ )         { return 'V' }
        if ( $CCNumber =~ /^5/ )         { return 'M' }
        if ( $CCNumber =~ /^3/ )         { return 'A' }
        if ( $CCNumber =~ /^6/ )         { return 'D' }
    }

    if ( $format eq 'word' ) {
        if ( $CCNumber =~ /^4/ )         { return 'Visa' }
        if ( $CCNumber =~ /^5/ )         { return 'Master Card' }
        if ( $CCNumber =~ /^3/ )         { return 'American Express' }
        if ( $CCNumber =~ /^6/ )         { return 'Discover' }
    }
    
    return;
}


=head2 createPin

Return a short pin for common data structures.

    #
    # retrieve a guid to use with a new record
    #
    my $pin = $fws->createPin();

This pin will be checked against the directory, and profile tables to make sure it is not repeated and by default be 6 characters long with only easy to read character composition (23456789QWERTYUPASDFGHJKLZXCVBNM).

=cut

sub createPin {
    my ( $self, $class ) = @_;
    my $newPin;

    #
    # run a while statement until we get a guid that isn't arelady used
    #
    while ( !$newPin ) {

        #
        # new pin!
        #
        $newPin = $self->createPassword( composition => '23456789QWERTYUPASDFGHJKLZXCVBNM', lowLength => 6, highLength => 6 );

        #
        # go through all our pins and see if we have a match
        #
        for my $table ( keys %{$self->{dataSchema}} ) {
            if ( $self->{dataSchema}{$table}{pin}{type} ) {
                if ( @{$self->runSQL( SQL => "select 1 from " . $self->safeSQL( $table ) . " where pin='" . $self->safeSQL( $newPin ) . "'" )} ) {
                    $newPin = '';
                }
            }
        }
    }
    return $newPin;
}

=head2 createPassword

Return a random password or text key that can be used for temp password or unique configurable small strings.

    #
    # retrieve a password that is 6-8 characters long and does not contain commonly mistaken letters
    #
    my $tempPassword = $fws->createPassword(
                    composition     => "abcedef1234567890",
                    lowLength       => 6,
                    highLength      => 8);

If no composition is given, a vocal friendly list will be used: qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM23456789

=cut

sub createPassword {
    my ( $self, %paramHash ) = @_;

    #
    # PH for return
    #
    my $returnString;

    #
    # set the composition to the easy say set if its blank
    #
    $paramHash{composition} ||= "qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM23456789";
    $paramHash{lowLength}   ||= 6;
    $paramHash{heighLength} ||= 6;

    my @pass = split( //, $paramHash{composition} );
    my $length = int( rand( $paramHash{highLength} - $paramHash{lowLength} + 1 ) ) + $paramHash{lowLength};
    for( 1 .. $length ) { 
        $returnString .= $pass[int( rand( $#pass ) )];
    }
    return $returnString;
}


=head2 dialogWindow

Return a modal window link or onclick javascript.

Possible Parameters:

=over 4

=item * width

defaults to 800 (only pass int)

=item * height

deafults to jquery dialog deafult

=item * id

The id of the div you wish to populate the modals content with (Can not be used with queryString)

=item * queryString

The query after the queryHead used to populate the modal (Can not be used with id)

=item * linkText

If linkText is passed the return will the a the linkText wrappered in an anchor tag with the modal onclick

=item * subModal

Set this to 1 if you are passing queryString and wish to replace the current contents of the modal with the new query.  This will only work if it is called from within another modal

=item * loadingContent

HTML passed as the "now loading..." type text as HTML.  This is javascript wrappered with single tics escape them if you need to use them: \'

=back

=cut


sub dialogWindow {
    my ( $self, %paramHash ) = @_;

    #
    # Determine Auto Resize Settings default it to true if it is blank
    #
    $paramHash{autoResize} = 'true' if ( !$paramHash{autoResize} );

    #
    # set defaults and fix up the width
    #
    $self->jqueryEnable( 'ui-1.8.9' );
    $self->jqueryEnable( 'ui.dialog-1.8.9' );
    $self->jqueryEnable( 'ui.position-1.8.9' );
    if ( !defined $paramHash{width} ) { $paramHash{width} = '800' }
    my $returnHTML = "var jsAutoResize = '" . $paramHash{autoResize} . "';";
    
    #
    # build the ajax load without the jquery pre object because we could use it two different ways
    #
    my $ajaxLoad = "load('" . $self->{scriptName} . $self->{queryHead} . $paramHash{queryString} . "',function(){";
    if ( $self->{adminLoginId} ) { $ajaxLoad .= "FWSUIInit();" }
    $ajaxLoad .= "if (jsAutoResize.length) { \$.modal.update(); } });";

    #
    # create someting small and unique so we can use it as a reference
    #
    my $uniqueId = '_' . $self->createPassword( composition => 'qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM', lowLength => 6, highLength => 6 );

    $paramHash{loadingContent} ||= "<img src=".$self->loadingImage()."></img> Loading, please wait...";

    #
    # return the ajax against he modal wrapper if we are just refreshing with new content
    #

    if ( $paramHash{subModal} ) {
        $returnHTML .= "\$('.simplemodal-data').html( '".$paramHash{loadingContent} ."' );\$('.simplemodal-data')." . $ajaxLoad;
    }
    
    #
    # this is not a subModal do the whole gig
    #
    else {
        $returnHTML .= "\$('" . ( $paramHash{id} ? "#" . $paramHash{id} : "<div></div>').html( '" . $paramHash{loadingContent} . "' )").".modal({ dataId: 'modal_" . $uniqueId . "',";
    
        #
        # Set the hit and autoresize
        #
        if ( defined $paramHash{height} ) { $returnHTML .= "minHeight: " . $paramHash{height} . ",maxHeight: " . $paramHash{height} . "," }
        $returnHTML .= "autoResize: " . $paramHash{autoResize} . ",";
    
        #
        # because we do NOT have an ID, lets build the onShow loader
        #
        if ( !$paramHash{id} ) { $returnHTML .= "onShow: function (dialog) { \$('#modal_" . $uniqueId . "')." . $ajaxLoad . " }," }
    
        #
        # create the oncloase to clean up any mce thingies
        #
        $returnHTML .= "onClose: function(dialog) { FWSCloseMCE(); \$.modal.close(); },";
        $returnHTML .= "minWidth:" . $paramHash{width};
        $returnHTML .= "}); ";
    }
    
    #
    # return the link wrapperd onclick or just the onclick
    #
    if ( $paramHash{linkHTML} ) { 
        return "<span style=\"cursor:pointer;\" class=\"FWSAjaxLink\" onclick=\"" . $returnHTML . "\">" . $paramHash{linkHTML} . "</span>";
    }
    return $returnHTML;
}


=head2 splitDirectory

Return directory with the last part of the directory split into two parts.  If a directory passed into it ends with a slash, then it will be removed.

    #
    # this will return /first/part/su/supertsplitter
    #
    print $fws->splitDirectory( directory => '/first/part/supersplitter' );
    
=cut

sub splitDirectory {
    my ( $self, %paramHash ) = @_;
    
    #
    # set the default length to 2
    #
    $paramHash{splitLength} = $paramHash{splitLength} ||= 2;

    #
    # managable parts
    #
    my @dirParts = split( /\//, $paramHash{directory} );

    #
    # take the one off the ened
    #
    my $lastDirPart = pop( @dirParts );
    
    return join( '/', @dirParts ) . '/' . substr( $lastDirPart, 0, $paramHash{splitLength} ) . '/' . $lastDirPart;
}


=head2 fieldHash

Return a hash of formValues passed to the current post that are not used for the FWS core.

    my %formFieldsPopulated = $fws->fieldHash();

=cut

sub fieldHash {
       my ( $self, %fieldHash ) = @_;

       #
       # put the fields in the screen and block out the ones we don't want to pass though
       #
       my @formArray = $self->formArray();
       foreach my $fieldName ( @formArray ) {
           if ( $fieldName !~ /^(amp|id|pageAction|killSession|page|a|noSession|session|l|p|s|b|editMode|bs)$/ && $fieldName !~ /FWS_/i ) {
               $fieldHash{$fieldName} = $self->formValue( $fieldName );
           }
       }
       return %fieldHash;
}


=head2 fontCSS

Return css that will set the default FWS font for inline use before CSS is capable of being applied.

=cut

sub fontCSS {
    return "font-size:12px;font-family: Tahoma, serifSansSerifMonospace;";
}


=head2 formatDate

Return the date time in a given format.  By passing epochTime, SQLTime you can do a time conversion from that date/time to what ever format is set to.  If you do not pass epoch or SQL time the server time will be used.

    #
    # get the current Date in SQL format
    #
    my $currentDate = $fws->formatDate( format => 'date' );
    
    #
    # convert SQL formated date time to a human form
    #
    my $humanDate = $fws->formatDate( SQLTime => '2012-10-12 10:09:33', format => 'date' );

By passing minuteMod, monthMod or dayMod you can adjust the month forward or backwards by the given number of months or days

    #
    # 3 months from today (negative numbers are ok)
    #
    my $threeMonths = $fws->formatDate( format => 'date', monthMod => 3 );

Multilingual support: French date formats will be used  for 'fancyDate' and 'date' if the language() is set to FR.

Possible Parameters:

=over 4

=item * format

Format type to return.  This is the only required field

=item * epochTime

epoch time which could be created with time()

=item * monthMod

Modify the current month ahead or behind.  (Note: If your current day is 31st, and you mod to a month that has less than 31 days it will move to the highest day of that month)

=item * dayMod

Modify the current day ahead or behind.

=item * minuteMod

Modify the current minute ahead or behind.

=item * dateSeparator

This will default to '-', but can be changed to anything.   (Note: Do not use this if you are returing SQLTime format)

=item * GMTOffset

Time zone modifier.  Example: CST would be -5

=item * numberTime

Use an number translated time format (It looks like SQL without sperators)  YYYYMMDDHHMMSS.  HHMMSS will default to 000000 if not passed.

=item * SQLTime

Use an SQL time format as the incomming date and time.

=item * ISO8601

Use GMT based ISO8601 formated time as the incomming date and time.

=back

The following types of formats are valid:

=over 4

=item * date

mm-dd-yyyy

=item * time

hh:mmAM XXX

=item * shortDate

MMM DD YYYY  (MMM is the three letter acrynomn for the month in caps)

=item * fancyDate

weekdayName, monthName dd[st|nd|rd] of yyyy

=item * cookie

cookie compatible date/time

=item * apache

apache web server compatible date/time

=item * number

yyyymmddhhmmss

=item * dateTime

mm-dd-yyyy hh:mmAM XXX

=item * dateTimeFull

mm-dd-yyyy hh:mm:ss XXX

=item * SQL

yyyy-mm-dd hh:mm:ss

=item * epoch

Standard epoch number

=item * yearFirstDate

yyyy-mm-dd

=item * year

yyyy

=item * month

mm

=item * day

dd

=item * ISO8601

YYYY-MM-DDTHH:MM:SSZ (The Z and the T are literal.  This format will always return GMT, but when epoch, and SQLTime are passed, they should passed as server time because they will be converted to GMT on the based on $fws->{GMTOffset} site setting)

=back

=cut

sub formatDate {
    my ( $self, %paramHash ) = @_;
    $paramHash{format}        ||= 'dateTime';
    $paramHash{monthMod}      ||= 0;
    $paramHash{dayMod}        ||= 0;
    $paramHash{minuteMod}     ||= 0;
    $paramHash{epochTime}     ||= time();
    $paramHash{dateSeparator} ||= '-';

    #
    # set defaults
    #
    $paramHash{GMTOffset} ||= 0;

    #
    # set up the ISO8601 date time and make it SQL with the GMTOffset and then process form there
    #
    if ( $paramHash{ISO8601} ) {
        $paramHash{GMTOffset} = $self->{GMTOffset};
        $paramHash{SQLTime}   = $paramHash{ISO8601};
        $paramHash{SQLTime}   =~ s/T/ /sg;
        $paramHash{SQLTime}   =~ s/Z//sg;
    }

    #
    # pase numbers or sql times
    #
    if ( defined $paramHash{numberTime} || defined $paramHash{SQLTime}) {
           
        #     
        # do sql by default, but overwrite with numberTime if thats what it is
        #
        my @timeSplit = split( /[ \-:]/, $paramHash{SQLTime} );

        if ( defined $paramHash{numberTime} ) {
            $timeSplit[0] = substr( $paramHash{numberTime} ,0,4 );
            $timeSplit[1] = substr( $paramHash{numberTime} ,4,2 );
            $timeSplit[2] = substr( $paramHash{numberTime} ,6,2 );
            $timeSplit[3] = substr( $paramHash{numberTime} ,8,2 );
            $timeSplit[4] = substr( $paramHash{numberTime} ,10,2 );
            $timeSplit[5] = substr( $paramHash{numberTime} ,12,2 );
        }
        
        #
        # fix anything that could rock the boat older versions of perl need this for
        # timelocal to work, 1902 -> 2037 is safe
        #
        if ( $timeSplit[0] < 1902) {$timeSplit[0] = '1902';}
        if ( $timeSplit[0] > 2037) {$timeSplit[0] = '2037';}
        if ( $timeSplit[1] eq '' || $timeSplit[1] == 0) {$timeSplit[1] = '1'}
        if ( $timeSplit[2] eq '' || $timeSplit[2] == 0) {$timeSplit[2] = '1'}
        if ( $timeSplit[3] eq '') {$timeSplit[3] = '0'}
        if ( $timeSplit[4] eq '') {$timeSplit[4] = '0'}
        if ( $timeSplit[5] eq '') {$timeSplit[5] = '0'}

        #
        # fix the month and make it epoch to use for the rest of the script
        #
        $timeSplit[1]--;
        require Time::Local;
        Time::Local->import();
        $paramHash{epochTime} = timelocal( reverse( @timeSplit ) );
    }
    
    #
    # offset the time if reqested to
    # 
    $paramHash{epochTime} += ( $paramHash{GMTOffset} * 3600 );

    #
    # move the day around if passed
    #
    $paramHash{epochTime} += ( $paramHash{dayMod} * 86400 );

    #
    # move the minute around if passed
    #
    $paramHash{epochTime} += ( $paramHash{minuteMod} * 60 ); 

    #
    # get the localtime
    #
    my ( $sec, $min, $hr, $mday, $mon, $annum, $wday, $yday, $isdst ) = localtime( $paramHash{epochTime} );

    #
    # we want months to go from 1-12 with the mod adjustment
    #
    $mon += $paramHash{monthMod} + 1;

    #
    # and we want to use four-digit years
    #
    my $year = 1900 + $annum;

    #
    # min and second is always leading zero
    #
    $min = ( "0" x ( 2 - length( $min ) ) ) . $min;
    $sec = ( "0" x ( 2 - length( $sec ) ) ) . $sec;

    #
    # lets grab minute before we PM/AM it
    #
    my $minute = $min;

    #
    #grab the hour before we am/pm it
    #
    my $hour = $hr;

    #
    # turn military time time to AM/PM time
    # hr is the AM PM version hour is military
    #
    if ( $hr > 12 ) {
        $hr = $hr-12;
        $min .= "PM";
    }
    else {
        if ( $hr == 12 )    { $min .= "PM" }
        else                { $min .= "AM" }
    }

    #
    # if the $month is less than 1 then shift them off to the year slots
    # if the monthmod is more than 12 shift them off to the year slots positivly
    #
    while ( $mon < 1 ) {
        $mon += 12;
        $year--;
    }
    while ( $mon > 12 ) {
        $mon -= 12;
        $year++;
    }

    #
    # adjust the number of months by the mod
    #
    my $month = ( "0" x (2 - length( $mon ) ) ) . $mon;

    #
    # leading zero our minute
    #
    $hour = ( "0" x (2 - length( $hour ) ) ) . $hour;
    my $monthDay = ( "0" x ( 2 - length( $mday ) ) ) . $mday;

    #
    # this is what we will return
    #
    my $showDateTime;

    if ( $paramHash{format} =~ /^number$/i ) {
        $showDateTime = $year.$month.$monthDay.$hour.$minute.$sec;
    }

    if ( $paramHash{format} =~ /^shortDate$/i ) {
        my @monthName = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
        $showDateTime = $monthName[$mon-1] . ' ' . $monthDay . ' ' . $year;
    }

    if ( $paramHash{format} =~ /^cookie$/i ) {
        my @dayName     = qw( Sun Mon Tue Wed Thu Fri Sat );
        my @monthName   = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
        $showDateTime   = $dayName[$wday] . ', ' . $monthDay . $paramHash{dateSeparator} . $monthName[$mon-1] . $paramHash{dateSeparator} . $year . ' ' . $hour . ':' . $minute . ':' . $sec . ' GMT';
    }

    if ( $paramHash{format} =~ /^ISO8601$/i ) {
        $showDateTime = sprintf( "%04d-%02d-%02dT%02d:%02d:%02dZ", sub { ( $_[5]+1900, $_[4] + 1, $_[3], $_[2], $_[1], $_[0] ) }->( gmtime( $paramHash{epochTime} ) ) );
    }


    if ( $paramHash{format} =~ /^fancyDate$/i ) {
        my @dayName     = qw( Sunday Monday Tuesday Wednesday Thursday Friday Saturday );
        my @monthName   = qw( January Febuary March April May June July August September October November December );

        #
        # date names in french
        #
        if ( $self->language() =~ /fr/i ) { @dayName     = qw( Dimanche Lundi Mardi Vendredi Jeudi Vendredi Samedi ) }
        if ( $self->language() =~ /fr/i ) { @monthName   = qw( janvier fevrier mars avril mai juin juillet a^out septembre octobre novembre decembre ) }

        # 
        # English th/nd/st rules 
        # 
        my $numberCap = 'th';
        $monthDay =~ s/^0//sg;
        if ( $monthDay =~ /2$/ && $monthDay ne '12' ) {     $numberCap = "nd" }
        if ( $monthDay =~ /3$/ && $monthDay ne '13' ) {     $numberCap = "rd" }
        if ( $monthDay =~ /1$/i && $monthDay ne '11' ) {    $numberCap = "st" }

        #
        # English date format
        # 
        $showDateTime = $dayName[$wday] . ', ' . $monthName[$mon-1] . ' ' . $monthDay . $numberCap . ',' . ' ' . $year;

        #
        # French date format
        #
        if ( $self->language() =~ /fr/i ) { $showDateTime = $dayName[$wday] . ' le ' . $monthDay . ' ' . $monthName[$mon-1] . ' ' . $year }
    }

    if ( $paramHash{format} =~ /^apache$/i ) {
        my @monthName = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
        my @dayName = qw( Sun Mon Tue Wed Thu Fri Sat );
        my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( $paramHash{epochTime} );
        $year = $year + 1900;
        $showDateTime = $dayName[$wday] . ', ' . $mday . ' ' . $monthName[$mon] . ' ' . $year . ' ' . $hour . ':' . $minute . ':' . $sec . ' GMT';
    }

    if ( $paramHash{format} =~ /^(odbc|SQL)$/i ) {
        $showDateTime = $year . $paramHash{dateSeparator} . $month . $paramHash{dateSeparator} . $monthDay . " " . $hour . ":" . $minute . ":" . $sec;
    }

    if ( $paramHash{format} =~ /^date$/i ) {
        #
        # english date
        #
        $showDateTime = $month . $paramHash{dateSeparator} . $monthDay . $paramHash{dateSeparator} . $year;

        #
        # french date
        #
        if ( $self->language() =~ /fr/i ) { $showDateTime = $monthDay . $paramHash{dateSeparator} . $month . $paramHash{dateSeparator} . $year }
    }
    
    if ( $paramHash{format} =~ /^month$/i )      { $showDateTime = $month }
    if ( $paramHash{format} =~ /^year$/i )       { $showDateTime = $year }
    if ( $paramHash{format} =~ /^day$/i )        { $showDateTime = $monthDay }

    # TODO Need to make timzone text fws configurable
    if ( $paramHash{format} =~ /^time$/i )       { $showDateTime = $hr . ":" . $min . " EST" }

    # TODO Need to make timzone text fws configurable
    if ( $paramHash{format} =~ /^dateTime$/i ) {
        $showDateTime = $month . $paramHash{dateSeparator} . $monthDay . $paramHash{dateSeparator} . $year . " " . $hr . ":" . $min . " EST";
    }

    # TODO Need to make timzone text fws configurable
    if ( $paramHash{format} =~ /^dateTimeFull$/i ) {
        $showDateTime = $month . $paramHash{dateSeparator} . $monthDay . $paramHash{dateSeparator} . $year . " " . $hour . ":" . $minute . ":" . $sec." EST";
    }

    if ( $paramHash{format} =~ /^yearFirstDate$/i ) {
        $showDateTime = $year . $paramHash{dateSeparator} . $month . $paramHash{dateSeparator} . $monthDay;
    }

    if ( $paramHash{format} =~ /^firstOfMonth$/i ) {
        $showDateTime = $month . $paramHash{dateSeparator} . "01" . $paramHash{dateSeparator} . $year;
    }

    if ( $paramHash{format} =~ /^epoch$/i ) {
        $showDateTime = $paramHash{epochTime};
    }

    return $showDateTime;
}

=head2 field

Return a field based on dynamic language and falling back to the default if the language specific value isn't available.

    print $fws->field( 'title', %dataHash );

=cut

sub field {
    my ( $self, $fieldName, %dataHash ) = @_;

    #
    # the datafields have a couple of issues with core field names that do not match its language field
    # here are the conversions
    #
    $fieldName =~ s/^navigationName/nav_name/s;

    #
    # check to see if a language specific one exists
    #
    if ( $dataHash{$fieldName . '_' . $self->language()} ) {
        $dataHash{$fieldName} = $dataHash{$fieldName . '_' . $self->language() }
    }
    else {
        #
        # put the navigationName back if we didn't have to switch
        #
        $fieldName =~ s/^nav_name/navigationName/s;
    }

    #
    # return either the default, or the language specific one
    #
    return $dataHash{$fieldName};    
}

=head2 formatCurrency

Return a number in USD Format.

    print $fws->formatCurrency(33.55);

=cut

sub formatCurrency {
    my ( $self, $amount ) = @_;
    #TODO convert this method to use paramHash with international support yet still legacy to work in this fasion
    my $negative = '';
    if ( $amount =~ /^-/ ) { $negative = '-' }
    $amount =~ s/[^\d.]+//g;
    $amount = $amount + 0;
    if ( $amount == 0 ) { $amount = "0.00" }
    else { $amount = sprintf ( "%.2f", $amount ) }
    $amount =~ s/\G(\d{1,3})(?=(?:\d\d\d)+(?:\.|$))/$1,/g;
    return "\$" . $negative . $amount;
}


=head2 formatPhone

Return a phone number in a specific format.

    print $fws->formatPhone( format => 'full', phone => '555-367-5309' );


Valid formats: 

number: 1234567890

full: (123) 456-7890

dots: 123.456.7890

=cut

sub formatPhone {
    my ( $self, %paramHash ) = @_;
    my $returnPhone = $paramHash{phone};
    $paramHash{phone}     =~ s/[\D]//sg;
    $paramHash{phone}     = substr( $paramHash{phone}, -10 );
    if ( length( $paramHash{phone} ) != 10) { $returnPhone = '' } else {
        if ( $paramHash{format} eq 'number' ) {
            $returnPhone        = $paramHash{phone};
        }
        if ( $paramHash{format} eq 'full' ) {
            $returnPhone = '(' . substr( $paramHash{phone}, 0, 3 ) . ') ' . substr( $paramHash{phone}, 3, 3 ) . '-' . substr( $paramHash{phone}, 6, 4 );
        }
        if ( $paramHash{format} eq 'dots' ) {
            $returnPhone = substr( $paramHash{phone}, 0, 3 ) . '.' . substr( $paramHash{phone}, 3, 3 ) . '.' . substr( $paramHash{phone}, 6, 4 );
        }
    }
    return $returnPhone;
}


=head2 FWSButton

Create a button that is default to JQuery UI class structure.  You can pass style, class, name, id, value and onClick keys.

=cut

sub FWSButton{
    my ( $self, %paramHash ) = @_;
    my $buttonHTML = "<button class=\"ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only " . $paramHash{class} . "\" type=\"button\" ";
    if ( $paramHash{style} )   { $buttonHTML .= " style=\"" . $paramHash{style} . "\" " }
    if ( $paramHash{name} )    { $buttonHTML .= " name=\"" . $paramHash{name} . "\" " }
    if ( $paramHash{id} )      { $buttonHTML .= " id=\"" . $paramHash{id} . "\" " }
    if ( $paramHash{onClick} ) { $buttonHTML .= " onclick=\"" . $paramHash{onClick} . "\"" }
    $buttonHTML .= ">";
    $buttonHTML .= "<span class=\"ui-button-text\">" . $paramHash{value} . "</span>";
    $buttonHTML .= "</button>";
    
    return $buttonHTML;
}


=head2 FWSHint

Return a FWS Hint HTML for roll over hint icons or links.

=cut

sub FWSHint {
    my ( $self, %paramHash ) = @_;
    #
    # add the jquery
    #
    $self->jqueryEnable( 'easyToolTip-1.0' );

    #
    # if no id is givin, that means we are posting an image
    #
    my $returnHTML;
    if ( !$paramHash{id} ) {
        my $imgPath = $self->fileWebPath()."/fws/jquery/easyToolTip-1.0/";
        $paramHash{id} = 'hint_' . $self->createPassword( composition => 'qwertyupasdfghjkzxcvbnmQWERTYUPASDFGHJKZXCVBNM', lowLength => 4, highLength => 4 );
        $returnHTML .= "<img onmouseout=\"this.src='" . $imgPath . "help_trans.png';\" onmouseover=\"this.src='" . $imgPath . "help.png';\" class=\"FWSHint\" id=\"" . $paramHash{id} . "\" src=\"" . $imgPath . "help_trans.png\"/>";
    }

    #
    # create the JS
    #
    my $headHTML = "<script type=\"text/javascript\">";
    $paramHash{content} =~ s/\n//sg;
    $paramHash{content} =~ s/'/&#39;/sg;
    $headHTML .= "\$('#" . $paramHash{id} . "').easyTooltip({ content: '" . $paramHash{content} . "'});";
    $headHTML .= "</script>\n";

    return $returnHTML . $headHTML;
}


=head2 FWSIcon

Return just the file name when given a full file path

       $valueHash{html} .= $fws->FWSIcon( icon => 'blank_16.png' );

You can pass the following keys:

    icon
    class
    id
    width
    alt
    onClick

=cut

sub FWSIcon {
    my ( $self, %paramHash ) = @_;
    $paramHash{icon}    ||= 'blank.png';
    $paramHash{alt}     ||= '\'\'';
    if ( $paramHash{class} ) {    $paramHash{class}  = ' class="' . $paramHash{class} . '"' }
    if ( $paramHash{id} ) {       $paramHash{id}     = ' id="' . $paramHash{id} . '"' }
    if ( $paramHash{width} ) {    $paramHash{style} .= "width:" . $paramHash{width} . "px" }
    if ( $paramHash{onClick} ) {
        $paramHash{onClick}   = " onclick=\"" . $paramHash{onClick} . "\"";
        $paramHash{style}     = 'cursor:pointer;' . $paramHash{style};
    }
    return "<img src=\"" . $self->{fileFWSPath} . "/icons/" . $paramHash{icon} . "\" alt=\"" . $paramHash{alt} . "\"" . $paramHash{id} . $paramHash{class} . $paramHash{onClick} . " style=\"border:none;" . $paramHash{style} . "\"/>";
}


=head2 justFileName

Return just the file name when given a full file path

    my $fileName = $fws->justFileName( '/this/is/not/going/to/be/here/justTheFileName.jpg' );

=cut

sub justFileName {
    my ( $self, $justFileName ) = @_;

    #
    # change the \ to /'s
    #
    $justFileName =~ s/\\/\//g;

    #
    # split it up and pop off the last one
    #
    my @fileNameArray = split( /\//, $justFileName );
    $justFileName = pop( @fileNameArray );

    return $justFileName
    }

=head2 jqueryEnable

Add FWS core distribution jQuery modules and corresponding CSS files to the CSS and JS cached files.  These are located in the /fws/jquery directory.  The naming convention for jQuery files are normalized and only the module name and version is required.

    #
    # if the module you were loadings file name is:
    # jquery-WHATEVERTHEMODULEIS-1.1.1.min.js
    # it would be loaded via jqueryEnable as follows:
    #
    $fws->jqueryEnable( 'WHATEVERTHEMODULEIS-1.1.1' );

This method ensures jQuery files are only loaded once, and the act of any jQuery module being enabled will auto-activate the core jQuery library.  They will be loaded in the order they were called  from any element in the rendering process.

=cut

sub jqueryEnable {
    my ( $self, $jqueryEnable ) = @_;


    #
    # make sure this is something before we continue
    #
    if ( $jqueryEnable ) {
    
        #
        # get the current hash
        #
        my %jqueryHash = %{$self->{_jqueryHash}};
    
        #
        # if its already there lets just leave it alone
        #
        if ( !$jqueryHash{$jqueryEnable} ) { 
            
            #
            # set the number, but lets make sure its greater than 1
            # so we can do boolean tests against it
            # 
            $jqueryHash{$jqueryEnable} = ( keys %jqueryHash ) + 1;
            
        }
  
        #
        # pass the new hash back into the jqueryHash
        #
        %{$self->{_jqueryHash}} = %jqueryHash;
    }

    return;
}


=head2 loadingImage

Return the web path for the default loading image spinny.

=cut

sub loadingImage {
    my ( $self ) = @_;
    return $self->{fileFWSPath} . "/saving.gif";
}


=head2 logoutOnClick

Return the on click javascript for a logout button.   You can pass landingPage key if you want it to land somewhere besides the current page.  This is also trigger the facebook logout.

=cut

sub logoutOnClick {
    my ( $self, %paramHash ) = @_;

    my $logoutHTML;

    #
    # set the landing page you will fall once this happens
    #
    my $landingPage = $self->formValue( 'p' );
    if ( $paramHash{landingPage} ) { $landingPage = $paramHash{landingPage} }

    #
    # logout string
    #
    $logoutHTML .= "location.href='" . $self->{scriptName} . "?s=" . $self->{siteId} . "&p=" . $landingPage . "&pageAction=logout';";

    #
    # if we are running facebook, we need to run logout();
    #
    if ( $self->siteValue( 'facebookAppId' ) ) {
        $logoutHTML = "FB.getLoginStatus( function(response) {  if (response.authResponse) {FB.logout(function(response) {" . $logoutHTML . "});} else { " . $logoutHTML . "}});return false;";
    }

    return $logoutHTML;
}


=head2 navigationLink

Return a wrapped link of data hash that can be linked to.  This supports friendlies, forced or not, and url linking.

=cut

sub navigationLink {
    my ( $self, %hrefHash ) = @_;
    my $href;
    #
    # if it is a page create this or we just want the href then do this
    #
    if ( $hrefHash{type} eq 'page' || $hrefHash{hrefOnly} ) {
        #
        # if there is a friendly for the URL use it, if not do the page=id stuff.
        #
        if ( $hrefHash{friendlyURL} && !$self->siteValue( 'noFriendlies' ) ) {
            $href .= '/' . $hrefHash{friendlyURL};
        }
        else {
            $href .= $self->{scriptName} . '?s=' . $self->{siteId} . '&p=' . $hrefHash{guid};
        }
    }

    #
    # we only want the href, reguardless of antying.  give and get out
    #
    if ( $hrefHash{hrefOnly} ) {
        return $href;
    };

    #
    # URL
    #
    if ( $hrefHash{type} eq 'url' ) { $href = "<a href=\"" . $hrefHash{url} . "\"" }

    #
    # finish grooming the href if its for a page.
    #
    if ( $hrefHash{type} eq 'page' ) {
        $href = "<a href=\"" .  $href . "\""
    }

    if ( $hrefHash{type} eq "page" || $hrefHash{type} eq "url") {

        #
        # if we are on the page we are printing add "currentPage"
        #
        if ( $hrefHash{guid} eq $self->formValue( 'FWS_pageId' ) ) {
            $href .= ' class="currentPage"';
        }

        #
        # End the href part of the anchor
        #
        $href .= ">";

        #
        # html friendly the text for the between the a's
        #
        $hrefHash{name} =~ s/&/&amp;/sg;
        $hrefHash{name} =~ s/</&lt;/sg;
        $hrefHash{name} =~ s/>/&gt;/sg;

        #
        # bilingual the name, and navName;
        #
        $hrefHash{navigationName} = $self->field( 'navigationName', %hrefHash );

        #
        # add the text for the name, and close the anchor
        #
        $href .= ( $hrefHash{navigationName} ) ? $hrefHash{navigationName} : $hrefHash{name};
        
        $href .= "</a>";
    }
    return $href;
}


=head2 popupWindow

Create a link to a popup window or just the onclick.  Passing queryString is requried and pass linkHTML if you would like it to be a link.  

    $valueHash{html} .= $fws->popupWindow(queryString=>'p=somePage',$linkHTML=>'Click Here to go to some page');

NOTE: This should only be used in the context of the FWS Administration, and is only here as a reference for modifiers of the admin. 

=cut

sub popupWindow {
    my ( $self, %paramHash ) = @_;
    my $returnHTML = "window.open('" . $self->{scriptName} . $self->{queryHead} . $paramHash{queryString} . "','_blank');";
    if ( $paramHash{linkHTML} ) {
        return "<span class=\"FWSAjaxLink\" onclick=\"" . $returnHTML . "\">" . $paramHash{linkHTML} . "</span>";
    }
    return $returnHTML;
}

=head2 removeHTML

Return a string minus anything that is in < >.

    $safeForText = $fws->removeHTML( '<a href="somelink.html">This is the text that will return without the anchor</a>' );

=cut

sub removeHTML {
    my ( $self, $theString ) = @_;
    $theString =~ s/<!.*?-->//gs;
    $theString =~ s/<.*?>//gs;
    return $theString;
}

=head2 startElement

Return a the complement to endElement having the default title control and class labeling.

    $valueHash{html} .= $fws->startElement( %dataHash );
    $valueHash{html} .= $fws->endElement( %dataHash );

If there is no dataHash to pass, you can set its the keys elementClass, title, and disableTitle to control its appearence.

=cut

sub startElement {
    my ( $self, %dataHash ) = @_;

    my $elementClass = $self->formValue( 'FWS_elementClassPrefix' );
    if ( $dataHash{elementClass} ) { $elementClass = $dataHash{elementClass} }

    #
    # start two divs for positioning and backgrounds
    #
    my $html = "<div class=\"globalElementWrapper " . $elementClass . "Wrapper\"><div class=\"globalElement " . $elementClass . "\">";

    #
    # Title Field/Table
    #
    if ( !$dataHash{disableTitle} ) {
        $html .= "<div class=\"globalTitleWrapper " . $elementClass . "TitleWrapper\"><h2 class=\"globalTitle " . $elementClass . "Title\">";
        $html .= $self->field( 'title', %dataHash );
        $html .= "</h2></div>";
    }

    $html .= "<div class=\"globalContentWrapper " . $elementClass . "ContentWrapper\">";

    #
    # wrap the element
    #
    return $html;
}

=head2 stateDropDown

Return a dropdown for all US States, passining it (current, class, id, name, style, topOption)  TopOption if passed will be the text that is displayed for the option, but the value will be blank.

=cut

sub stateDropDown {
    my ( $self, %paramHash ) = @_;

    #
    # create a array we will process of states
    #
    my @stateArray = ( 'AL', 'Alabama', 'AK', 'Alaska', 'AZ', 'Arizona', 'AR', 'Arkansas', 'CA', 'California', 'CO', 'Colorado', 'CT', 'Connecticut', 'DE', 'Delaware', 'DC', 'District of Columbia', 'FL', 'Florida', 'GA', 'Georgia', 'HI', 'Hawaii', 'ID', 'Idaho', 'IL', 'Illinois', 'IN', 'Indiana', 'IA', 'Iowa', 'KS', 'Kansas', 'KY', 'Kentucky', 'LA', 'Louisiana', 'ME', 'Maine', 'MD', 'Maryland', 'MA', 'Massachusetts', 'MI', 'Michigan', 'MN', 'Minnesota', 'MS', 'Mississippi', 'MO', 'Missouri', 'MT', 'Montana', 'NE', 'Nebraska', 'NV', 'Nevada', 'NH', 'New Hampshire', 'NJ', 'New Jersey', 'NM', 'New Mexico', 'NY', 'New York', 'NC', 'North Carolina', 'ND', 'North Dakota', 'OH', 'Ohio', 'OK', 'Oklahoma', 'OR', 'Oregon', 'PA', 'Pennsylvania', 'RI', 'Rhode Island', 'SC', 'South Carolina', 'SD', 'South Dakota', 'TN', 'Tennessee', 'TX', 'Texas', 'UT', 'Utah', 'VT', 'Vermont', 'VA', 'Virginia', 'WA', 'Washington', 'WV', 'West Virginia', 'WI', 'Wisconsin', 'WY', 'Wyoming');

    #
    # preformat anything that will be in the html that is passed
    #
    if ( $paramHash{class} )         { $paramHash{class}         = 'class="' . $paramHash{class} . '" ' }
    if ( $paramHash{style} )         { $paramHash{style}         = 'style="' . $paramHash{style} . '" ' }
    if ( $paramHash{id} )            { $paramHash{id}            = 'id="' . $paramHash{id} . '" ' }
    if ( $paramHash{name} )          { $paramHash{name}          = 'name="' . $paramHash{name} . '" ' }
    if ( $paramHash{topOption} )     { $paramHash{topOption}     = '<option value="">' . $paramHash{topOption} . '</option>' }

    #
    # start off the select with the top opction if present
    #
    my $returnHTML = '<select ' . $paramHash{name} . $paramHash{id} . $paramHash{class} . $paramHash{style} . '>' . $paramHash{topOption};

    #
    # loop though the array creating each one, with the selected if the current matches
    #
    while ( @stateArray ) {
        my $stateAbbr = shift( @stateArray );
        my $stateName = shift( @stateArray );
        $returnHTML .= '<option ';
        if ( $paramHash{current} =~ /$stateAbbr/i ) { $returnHTML .= 'selected="selected" ' }
        $returnHTML .= 'value="' . $stateAbbr . '">' . $stateName . '</option>';
    }

    #
    #  Close the select, and return our HTML for the select
    #
    $returnHTML .= '</select>';
    return $returnHTML;
}


=head2 SQLDate

Return a date string in SQL format if it was passed ass SQL format already, or convert it if it was sent as mm-dd-yyyy.

    my $SQLDate = $fws->SQLDate( '2012-02-03' );

=cut

sub SQLDate {
    #TODO Depricate SQLDate this and make it part of formatDate
    my ( $self, $date ) = @_;
    my @dateSplit = split(/\D/,$date);
    if ( length( $dateSplit[2]) == 4 ) {
        $date = $dateSplit[2] . '-' . $dateSplit[0] . '-' . $dateSplit[1];
    }
    else {
        $date = $dateSplit[0] . '-' . $dateSplit[1] . '-'.$dateSplit[2];
    }
    return $self->safeSQL( $date );
}

=head2 truncateContent

Return content based on nearest ended word to the length parameter.

    print $fws->truncateContent(
        content     => 'this is some long content I want just a preview of.',
        length      => 10, 
        postText    => '...',
    );

=cut



sub truncateContent {
    my ( $self, %paramHash ) = @_;

    #
    # add a space to make the logic easier, we will eat this after the fact if its still sitting around
    #
    $paramHash{content} .= ' ';
    my @charArray   = split( //, $paramHash{content} );
    my $count       = 0;
    my $newString;
    my $currentWord;

    #
    # loop though the array, adding to the newstring if there is a friendly space
    #
    while ( @charArray ) {
        $count++;
        my $currentChar = shift( @charArray );
        if ( $count < $paramHash{length} ) {
            $currentWord .= $currentChar;
            if ( $currentChar eq ' ' ) {
                $newString .= $currentWord;
                $currentWord = '';
            }
        }
    }

    #
    # if there is no friendly spaces, just chop at the maxLength
    #
    if ( $newString eq '' ) {
        $newString = substr( $paramHash{content}, 0, $paramHash{length} );
    }

    #
    # eat the post space if there is any.
    #
    $newString =~ s/\s+$//sg;

    #
    # add posttext if there is a chop
    #
    if ( $paramHash{content} ne $newString ) { $newString .= $paramHash{postText} }

    #
    # return our newly created pontentialy shorter string
    #
    return $newString;
}


=head2 urlEncode

Encode a string to make it browser url friendly.

    print $fws->urlEncode( $someString );

=cut

sub urlEncode {
    my ( $self, $url ) = @_;
    $url =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    return $url;
}

=head2 urlDecode

Decode a string to make it potentially browser url unfriendly.

    print $fws->urlEncode( $someString );

=cut

sub urlDecode {
    my ( $self, $url ) = @_;
    $url =~ s/\+/ /sg;
    $url =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $url;
}


=head2 endElement

Return the complement to startElement() having the default by placing the appropriate close divs created in startElement().

    $valueHash{html} .= $fws->startElement( %dataHash );
    $valueHash{html} .= $fws->endElement( %dataHash );

=cut

sub endElement {
    my ( $self ) = @_;
    return "</div></div></div>";
}


=head2 convertUnicode

Convert from unicode charcters from web services to a standard character.

=cut

sub convertUnicode {
    my ( $self, $conversionString ) = @_;
    $conversionString =~ s/((?:\A|\G|[^\\]))\\u([\da-fA-F]{4})/$1.hex2chr($2)/gse;
    return $conversionString;
}


=head2 hex2chr

Convert hex to its ascii character.

=cut

sub hex2chr {
    my( $hex ) = @_;
    if ( hex( $hex ) >= 0 and hex( $hex ) < 65536) { return ( chr( hex( $hex ) ) ); }
}


sub _jsEnable {
    my ( $self, $jsEnable, $modifier ) = @_;

    #
    # get the current hash
    #
    my %jsHash = %{$self->{_jsHash}};

    #
    # always add one to modifier to its never 0
    #
    $modifier++;

    #
    # set the number to at least one
    #

    #
    # if its already there lets just leave it alone
    #
    if ( !$jsHash{$jsEnable} ) { $jsHash{$jsEnable} = ( keys %jsHash ) + $modifier }

    #
    # pass the new hash back into the jsHash
    #
    %{$self->{_jsHash}} = %jsHash;

    return %jsHash;
}


sub _cssEnable {
    my ( $self, $cssEnable, $modifier ) = @_;
    
    #
    # get the current hash
    #
    my %cssHash = %{$self->{_cssHash}};
    
    #
    # always add one to modifier to its never 0
    #
    $modifier++;

    #
    # if its already there lets just leave it alone
    #
    if ( !$cssHash{$cssEnable} ) { $cssHash{$cssEnable} = ( keys %cssHash ) + $modifier }

    #
    # pass the new hash back into the cssHash
    #
    %{$self->{_cssHash}} = %cssHash;

    return %cssHash;
}


sub _minCSS {
    my ( $self ) = @_;
    #
    # when showing pre-installation screens this is the CSS that will make login's and panels show up correctly
    # this is only used for adminLogin and for fws_systemInfo
    #
    return '<style type="text/css">'.
          'body {font-family: Tahoma, serifSansSerifMonospace;font-size:12px;}' . 
          '.FWSStatusNote { padding:15px;text-align:center;color:#FF0000; }' . 
          '.FWSPanelTitle { padding:10px;color:#2B6FB6;padding-bottom:15px;font-size:16px;font-weight:800; }' . 
          '.FWSPanel { width:90%;margin:auto;margin-bottom:20px; }' . 
          '.FWSPanelContent { padding:10px;font-size:12px;}' . 
          '.loginInput { width:200px; }' . 
          '.loginSubmit { text-align:right;width:275px; }' . 
          '.ui-corner-all { -moz-border-radius: 4px; -webkit-border-radius: 4px; border-radius: 4px; }' . 
          '.ui-widget { font-family: Tahoma, serifSansSerifMonospace; font-size: 14px }' . 
          '.ui-widget button { font-family: Tahoma, serifSansSerifMonospace; font-size: 14px; }' . 
          '.ui-widget-content { border: 1px solid #aaaaaa; background: #ffffff url(' . $self->{fileFWSPath} . '/jquery/ui-1.8.9/ui-bg_flat_75_ffffff_40x100.png) 50% 50% repeat-x; color: #222222; }' . 
          '.ui-button { display: inline-block; position: relative; padding: 5px; margin-right: .1em; text-decoration: none !important; cursor: pointer; text-align: center; overflow: visible; }' . 
          '.ui-state-default { border: 1px solid #d3d3d3; background: #e6e6e6 url(' . $self->{fileFWSPath} . '/jquery/ui-1.8.9/images/ui-bg_glass_75_e6e6e6_1x400.png) 50% 50% repeat-x; font-weight: normal; color: #555555; }' . 
          '.FWSAdminLoginLeft { float: left; text-align: left; }' . 
          '.FWSAdminLoginRight { float: right; text-align: left; }' . 
          '.FWSAdminLoginContainer { margin: 170px auto; width: 581px; border: solid 1px; }' . 
          '#FWSAdminLogin h2 {  font-size: 24px; color: #f78d1d; font-weight: 800; }'.
          '#FWSAdminLogin { text-align: left; padding: 2px 57px 50px; background: #ddd; }' . 
          '#FWSAdminLogin { text-align: center; }'.
          '#FWSAdminLoginUser, #FWSAdminLoginPassword { overflow:visible; width: 224px; padding: 3px; height: 20px; border-color: #AAAAAA #C8C8C8 #C8C8C8 #AAAAAA; border-style: solid; border-width: 1px; font-size: 12px; }' . 
          '.FWSAdminLoginContainer #FWSAdminLogin label { color: #333333; font-weight: bold; font-size: 12px; }' . 
          '.FWSAdminLoginLegal { background: #fff; padding: 8px 8px 5px; margin: 0; border-top: dashed 1px; font-size: 10px; }' . 
          '.FWSAdminLoginContainer .FWSAdminLoginBottom { height: 5px; width: 581px; overflow: hidden; background: #fff; }' . 
          '.FWSAdminLoginButton { float: right; margin-top: 10px; cursor: pointer; padding: 5px 20px; text-shadow: 0 1px 1px rgba(0,0,0,.3); -webkit-border-radius: 5px; -moz-border-radius: 5px; border-radius: 5px; -webkit-box-shadow: 0 1px 2px rgba(0,0,0,.2); -moz-box-shadow: 0 1px 2px rgba(0,0,0,.2); box-shadow: 0 1px 2px rgba(0,0,0,.2); color: #fef4e9; border: solid 1px #da7c0c; background: #f78d1d; background: -webkit-gradient(linear, left top, left bottom, from(#faa51a), to(#f47a20)); background: -moz-linear-gradient(top,  #faa51a,  #f47a20); } ' . 
          '.clear { clear: both; }' . 
        '</style>';

}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Format


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

1; # End of FWS::V2::Format
