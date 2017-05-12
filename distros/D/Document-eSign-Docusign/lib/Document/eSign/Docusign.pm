package Document::eSign::Docusign;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Document::eSign::Docusign - Provides an interface for Perl to the Docusign REST API.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';
our @apicalls = qw{
    login                           updatePassword
    getToken                        getTokenOnBehalfOf
    revokeToken                     requestSignatureFromTemplate
    requestSignatureFromDocument    requestSignatureFromComposite
    changeEnvelopeStatus            putDocumentDraftEnvelope
    createRecipientDraftEnvelope    openDocusignConsoleView
    openDocusignCorrectEnvelopeView openDocusignSenderView
    openDocusignRecipientView       getStatusSinceDate
    getStatusSinceDateUsingChangeType getStatusRangeDateUsingChangeType
    getSearchFolders                getEnvelope
    getListOfEnvelopesInFolders
    getEnvelopeRecipients           addEnvelopeRecipients
    editEnvelopeRecipients          deleteEnvelopeRecipient
    getRecipientTabs                createRecipientTabs
    modifyExistingRecipientTabs     getEnvelopeAssets
    getEnvelopeDocument             getCombinedEnvelopeDocuments
    deleteEnvelopeDocument          getListOfTemplates
    getUserProfile                  updateUserProfile
    getUserProfileImage             updateUserProfileImage
    deleteUserProfileImage          getSignatures
    createUpdateSignatureName       deleteSignatureName
    getSignatureImage               updateSignatureImage
    getSignatureInitials            updateSignatureInitials
    deleteSignatureImage            deleteInitialsImage
    getUserSettings                 updateUserSettings
    getSocialInformation            putSocialInformation
    deleteSocialInformation         getAccountProvisioning
    createAccount                   getAccountInfo
    getBillingPlanForAccount        deleteAccount
    viewFolders                     getFolderItems
    moveEnvelopeToFolder            getRecipientNames
    getAccountSettings              getAccountCustomFields
    getAccountTemplates             getAccountTemplatesById
    getAccountPermissionProfile     createGroup
    getAccountGroup                 getAccountUserList
    addUsersToAccount               deleteUsersFromAccount
    getUnsupportedFileTypes         postBrands
    getBrands                       deleteBrands
    distributorGetBillingPlans      distributorGetBillingPlanById
    getConnectConfiguration         getConnectConfigurationById
    postConnectionConfiguration     putConnectConfiguration
    deleteConnectConfiguration      getConnectLog
    getConnectLogById               getConnectFailuresLog
    getConnectFailureLogById        deleteConnectLogs
    deleteConnectLogById            deleteConnectFailureLogById
    putEnvelopesInRetryQueue        putEnvelopeInRetryQueueById
    buildCredentials                sendRequest
};

=head1 SYNOPSIS

This module supplies Perl centric methods for accessing the Docusign API.

Example:

    use Document::eSign::Docusign;

    my $ds = Document::eSign::Docusign->new(
        baseUrl => 'https://demo.docusign.net/restapi',
        username => 'username@domain.com',
        password => 'yourloginpassword',
        integratorkey => 'yourintegratorkeyfromdocusign'
    );
    
    # The API has already called the "Login" portion of the API, you're ready to go:
    
    my $response = $ds->requestSignatureFromTemplate(
        accountId => $ds->accountId, # Note that this is actually redundant.
        emailSubject => 'You have a document to sign from ACME.com.',
        emailBlurb => 'Here is the XYZ document for you to sign.',
        customFields => {
            textCustomFields => [
                name => 'FIELDNAME',
                value => 'value to place in field',
                show => 'true',
                required => 'true',
            ]
        },
        templateId => 'templateId',
        templateRoles => [
            {
                roleName     => 'Signer1', # Description of the signer's role
                name => 'Jane Smith',
                email => 'jsmith@somedomain.com'
            }, # Note that this is a list, so adding more roles creates more signatures.
        ],
        status => 'created', # One of sent or created.
        eventNotification => {}, # Large object, see API docs for details.
        
        
    );
    
    if ( defined $response->{error} ) {
        die "Uh oh, we had an error: " . $response->{error};
    }
    
    ...

=head1 SUBROUTINES/METHODS

=head2 new

Sets up the connection to Docusign and performs the login function. You will need
to pass parameters, at a minimum the call should contain the following properties:

=head3 username

Should be set to your username for Docusign

=head3 baseUrl

Should be set to https://demo.docusign.net/restapi at a minimum. Ultimately will be
overwritten after login. The login call specifies the baseUrl that becomes the
default.

=head3 password

Your API password, same as your login password.

=head3 integratorkey

Assigned to you through Docusign's demo site.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %vars = @_;
    
    while ( my ($key, $value) = each %vars  ) {
        eval { $self->$key($value) };
    }
    
    $self->defaultUrl($self->baseUrl);
    
    $self->login(
        {api_password => 'true',
        include_account_id_guid => 'true',
        login_settings => ''}
    );
    
    return $self;
}

=head2 API Calls

This module attempts to stay true to the intent of the original API interface and
simply supplies an OO interface in perl to abstract the need to construct JSON and
web calls. It also uses all of the standard perl modules around these. Below is the
list of all of the calls. Simply using "perldoc Document::eSign::Docusign::apiCall"
will supply you with the examples for each of the calls. Each call returns a hashref
that contains the response JSON from Docusign. Errors are passed back with a single
reference $response->{error}. This will contain the status code and error as returned
from the webservice. Calls that are not yet implemented are marked with a *.

    updatePassword
    getToken
    getTokenOnBehalfOf
    revokeToken
    requestSignatureFromTemplate
    requestSignatureFromDocument
    requestSignatureFromComposite*
    changeEnvelopeStatus
    putDocumentDraftEnvelope*
    createRecipientDraftEnvelope*
    openDocusignConsoleView*
    openDocusignCorrectEnvelopeView*
    openDocusignSenderView*
    openDocusignRecipientView*
    getStatusSinceDate*
    getStatusSinceDateUsingChangeType*
    getStatusRangeDateUsingChangeType*
    getSearchFolders*
    getListOfEnvelopesInFolders
    getEnvelope*
    getEnvelopeRecipients
    addEnvelopeRecipients*
    editEnvelopeRecipients*
    deleteEnvelopeRecipient*
    getRecipientTabs
    createRecipientTabs*
    modifyExistingRecipientTabs*
    getEnvelopeAssets*
    getEnvelopeDocument*
    getCombinedEnvelopeDocuments*
    deleteEnvelopeDocument*
    getListOfTemplates*
    getUserProfile*
    updateUserProfile*
    getUserProfileImage*
    updateUserProfileImage*
    deleteUserProfileImage*
    getSignatures*
    createUpdateSignatureName*
    deleteSignatureName*
    getSignatureImage*
    updateSignatureImage*
    getSignatureInitials*
    updateSignatureInitials*
    deleteSignatureImage*
    deleteInitialsImage*
    getUserSettings*
    updateUserSettings*
    getSocialInformation*
    putSocialInformation*
    deleteSocialInformation*
    getAccountProvisioning*
    createAccount*
    getAccountInfo*
    getBillingPlanForAccount*
    deleteAccount*
    viewFolders*
    getFolderItems*
    moveEnvelopeToFolder*
    getRecipientNames*
    getAccountSettings*
    getAccountCustomFields*
    getAccountTemplates*
    getAccountTemplatesById*
    getAccountPermissionProfile*
    createGroup*
    getAccountGroup*
    getAccountUserList*
    addUsersToAccount*
    deleteUsersFromAccount*
    getUnsupportedFileTypes*
    postBrands*
    getBrands*
    deleteBrands*
    distributorGetBillingPlans*
    distributorGetBillingPlanById*
    getConnectConfiguration*
    getConnectConfigurationById*
    postConnectionConfiguration*
    putConnectConfiguration*
    deleteConnectConfiguration*
    getConnectLog*
    getConnectLogById*
    getConnectFailuresLog*
    getConnectFailureLogById*
    deleteConnectLogs*
    deleteConnectLogById*
    deleteConnectFailureLogById*
    putEnvelopesInRetryQueue*
    putEnvelopeInRetryQueueById*

=cut

sub AUTOLOAD {
    my $self = shift;
    
    our $AUTOLOAD;
    
    (my $method = $AUTOLOAD ) =~ s/.*:://;
    
    # Is the method part of an API call?
    
    if ( grep $_ eq $method, @apicalls ) {
        my $module = __PACKAGE__ . "::" . $method;
        my $direct = $module;
        $direct =~ s/::/\//g;
        for ( @INC ) {
            if ( -f $_ . '/' . $direct . ".pm") {
                $direct = $_ . '/' . $direct . '.pm';
                last;
            }
            
        }
        
        unless ( $direct =~ /.pm/ ) {
            return "Unimplemented. :(";
        }
        
        
        eval {
            require $direct;
            $module->import();
        };
        
        return $module->new($self, @_);
    }
    
    # Nope, must be a getter/setter.
    
    my $value = shift;
    
    $method = lc $method;
    
    if ( defined $value ) {
        $self->{args}->{$method} = $value;
    }
    
    
    return $self->{args}->{$method};
    
}

=head1 AUTHOR

 Tyler Hardison, <tyler at seraph-net.net>
 Gavin Henry, <ghenry at surevoip.co.uk>, Suretec Systems Ltd. T/A SureVoIP.

=head1 BUGS

Please report any bugs or feature requests to C<bug-document-esign-docusign at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Document-eSign-Docusign>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Document::eSign::Docusign


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Document-eSign-Docusign>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Document-eSign-Docusign>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Document-eSign-Docusign>

=item * Search CPAN

L<http://search.cpan.org/dist/Document-eSign-Docusign/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

 Copyright 2013 Tyler Hardison.
 Copyright 2017 Gavin Henry, Suretec Systems Ltd. T/A SureVoIP.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Document::eSign::Docusign
