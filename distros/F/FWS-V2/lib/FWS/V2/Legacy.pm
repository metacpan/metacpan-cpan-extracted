package FWS::V2::Legacy;

use 5.006;
use strict;
use warnings;

=head1 NAME

FWS::V2::Legacy - Framework Sites version 2 compatibility and legacy methods and translations

=head1 VERSION

Version 1.13091122

=cut

our $VERSION = '1.13091122';


=head1 SYNOPSIS

    use FWS::V2;

    my $fws = FWS::V2->new();

    $fws->domain('http://www.mynewdomain.com');
    $fws->secureDomain('https://www.mynewdomain.com');
    ...


=head1 DESCRIPTION

FWS version 2 legacy methods are here for compatibility from upgrade paths of 1.3 and will not be present in the next version of FWS.   Most of the methods are deprecated for the most part because they are get/set subroutines that allow you to change something that you should not change after new() is called.   In a worst case scenario if you REALLY needed to change a setting you could access it via $fws->{thesetting} = 'something' instead.

=head1 METHODS

=head2 addExtraHash

This was renamed to mergeExtra().

=cut

sub addExtraHash {
    my ( $self, $extraValue, %addHash ) = @_;
    return $self->mergeExtra( $extraValue, %addHash );
}


=head2 adminLoginId

Should NEVER be set manually, it will be set during processLogin().  Will return the current admin user logged in.  If it is blank then no admin user is logged in and can be accessed via $fws->{adminLoginId};

=cut

sub adminLoginId {
    my ( $self, $adminLoginId ) = @_;
    if ( $adminLoginId ) { $self->{adminLoginId} = $adminLoginId }
    return $self->{adminLoginId};
}

=head2 adminPageId

The default value is set to 'admin', which would be accessed via yourdomain.com/admin.  Should be set when calling new(adminURL=>'admin') and can be accessed via $fws->{adminURL};

=cut

sub adminPageId {
    my ( $self, $adminPageId ) = @_;
    if ( $adminPageId ) { $self->{adminURL} = $adminPageId }
    return $self->{adminURL};
}

=head2 adminPassword

Should be set when calling new().  This is only used for internal security for the first time log in, and is disabled once an admin account is created.

=cut

sub adminPassword {
    my ( $self, $adminPassword ) = @_;
    if ( $adminPassword ) { $self->{adminPassword} = $adminPassword }
    return $self->{adminPassword};
}


=head2 affiliateId

Is set by passing 'a' as a form value. Can be accessed via $fws->{affiliateId};

=cut

sub affiliateId {
    my ( $self, $affiliateId ) = @_;
    if ( $affiliateId ) { $self->{affiliateId} = $affiliateId }
    return $self->{affiliateId};
}

=head2 ajaxEnable

Deprecated here for backwards compatibility in code.

=cut

sub ajaxEnable {
    my ( $self ) = @_;
    return '';
}

=head2 cookieDomainName

Should be set when calling new() and can be accessed via $fws->{cookieDomainName};

=cut

sub cookieDomainName {
    my ( $self, $cookieDomainName ) = @_;
    if ( $cookieDomainName ) { $self->{cookieDomainName} = $cookieDomainName }
    return $self->{cookieDomainName};
}

=head2 email

Is set when calling setSiteValues() and can be accessed via $fws->{email};

=cut

sub email {
    my ( $self, $email ) = @_;
    if ( $email ) { $self->{email} = $email }
    return $self->{email};
}


=head2 dataCacheFields

Deprecated. Internal only but was exported at one point so it is here for compatability

=cut

sub dataCacheFields {
    my ( $self, %dataCacheFields ) = @_;
    if (keys %dataCacheFields) { %{$self->{dataCacheFields}} = %dataCacheFields }
    return %{$self->{dataCacheFields}};
}

=head2 debug

Deprecated. All logging is handled via $fws->FWSLog.

=cut

sub debug {
    my ( $self ) = @_;
    return '';
}

=head2 domain

Should be set when calling new() and can be accessed via $fws->{domain};

=cut

sub domain {
    my ( $self, $domain ) = @_;
    if ( $domain ) { $self->{domain} = $domain }
    return $self->{domain};
}

=head2 encryptionKey

Should be set when calling new() and can be accessed via $fws->{encryptionKey};

=cut

sub encryptionKey {
    my ( $self, $encryptionKey ) = @_;
    if ( $encryptionKey ) { $self->{encryptionKey} = $encryptionKey }
    return $self->{encryptionKey};
}

=head2 encryptionType

Should be set when calling new() and can be accessed via $fws->{encryptionType};

=cut

sub encryptionType {
    my ( $self, $encryptionType ) = @_;
    if ( $encryptionType ) { $self->{encryptionType} = $encryptionType }
    return $self->{encryptionType};
}

=head2 fileDir

Should be set when calling new() and can be accessed via $fws->{fileDir};

=cut

sub fileDir {
    my ( $self, $fileDir ) = @_;
    if ( $fileDir ) { $self->{fileDir} = $fileDir }
    return $self->{fileDir};
}


=head2 filePackagePath

Deprecated.  This is set during siteSiteValues().Should be set when calling new() and can be accessed via $fws->{fileFWSPath};

=cut

sub filePackagePath {
    my ( $self, $filePackagePath ) = @_;
    if ( $filePackagePath ) { $self->{fileFWSPath} = $filePackagePath }
    return $self->{fileFWSPath};
}

=head2 filePath

Should be set when calling new() and can be accessed via $fws->{filePath};

=cut

sub filePath {
    my ( $self, $filePath ) = @_;
    if ( $filePath ) { $self->{filePath} = $filePath }
    return $self->{filePath};
}

=head2 fileSecurePath

Should be set when calling new() and can be accessed via $fws->{fileSecurePath};

=cut

sub fileSecurePath {
    my ( $self, $fileSecurePath ) = @_;
    if ( $fileSecurePath ) { $self->{fileSecurePath} = $fileSecurePath }
    return $self->{fileSecurePath};
}

=head2 fileStagingPath

Deprecated, V2 does not have built in staging control.  Staging is handled by an external methodology.

=cut

sub fileStagingPath {
    my ( $self ) = @_;
    return $self->{filePath};
}

=head2 fileWebPath

Should be set when calling new() and can be accessed via $fws->{fileWebPath};

=cut

sub fileWebPath {
    my ( $self, $fileWebPath ) = @_;
    if ( $fileWebPath ) { $self->{fileWebPath} = $fileWebPath }
    return $self->{fileWebPath};
}

=head2 fileWebStagingPath

Deprecated, V2 does not have built in staging control.  Staging is handled by an external methodology.

=cut

sub fileWebStagingPath {
    my ( $self ) = @_;
    return $self->{fileWebPath};
}

=head2 gatewayType

Is set with the administration and normally not accessed outside of the core.   Can be accessed via $fws->{gatewayType};

=cut

sub gatewayType {
    my ( $self, $gatewayType ) = @_;
    if ( $gatewayType ) { $self->{gatewayType} = $gatewayType }
    return $self->{gatewayType};
}

=head2 gatewayUserID

Is set with the administration and normally not accessed outside of the core.   Can be accessed via $fws->{gatewayUserId};

=cut

sub gatewayUserID {
    my ( $self, $gatewayUserID ) = @_;
    if ( $gatewayUserID ) { $self->{gatewayUserID} = $gatewayUserID }
    return $self->{gatewayUserID};
}

=head2 googleAppsKeyFile

Should be set when calling new() and can be accessed via $fws->{googleAppsKeyFile};

=cut

sub googleAppsKeyFile {
    my ( $self, $googleAppsKeyFile ) = @_;
    if ( $googleAppsKeyFile ) { $self->{googleAppsKeyFile} = $googleAppsKeyFile }
    return $self->{googleAppsKeyFile};
}


=head2 getPageGUID

This is depricated.  To get this value you can retrieve it from the dataHash or dataArray under the pageGUID key.

=cut

sub getPageGUID {
    my ( $self, $guid, $depth ) = @_;

    my ( $pageGUID ) = @{$self->runSQL( SQL => "select page_guid from data where guid='" . $self->safeSQL( $guid ) . "'" )};

    $pageGUID ||= $self->_setPageGUID( guid => $guid, depth => $depth );

    return $pageGUID;
}


=head2 navigationHref

Deprecated, use navigationLink() and add hrefOnly flag.

=cut

sub navigationHref {
    my ( $self, %hrefHash ) = @_;
    $hrefHash{hrefOnly} = 1;
    return $self->navigationLink(%hrefHash);
}


=head2 newDBCheck

Renamed to createFWSDatabase().

=cut

sub newDBCheck {
    my ( $self ) = @_;
    $self->createFWSDatabase();
}


=head2 phone

Deprecated, use formatPhone()

=cut

sub phone {
    my ( $self, %paramHash ) = @_;
    return $self->formatPhone(%paramHash);
}


=head2 processDownloads

Deprecated, all downloads are handled by the rendering element.

=cut

sub processDownloads {
    return 1;
}


=head2 siteGlobalValue

Deprecated, use siteValue()

=cut

sub siteGlobalValue {
    my ( $self, $key, $value ) = @_;
    return $self->siteValue( $key, $value );
}


=head2 skipIpCheckOnLogin

Deprecated, session management was updated to improve ip checking to make this no longer required.

=cut

sub skipIpCheckOnLogin {
    my ( $self ) = @_;
    return 0;
}


=head2 dateTime

Deprecated, use formatDate()

=cut

sub dateTime {
    my (  $self, %paramHash ) = @_;
    return $self->formatDate( %paramHash );
}


=head2 showDateTime

Deprecated, use formatDate()

=cut

sub showDateTime {
    my $self;
    my %paramHash;
    ( $self, $paramHash{format}, $paramHash{monthMod}, $paramHash{epochTime}, $paramHash{GMTOffset}, $paramHash{SQLTime} ) = @_;
    return $self->formatDate(%paramHash);
}

=head2 tinyMCEHead

Deprecated, built into the fws-2.x.css

=cut

sub tinyMCEHead {
    my ( $self ) = @_;
    return '';
}


=head2 truncatePhrase

Deprecated, use truncateContent()

=cut

sub truncatePhrase {
    my ( $self, $theString, $maxLength ) = @_;
    return $self->truncateContent( content => $theString, length => $maxLength );
}

=head2 pageIdOfElement

Method name changed, use $fws->getPageGUID('theguid')

=cut

sub pageIdOfElement {
    my ( $self, $guid ) = @_;
    return $self->getPageGUID( $guid );
}


=head2 getFormValues {

Renamed to setFormValues()

=cut

sub getFormValues {
    my ( $self ) = @_;
    return $self->setFormValues();
}


=head2 getPluginVersion

Single extraction of version replaced by pluginInfo()

=cut

sub getPluginVersion {
    my ( $self, $pluginFile ) = @_;
    my %pluginInfo = $self->pluginInfo( $pluginFile );
    return $pluginInfo{version};
}


=head2 guidKey

Deprecated, no longer needed with V2 security models

=cut

sub guidKey {
    my ( $self ) = @_;
    return;
}


=head2 initActions

Deprecated, no longer needed with V2 work flow models

=cut

sub initActions {
    my ( $self ) = @_;
    return;
}


=head2 isStaging

Deprecated.

=cut

sub isStaging { return 1 }


=head2 openRS

Depricated, use runSQL instead.

=cut

sub openRS {
    my ( $self, $SQL ) = @_;
    return @{$self->runSQL( SQL => $SQL )};
}


=head2 postHTTP

Depricated, use HTTPRequest instead.

=cut

sub postHTTP {
    my ( $self, %paramHash ) = @_;
    my $res = $self->HTTPRequest( %paramHash );
    if ( $res->{success} ) { return ( $res->{content}, 1 ) }
    else { return ( $res->{status}, 0 ) }
}


=head2 resizeImage

Depricated, use saveImage instead.

=cut

sub resizeImage {
    my ( $self, $origFile, $newFile, $newWidth, $newHeight ) = @_;
    return $self->saveImage( sourceFile => $origFile, fileName => $newFile, width => $newWidth, height => $newHeight );
}


=head2 runSiteActions

Depricated, all site actions are in plugins or elements

=cut

sub runSiteActions {
    return '';
}


=head2 scriptName

Should be set when calling new() and can be accessed via $fws->{scriptName};

=cut

sub scriptName {
    my ( $self, $scriptName ) = @_;
    if ( $scriptName ) { $self->{scriptName} = $scriptName }
    return $self->{scriptName};
}

=head2 secureDomain

Should be set when calling new() and can be accessed via $fws->{secureDomain};

=cut

sub secureDomain {
    my ( $self, $secureDomain ) = @_;
    if ( $secureDomain ) { $self->{secureDomain} = $secureDomain }
    return $self->{secureDomain};
}

=head2 securePageHash

Depricated.  All secure page references are done manually for performance and unique logic restrictions.

=cut

sub securePageHash {
    my ( $self ) = @_;
    return ();
}


=head2 sendMailBin

Should be set when calling new() and can be accessed via $fws->{sendmailBin};

=cut

sub sendMailBin  {
    my ( $self, $sendmailBin ) = @_;
    if ( $sendmailBin ) { $self->{sendmailBin} = $sendmailBin }
    if ( !$self->{sendmailBin} ) { return "/usr/sbin/sendmail" }
    return $self->{sendmailBin};
}

=head2 sendMethod

Should be set when calling new() and can be accessed via $fws->{sendMethod};

=cut

sub sendMethod {
    my ( $self, $sendMethod ) = @_;
    if ( $sendMethod ) { $self->{sendMethod} = $sendMethod }
    return $self->{sendMethod};
}

=head2 siteGUID

Used to retreive the current site GUID. Can be accessed via $fws->{siteGUID};

=cut

sub siteGUID {
    my ( $self, $siteGUID ) = @_;
    if ( $siteGUID ) { $self->{siteGUID} = $siteGUID }
    return $self->{siteGUID};
}

=head2 siteId

Used to retreive the current site Id. Can be accessed via $fws->{siteId};

=cut

sub siteId {
    my ( $self, $siteId ) = @_;
    if ( $siteId ) { $self->{siteId} = $siteId }
    return $self->{siteId};
}

=head2 siteName

Used to retreive the current site GUID. Can be accessed via $fws->{siteName};

=cut

sub siteName {
    my ( $self, $siteName ) = @_;
    if ( $siteName ) { $self->{siteName} = $siteName }
    return $self->{siteName};
}

=head2 tinyMCEEnable

Should be set when calling new() and can be accessed via $fws->{tinyMCEEnable};

=cut

sub tinyMCEEnable {
    my ( $self, $tinyMCEEnable ) = @_;
    if ( $tinyMCEEnable ) { $self->{tinyMCEEnable} = $tinyMCEEnable }
    return $self->{tinyMCEEnable};
}


=head2 queryHead

Should be set when calling new() and can be accessed via $fws->{queryHead};

=cut

sub queryHead {
    my ( $self, $queryHead ) = @_;
    if ( $queryHead ) { $self->{queryHead} = $queryHead }
    return $self->{queryHead};
}

=head2 userLoginId

Should NEVER be set manually, it will be set during processLogin().  Will return the current site user logged in.  If it is blank then no site user is logged in and can be accessed via $fws->{userLoginId};

=cut

sub userLoginId {
    my ( $self, $userLoginId ) = @_;
    if ( $userLoginId ) { $self->{userLoginId} = $userLoginId }
    return $self->{userLoginId};
}


=head2 DBHost

Should be set when calling new() and can be accessed via $fws->{DBHost};

=cut

sub DBHost {
    my ( $self, $DBHost ) = @_;
    if ( $DBHost ) { $self->{DBHost} = $DBHost }
    return $self->{DBHost};
}

=head2 DBName

Should be set when calling new() and can be accessed via $fws->{DBName};

=cut

sub DBName {
    my ( $self, $DBName ) = @_;
    if ( $DBName ) { $self->{DBName} = $DBName }
    return $self->{DBName};
}

=head2 DBPassword

Should be set when calling new() and can be accessed via $fws->{DBPassword};

=cut

sub DBPassword {
    my ( $self, $DBPassword ) = @_;
    if ( $DBPassword ) { $self->{DBPassword} = $DBPassword }
    return $self->{DBPassword};
}

=head2 DBType

Should be set when calling new() and can be accessed via $fws->{DBType};

=cut

sub DBType {
    my ( $self, $DBType ) = @_;
    if ( $DBType ) { $self->{DBType} = $DBType }
    return $self->{DBType};
}

=head2 DBUser

Should be set when calling new() and can be accessed via $fws->{DBUser};

=cut

sub DBUser {
    my ( $self, $DBUser ) = @_;
    if ( $DBUser ) { $self->{DBUser} = $DBUser }
    return $self->{DBUser};
}

=head2 FWSLogLevel

Should be set when calling new() and can be accessed via $fws->{FWSLogLevel};

=cut

sub FWSLogLevel {
    my ( $self, $FWSLogLevel ) = @_;
    if ( $FWSLogLevel ) { $self->{FWSLogLevel} = $FWSLogLevel }
    return $self->{FWSLogLevel};
}

=head2 SQLLogLevel

Should be set when calling new() and can be accessed via $fws->{SQLLogLevel};

=cut

sub SQLLogLevel {
    my ( $self, $SQLLogLevel ) = @_;
    if ( $SQLLogLevel ) { $self->{SQLLogLevel} = $SQLLogLevel }
    return $self->{SQLLogLevel};
}


=head2 XMLNode

Node safe routine for XML replaced by safeXML

=cut

sub XMLNode {
    my ( $self, $XMLNode ) = @_;
    $XMLNode =~ s/&/&amp;/sxg;
    $XMLNode =~ s/\</&lt;/sxg;
    return $XMLNode;
}


=head2 CSVNode

Node safe routine for XML replaced by safeCSV

=cut

sub CSVNode {
    my ( $self, $CSVNode ) = @_;
    $CSVNode =~ s/(,|;)/ /sxg;
    $CSVNode =~ s/(\n|\r)//sxg;
    $CSVNode =~ s/^('|")//sxg;
    return $CSVNode;
}


=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::Legacy


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

1; # End of FWS::V2::Legacy
