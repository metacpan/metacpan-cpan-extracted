package ElasticEmail;

use 5.006;
use strict;
use warnings;

package Api;  
use LWP::UserAgent;
use File::Basename;

our $mainApi= new Api("00000000-0000-0000-0000-000000000000", 'example@email.com', 'https://api.elasticemail.com/v2/');

sub new
{
    my $class = shift;
    my $self = {
        apikey => shift,
        username => shift,
        url => shift,
    };
    bless $self, $class;
    return $self;
}
 
sub Request
{
    my ($self, $urlLocal, $requestType, $one_ref, $two_ref) = @_;
	  
	my @allTheData =  $one_ref ? @{$one_ref} : ();
	my @postFilesPaths = $two_ref ? @{$two_ref} : (); 
	  
	my $ua = LWP::UserAgent->new;
	  
	my $response;
	if ($requestType eq "GET"){
        my $fullURL = $self->{url}."/".$urlLocal."?apikey=".$self->{apikey};
        $response = $ua->get($fullURL);
	}
    elsif($requestType eq "POST"){
        my $fullURL = $self->{ url}."/".$urlLocal;
        my $num = 0;
        my $file;
        foreach $file(@postFilesPaths){
            my $localFileName = fileparse($file);
            my $fieldName = 'file'.$num;
			
            push(@{$allTheData[0]}, ($fieldName, [$file, $localFileName]));
		    $num++;
        }
        $response = $ua->post($fullURL, Content_Type => 'multipart/form-data', Content => @allTheData);
    }
    my $content  = $response->decoded_content();
    return $content;
} 



#
# Methods for managing your account and subaccounts.
#
package Api::Account;

        # Create new subaccount and provide most important data about it.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string email - Proper email address.
            # string password - Current password.
            # string confirmPassword - Repeat new password.
            # bool requiresEmailCredits - True, if account needs credits to send emails. Otherwise, false (default False)
            # bool enableLitmusTest - True, if account is able to send template tests to Litmus. Otherwise, false (default False)
            # bool requiresLitmusCredits - True, if account needs credits to send emails. Otherwise, false (default False)
            # int maxContacts - Maximum number of contacts the account can have (default 0)
            # bool enablePrivateIPRequest - True, if account can request for private IP on its own. Otherwise, false (default True)
            # bool sendActivation - True, if you want to send activation email to this account. Otherwise, false (default False)
            # string returnUrl - URL to navigate to after account creation (default None)
            # ApiTypes::SendingPermission? sendingPermission - Sending permission setting for account (default None)
            # bool? enableContactFeatures - True, if you want to use Advanced Tools.  Otherwise, false (default None)
            # string poolName - Private IP required. Name of the custom IP Pool which Sub Account should use to send its emails. Leave empty for the default one or if no Private IPs have been bought (default None)
            # int emailSizeLimit - Maximum size of email including attachments in MB's (default 10)
        # Returns string
    sub AddSubAccount
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        email => shift,
                        password => shift,
                        confirmPassword => shift,
                        requiresEmailCredits => shift,
                        enableLitmusTest => shift,
                        requiresLitmusCredits => shift,
                        maxContacts => shift,
                        enablePrivateIPRequest => shift,
                        sendActivation => shift,
                        returnUrl => shift,
                        sendingPermission => shift,
                        enableContactFeatures => shift,
                        poolName => shift,
                        emailSizeLimit => shift];
        return $Api::mainApi->Request('account/addsubaccount', "GET", \@params);
    }

        # Add email, template or litmus credits to a sub-account
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int credits - Amount of credits to add
            # string notes - Specific notes about the transaction
            # ApiTypes::CreditType creditType - Type of credits to add (Email or Litmus) (default ApiTypes.CreditType.Email)
            # string subAccountEmail - Email address of sub-account (default None)
            # string publicAccountID - Public key of sub-account to add credits to. Use subAccountEmail or publicAccountID not both. (default None)
    sub AddSubAccountCredits
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        credits => shift,
                        notes => shift,
                        creditType => shift,
                        subAccountEmail => shift,
                        publicAccountID => shift];
        return $Api::mainApi->Request('account/addsubaccountcredits', "GET", \@params);
    }

        # Change your email address. Remember, that your email address is used as login!
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string sourceUrl - URL from which request was sent.
            # string newEmail - New email address.
            # string confirmEmail - New email address.
    sub ChangeEmail
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        sourceUrl => shift,
                        newEmail => shift,
                        confirmEmail => shift];
        return $Api::mainApi->Request('account/changeemail', "GET", \@params);
    }

        # Create new password for your account. Password needs to be at least 6 characters long.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string currentPassword - Current password.
            # string newPassword - New password for account.
            # string confirmPassword - Repeat new password.
    sub ChangePassword
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        currentPassword => shift,
                        newPassword => shift,
                        confirmPassword => shift];
        return $Api::mainApi->Request('account/changepassword', "GET", \@params);
    }

        # Deletes specified Subaccount
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # bool notify - True, if you want to send an email notification. Otherwise, false (default True)
            # string subAccountEmail - Email address of sub-account (default None)
            # string publicAccountID - Public key of sub-account to delete. Use subAccountEmail or publicAccountID not both. (default None)
    sub DeleteSubAccount
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        notify => shift,
                        subAccountEmail => shift,
                        publicAccountID => shift];
        return $Api::mainApi->Request('account/deletesubaccount', "GET", \@params);
    }

        # Returns API Key for the given Sub Account.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string subAccountEmail - Email address of sub-account (default None)
            # string publicAccountID - Public key of sub-account to retrieve sub-account API Key. Use subAccountEmail or publicAccountID not both. (default None)
        # Returns string
    sub GetSubAccountApiKey
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        subAccountEmail => shift,
                        publicAccountID => shift];
        return $Api::mainApi->Request('account/getsubaccountapikey', "GET", \@params);
    }

        # Lists all of your subaccounts
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns List<ApiTypes::SubAccount>
    sub GetSubAccountList
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('account/getsubaccountlist', "GET", \@params);
    }

        # Loads your account. Returns detailed information about your account.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns ApiTypes::Account
    sub Load
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('account/load', "GET", \@params);
    }

        # Load advanced options of your account
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns ApiTypes::AdvancedOptions
    sub LoadAdvancedOptions
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('account/loadadvancedoptions', "GET", \@params);
    }

        # Lists email credits history
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns List<ApiTypes::EmailCredits>
    sub LoadEmailCreditsHistory
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('account/loademailcreditshistory', "GET", \@params);
    }

        # Lists litmus credits history
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns List<ApiTypes::LitmusCredits>
    sub LoadLitmusCreditsHistory
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('account/loadlitmuscreditshistory', "GET", \@params);
    }

        # Shows queue of newest notifications - very useful when you want to check what happened with mails that were not received.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns List<ApiTypes::NotificationQueue>
    sub LoadNotificationQueue
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('account/loadnotificationqueue', "GET", \@params);
    }

        # Lists all payments
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int limit - Maximum of loaded items.
            # int offset - How many items should be loaded ahead.
            # DateTime fromDate - Starting date for search in YYYY-MM-DDThh:mm:ss format.
            # DateTime toDate - Ending date for search in YYYY-MM-DDThh:mm:ss format.
        # Returns List<ApiTypes::Payment>
    sub LoadPaymentHistory
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        limit => shift,
                        offset => shift,
                        fromDate => shift,
                        toDate => shift];
        return $Api::mainApi->Request('account/loadpaymenthistory', "GET", \@params);
    }

        # Lists all referral payout history
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns List<ApiTypes::Payment>
    sub LoadPayoutHistory
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('account/loadpayouthistory', "GET", \@params);
    }

        # Shows information about your referral details
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns ApiTypes::Referral
    sub LoadReferralDetails
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('account/loadreferraldetails', "GET", \@params);
    }

        # Shows latest changes in your sending reputation
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int limit - Maximum of loaded items. (default 20)
            # int offset - How many items should be loaded ahead. (default 0)
        # Returns List<ApiTypes::ReputationHistory>
    sub LoadReputationHistory
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        limit => shift,
                        offset => shift];
        return $Api::mainApi->Request('account/loadreputationhistory', "GET", \@params);
    }

        # Shows detailed information about your actual reputation score
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns ApiTypes::ReputationDetail
    sub LoadReputationImpact
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('account/loadreputationimpact', "GET", \@params);
    }

        # Returns detailed spam check.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int limit - Maximum of loaded items. (default 20)
            # int offset - How many items should be loaded ahead. (default 0)
        # Returns List<ApiTypes::SpamCheck>
    sub LoadSpamCheck
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        limit => shift,
                        offset => shift];
        return $Api::mainApi->Request('account/loadspamcheck', "GET", \@params);
    }

        # Lists email credits history for sub-account
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string subAccountEmail - Email address of sub-account (default None)
            # string publicAccountID - Public key of sub-account to list history for. Use subAccountEmail or publicAccountID not both. (default None)
        # Returns List<ApiTypes::EmailCredits>
    sub LoadSubAccountsEmailCreditsHistory
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        subAccountEmail => shift,
                        publicAccountID => shift];
        return $Api::mainApi->Request('account/loadsubaccountsemailcreditshistory', "GET", \@params);
    }

        # Loads settings of subaccount
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string subAccountEmail - Email address of sub-account (default None)
            # string publicAccountID - Public key of sub-account to load settings for. Use subAccountEmail or publicAccountID not both. (default None)
        # Returns ApiTypes::SubAccountSettings
    sub LoadSubAccountSettings
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        subAccountEmail => shift,
                        publicAccountID => shift];
        return $Api::mainApi->Request('account/loadsubaccountsettings', "GET", \@params);
    }

        # Lists litmus credits history for sub-account
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string subAccountEmail - Email address of sub-account (default None)
            # string publicAccountID - Public key of sub-account to list history for. Use subAccountEmail or publicAccountID not both. (default None)
        # Returns List<ApiTypes::LitmusCredits>
    sub LoadSubAccountsLitmusCreditsHistory
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        subAccountEmail => shift,
                        publicAccountID => shift];
        return $Api::mainApi->Request('account/loadsubaccountslitmuscreditshistory', "GET", \@params);
    }

        # Shows usage of your account in given time.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # DateTime from - Starting date for search in YYYY-MM-DDThh:mm:ss format.
            # DateTime to - Ending date for search in YYYY-MM-DDThh:mm:ss format.
        # Returns List<ApiTypes::Usage>
    sub LoadUsage
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        from => shift,
                        to => shift];
        return $Api::mainApi->Request('account/loadusage', "GET", \@params);
    }

        # Manages your apikeys.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string apiKey - APIKey you would like to manage.
            # ApiTypes::APIKeyAction action - Specific action you would like to perform on the APIKey
        # Returns List<string>
    sub ManageApiKeys
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        apiKey => shift,
                        action => shift];
        return $Api::mainApi->Request('account/manageapikeys', "GET", \@params);
    }

        # Shows summary for your account.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns ApiTypes::AccountOverview
    sub Overview
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('account/overview', "GET", \@params);
    }

        # Shows you account's profile basic overview
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns ApiTypes::Profile
    sub ProfileOverview
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('account/profileoverview', "GET", \@params);
    }

        # Remove email, template or litmus credits from a sub-account
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # ApiTypes::CreditType creditType - Type of credits to add (Email or Litmus)
            # string notes - Specific notes about the transaction
            # string subAccountEmail - Email address of sub-account (default None)
            # string publicAccountID - Public key of sub-account to remove credits from. Use subAccountEmail or publicAccountID not both. (default None)
            # int? credits - Amount of credits to remove (default None)
            # bool removeAll - Remove all credits of this type from sub-account (overrides credits if provided) (default False)
    sub RemoveSubAccountCredits
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        creditType => shift,
                        notes => shift,
                        subAccountEmail => shift,
                        publicAccountID => shift,
                        credits => shift,
                        removeAll => shift];
        return $Api::mainApi->Request('account/removesubaccountcredits', "GET", \@params);
    }

        # Request a private IP for your Account
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int count - Number of items.
            # string notes - Free form field of notes
    sub RequestPrivateIP
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        count => shift,
                        notes => shift];
        return $Api::mainApi->Request('account/requestprivateip', "GET", \@params);
    }

        # Update sending and tracking options of your account.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # bool? enableClickTracking - True, if you want to track clicks. Otherwise, false (default None)
            # bool? enableLinkClickTracking - True, if you want to track by link tracking. Otherwise, false (default None)
            # bool? manageSubscriptions - True, if you want to display your labels on your unsubscribe form. Otherwise, false (default None)
            # bool? manageSubscribedOnly - True, if you want to only display labels that the contact is subscribed to on your unsubscribe form. Otherwise, false (default None)
            # bool? transactionalOnUnsubscribe - True, if you want to display an option for the contact to opt into transactional email only on your unsubscribe form. Otherwise, false (default None)
            # bool? skipListUnsubscribe - True, if you do not want to use list-unsubscribe headers. Otherwise, false (default None)
            # bool? autoTextFromHtml - True, if text BODY of message should be created automatically. Otherwise, false (default None)
            # bool? allowCustomHeaders - True, if you want to apply custom headers to your emails. Otherwise, false (default None)
            # string bccEmail - Email address to send a copy of all email to. (default None)
            # string contentTransferEncoding - Type of content encoding (default None)
            # bool? emailNotificationForError - True, if you want bounce notifications returned. Otherwise, false (default None)
            # string emailNotificationEmail - Specific email address to send bounce email notifications to. (default None)
            # string webNotificationUrl - URL address to receive web notifications to parse and process. (default None)
            # bool? webNotificationForSent - True, if you want to send web notifications for sent email. Otherwise, false (default None)
            # bool? webNotificationForOpened - True, if you want to send web notifications for opened email. Otherwise, false (default None)
            # bool? webNotificationForClicked - True, if you want to send web notifications for clicked email. Otherwise, false (default None)
            # bool? webNotificationForUnsubscribed - True, if you want to send web notifications for unsubscribed email. Otherwise, false (default None)
            # bool? webNotificationForAbuseReport - True, if you want to send web notifications for complaint email. Otherwise, false (default None)
            # bool? webNotificationForError - True, if you want to send web notifications for bounced email. Otherwise, false (default None)
            # string hubCallBackUrl - URL used for tracking action of inbound emails (default "")
            # string inboundDomain - Domain you use as your inbound domain (default None)
            # bool? inboundContactsOnly - True, if you want inbound email to only process contacts from your account. Otherwise, false (default None)
            # bool? lowCreditNotification - True, if you want to receive low credit email notifications. Otherwise, false (default None)
            # bool? enableUITooltips - True, if account has tooltips active. Otherwise, false (default None)
            # bool? enableContactFeatures - True, if you want to use Advanced Tools.  Otherwise, false (default None)
            # string notificationsEmails - Email addresses to send a copy of all notifications from our system. Separated by semicolon (default None)
            # string unsubscribeNotificationsEmails - Emails, separated by semicolon, to which the notification about contact unsubscribing should be sent to (default None)
            # string logoUrl - URL to your logo image. (default None)
            # bool? enableTemplateScripting - True, if you want to use template scripting in your emails {{}}. Otherwise, false (default True)
            # int? staleContactScore - (0 means this functionality is NOT enabled) Score, depending on the number of times you have sent to a recipient, at which the given recipient should be moved to the Stale status (default None)
            # int? staleContactInactiveDays - (0 means this functionality is NOT enabled) Number of days of inactivity for a contact after which the given recipient should be moved to the Stale status (default None)
        # Returns ApiTypes::AdvancedOptions
    sub UpdateAdvancedOptions
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        enableClickTracking => shift,
                        enableLinkClickTracking => shift,
                        manageSubscriptions => shift,
                        manageSubscribedOnly => shift,
                        transactionalOnUnsubscribe => shift,
                        skipListUnsubscribe => shift,
                        autoTextFromHtml => shift,
                        allowCustomHeaders => shift,
                        bccEmail => shift,
                        contentTransferEncoding => shift,
                        emailNotificationForError => shift,
                        emailNotificationEmail => shift,
                        webNotificationUrl => shift,
                        webNotificationForSent => shift,
                        webNotificationForOpened => shift,
                        webNotificationForClicked => shift,
                        webNotificationForUnsubscribed => shift,
                        webNotificationForAbuseReport => shift,
                        webNotificationForError => shift,
                        hubCallBackUrl => shift,
                        inboundDomain => shift,
                        inboundContactsOnly => shift,
                        lowCreditNotification => shift,
                        enableUITooltips => shift,
                        enableContactFeatures => shift,
                        notificationsEmails => shift,
                        unsubscribeNotificationsEmails => shift,
                        logoUrl => shift,
                        enableTemplateScripting => shift,
                        staleContactScore => shift,
                        staleContactInactiveDays => shift];
        return $Api::mainApi->Request('account/updateadvancedoptions', "GET", \@params);
    }

        # Update settings of your private branding. These settings are needed, if you want to use Elastic Email under your brand.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # bool enablePrivateBranding - True: Turn on or off ability to send mails under your brand. Otherwise, false (default False)
            # string logoUrl - URL to your logo image. (default None)
            # string supportLink - Address to your support. (default None)
            # string privateBrandingUrl - Subdomain for your rebranded service (default None)
            # string smtpAddress - Address of SMTP server. (default None)
            # string smtpAlternative - Address of alternative SMTP server. (default None)
            # string paymentUrl - URL for making payments. (default None)
    sub UpdateCustomBranding
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        enablePrivateBranding => shift,
                        logoUrl => shift,
                        supportLink => shift,
                        privateBrandingUrl => shift,
                        smtpAddress => shift,
                        smtpAlternative => shift,
                        paymentUrl => shift];
        return $Api::mainApi->Request('account/updatecustombranding', "GET", \@params);
    }

        # Update http notification URL.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string url - URL of notification.
            # string settings - Http notification settings serialized to JSON  (default None)
    sub UpdateHttpNotification
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        url => shift,
                        settings => shift];
        return $Api::mainApi->Request('account/updatehttpnotification', "GET", \@params);
    }

        # Update your profile.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string firstName - First name.
            # string lastName - Last name.
            # string address1 - First line of address.
            # string city - City.
            # string state - State or province.
            # string zip - Zip/postal code.
            # int countryID - Numeric ID of country. A file with the list of countries is available <a href="http://api.elasticemail.com/public/countries"><b>here</b></a>
            # string deliveryReason - Why your clients are receiving your emails. (default None)
            # bool marketingConsent - True if you want to receive newsletters from Elastic Email. Otherwise, false. (default False)
            # string address2 - Second line of address. (default None)
            # string company - Company name. (default None)
            # string website - HTTP address of your website. (default None)
            # string logoUrl - URL to your logo image. (default None)
            # string taxCode - Code used for tax purposes. (default None)
            # string phone - Phone number (default None)
    sub UpdateProfile
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        firstName => shift,
                        lastName => shift,
                        address1 => shift,
                        city => shift,
                        state => shift,
                        zip => shift,
                        countryID => shift,
                        deliveryReason => shift,
                        marketingConsent => shift,
                        address2 => shift,
                        company => shift,
                        website => shift,
                        logoUrl => shift,
                        taxCode => shift,
                        phone => shift];
        return $Api::mainApi->Request('account/updateprofile', "GET", \@params);
    }

        # Updates settings of specified subaccount
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # bool requiresEmailCredits - True, if account needs credits to send emails. Otherwise, false (default False)
            # int monthlyRefillCredits - Amount of credits added to account automatically (default 0)
            # bool requiresLitmusCredits - True, if account needs credits to send emails. Otherwise, false (default False)
            # bool enableLitmusTest - True, if account is able to send template tests to Litmus. Otherwise, false (default False)
            # int dailySendLimit - Amount of emails account can send daily (default 50)
            # int emailSizeLimit - Maximum size of email including attachments in MB's (default 10)
            # bool enablePrivateIPRequest - True, if account can request for private IP on its own. Otherwise, false (default False)
            # int maxContacts - Maximum number of contacts the account can have (default 0)
            # string subAccountEmail - Email address of sub-account (default None)
            # string publicAccountID - Public key of sub-account to update. Use subAccountEmail or publicAccountID not both. (default None)
            # ApiTypes::SendingPermission? sendingPermission - Sending permission setting for account (default None)
            # bool? enableContactFeatures - True, if you want to use Advanced Tools.  Otherwise, false (default None)
            # string poolName - Name of your custom IP Pool to be used in the sending process (default None)
    sub UpdateSubAccountSettings
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        requiresEmailCredits => shift,
                        monthlyRefillCredits => shift,
                        requiresLitmusCredits => shift,
                        enableLitmusTest => shift,
                        dailySendLimit => shift,
                        emailSizeLimit => shift,
                        enablePrivateIPRequest => shift,
                        maxContacts => shift,
                        subAccountEmail => shift,
                        publicAccountID => shift,
                        sendingPermission => shift,
                        enableContactFeatures => shift,
                        poolName => shift];
        return $Api::mainApi->Request('account/updatesubaccountsettings', "GET", \@params);
    }


#
# Managing attachments uploaded to your account.
#
package Api::Attachment;

        # Permanently deletes attachment file from your account
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # long attachmentID - ID number of your attachment.
    sub Delete
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        attachmentID => shift];
        return $Api::mainApi->Request('attachment/delete', "GET", \@params);
    }

        # Gets address of chosen Attachment
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string fileName - Name of your file.
            # long attachmentID - ID number of your attachment.
        # Returns File
    sub Get
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        fileName => shift,
                        attachmentID => shift];
        return $Api::mainApi->Request('attachment/get', "GET", \@params);
    }

        # Lists your available Attachments in the given email
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string msgID - ID number of selected message.
        # Returns List<ApiTypes::Attachment>
    sub List
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        msgID => shift];
        return $Api::mainApi->Request('attachment/list', "GET", \@params);
    }

        # Lists all your available attachments
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns List<ApiTypes::Attachment>
    sub ListAll
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('attachment/listall', "GET", \@params);
    }

        # Permanently removes attachment file from your account
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string fileName - Name of your file.
    sub Remove
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        fileName => shift];
        return $Api::mainApi->Request('attachment/remove', "GET", \@params);
    }

        # Uploads selected file to the server using http form upload format (MIME multipart/form-data) or PUT method. The attachments expire after 30 days.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # File attachmentFile - Content of your attachment.
        # Returns ApiTypes::Attachment
    sub Upload
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('attachment/upload', "POST", \@params, \@_);
    }


#
# Sending and monitoring progress of your Campaigns
#
package Api::Campaign;

        # Adds a campaign to the queue for processing based on the configuration
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # ApiTypes::Campaign campaign - Json representation of a campaign
        # Returns int
    sub Add
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        campaign => shift];
        return $Api::mainApi->Request('campaign/add', "GET", \@params);
    }

        # Copy selected campaign
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int channelID - ID number of selected Channel.
    sub Copy
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        channelID => shift];
        return $Api::mainApi->Request('campaign/copy', "GET", \@params);
    }

        # Delete selected campaign
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int channelID - ID number of selected Channel.
    sub Delete
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        channelID => shift];
        return $Api::mainApi->Request('campaign/delete', "GET", \@params);
    }

        # Export selected campaigns to chosen file format.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # IEnumerable<int> channelIDs - List of campaign IDs used for processing (default None)
            # ApiTypes::ExportFileFormats fileFormat -  (default ApiTypes.ExportFileFormats.Csv)
            # ApiTypes::CompressionFormat compressionFormat - FileResponse compression format. None or Zip. (default ApiTypes.CompressionFormat.EENone)
            # string fileName - Name of your file. (default None)
        # Returns ApiTypes::ExportLink
    sub Export
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        channelIDs => shift,
                        fileFormat => shift,
                        compressionFormat => shift,
                        fileName => shift];
        return $Api::mainApi->Request('campaign/export', "GET", \@params);
    }

        # List all of your campaigns
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string search - Text fragment used for searching. (default None)
            # int offset - How many items should be loaded ahead. (default 0)
            # int limit - Maximum of loaded items. (default 0)
        # Returns List<ApiTypes::CampaignChannel>
    sub List
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        search => shift,
                        offset => shift,
                        limit => shift];
        return $Api::mainApi->Request('campaign/list', "GET", \@params);
    }

        # Updates a previously added campaign.  Only Active and Paused campaigns can be updated.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # ApiTypes::Campaign campaign - Json representation of a campaign
        # Returns int
    sub Update
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        campaign => shift];
        return $Api::mainApi->Request('campaign/update', "GET", \@params);
    }


#
# SMTP and HTTP API channels for grouping email delivery.
#
package Api::Channel;

        # Manually add a channel to your account to group email
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string name - Descriptive name of the channel
        # Returns string
    sub Add
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        name => shift];
        return $Api::mainApi->Request('channel/add', "GET", \@params);
    }

        # Delete the channel.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string name - The name of the channel to delete.
    sub Delete
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        name => shift];
        return $Api::mainApi->Request('channel/delete', "GET", \@params);
    }

        # Export channels in CSV file format.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # IEnumerable<string> channelNames - List of channel names used for processing
            # ApiTypes::CompressionFormat compressionFormat - FileResponse compression format. None or Zip. (default ApiTypes.CompressionFormat.EENone)
            # string fileName - Name of your file. (default None)
        # Returns File
    sub ExportCsv
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        channelNames => shift,
                        compressionFormat => shift,
                        fileName => shift];
        return $Api::mainApi->Request('channel/exportcsv', "GET", \@params);
    }

        # Export channels in JSON file format.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # IEnumerable<string> channelNames - List of channel names used for processing
            # ApiTypes::CompressionFormat compressionFormat - FileResponse compression format. None or Zip. (default ApiTypes.CompressionFormat.EENone)
            # string fileName - Name of your file. (default None)
        # Returns File
    sub ExportJson
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        channelNames => shift,
                        compressionFormat => shift,
                        fileName => shift];
        return $Api::mainApi->Request('channel/exportjson', "GET", \@params);
    }

        # Export channels in XML file format.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # IEnumerable<string> channelNames - List of channel names used for processing
            # ApiTypes::CompressionFormat compressionFormat - FileResponse compression format. None or Zip. (default ApiTypes.CompressionFormat.EENone)
            # string fileName - Name of your file. (default None)
        # Returns File
    sub ExportXml
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        channelNames => shift,
                        compressionFormat => shift,
                        fileName => shift];
        return $Api::mainApi->Request('channel/exportxml', "GET", \@params);
    }

        # List all of your channels
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns List<ApiTypes::Channel>
    sub List
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('channel/list', "GET", \@params);
    }

        # Rename an existing channel.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string name - The name of the channel to update.
            # string newName - The new name for the channel.
        # Returns string
    sub Update
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        name => shift,
                        newName => shift];
        return $Api::mainApi->Request('channel/update', "GET", \@params);
    }


#
# Methods used to manage your Contacts.
#
package Api::Contact;

        # Activate contacts that are currently blocked.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # bool activateAllBlocked - Activate all your blocked contacts.  Passing True will override email list and activate all your blocked contacts. (default False)
            # IEnumerable<string> emails - Comma delimited list of contact emails (default None)
    sub ActivateBlocked
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        activateAllBlocked => shift,
                        emails => shift];
        return $Api::mainApi->Request('contact/activateblocked', "GET", \@params);
    }

        # Add a new contact and optionally to one of your lists.  Note that your API KEY is not required for this call.
            # string publicAccountID - Public key for limited access to your account such as contact/add so you can use it safely on public websites.
            # string email - Proper email address.
            # string[] publicListID - ID code of list (default None)
            # string[] listName - Name of your list. (default None)
            # string title - Title (default None)
            # string firstName - First name. (default None)
            # string lastName - Last name. (default None)
            # string phone - Phone number (default None)
            # string mobileNumber - Mobile phone number (default None)
            # string notes - Free form field of notes (default None)
            # string gender - Your gender (default None)
            # DateTime? birthDate - Date of birth in YYYY-MM-DD format (default None)
            # string city - City. (default None)
            # string state - State or province. (default None)
            # string postalCode - Zip/postal code. (default None)
            # string country - Name of country. (default None)
            # string organizationName - Name of organization (default None)
            # string website - HTTP address of your website. (default None)
            # int? annualRevenue - Annual revenue of contact (default None)
            # string industry - Industry contact works in (default None)
            # int? numberOfEmployees - Number of employees (default None)
            # ApiTypes::ContactSource source - Specifies the way of uploading the contact (default ApiTypes.ContactSource.ContactApi)
            # string returnUrl - URL to navigate to after account creation (default None)
            # string sourceUrl - URL from which request was sent. (default None)
            # string activationReturnUrl - The url to return the contact to after activation. (default None)
            # string activationTemplate -  (default None)
            # bool sendActivation - True, if you want to send activation email to this account. Otherwise, false (default True)
            # DateTime? consentDate - Date of consent to send this contact(s) your email. If not provided current date is used for consent. (default None)
            # string consentIP - IP address of consent to send this contact(s) your email. If not provided your current public IP address is used for consent. (default None)
            # Dictionary<string, string> field - Custom contact field like firstname, lastname, city etc. Request parameters prefixed by field_ like field_firstname, field_lastname  (default None)
            # string notifyEmail - Emails, separated by semicolon, to which the notification about contact subscribing should be sent to (default None)
        # Returns string
    sub Add
    {
        shift;
        my @params = [publicAccountID => shift,
                        email => shift,
                        publicListID => shift,
                        listName => shift,
                        title => shift,
                        firstName => shift,
                        lastName => shift,
                        phone => shift,
                        mobileNumber => shift,
                        notes => shift,
                        gender => shift,
                        birthDate => shift,
                        city => shift,
                        state => shift,
                        postalCode => shift,
                        country => shift,
                        organizationName => shift,
                        website => shift,
                        annualRevenue => shift,
                        industry => shift,
                        numberOfEmployees => shift,
                        source => shift,
                        returnUrl => shift,
                        sourceUrl => shift,
                        activationReturnUrl => shift,
                        activationTemplate => shift,
                        sendActivation => shift,
                        consentDate => shift,
                        consentIP => shift,
                        field => shift,
                        notifyEmail => shift];
        return $Api::mainApi->Request('contact/add', "GET", \@params);
    }

        # Manually add or update a contacts status to Abuse, Bounced or Unsubscribed status (blocked).
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string email - Proper email address.
            # ApiTypes::ContactStatus status - Name of status: Active, Engaged, Inactive, Abuse, Bounced, Unsubscribed.
    sub AddBlocked
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        email => shift,
                        status => shift];
        return $Api::mainApi->Request('contact/addblocked', "GET", \@params);
    }

        # Change any property on the contact record.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string email - Proper email address.
            # string name - Name of the contact property you want to change.
            # string value - Value you would like to change the contact property to.
    sub ChangeProperty
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        email => shift,
                        name => shift,
                        value => shift];
        return $Api::mainApi->Request('contact/changeproperty', "GET", \@params);
    }

        # Changes status of selected Contacts. You may provide RULE for selection or specify list of Contact IDs.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # ApiTypes::ContactStatus status - Name of status: Active, Engaged, Inactive, Abuse, Bounced, Unsubscribed.
            # string rule - Query used for filtering. (default None)
            # IEnumerable<string> emails - Comma delimited list of contact emails (default None)
            # bool allContacts - True: Include every Contact in your Account. Otherwise, false (default False)
    sub ChangeStatus
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        status => shift,
                        rule => shift,
                        emails => shift,
                        allContacts => shift];
        return $Api::mainApi->Request('contact/changestatus', "GET", \@params);
    }

        # Returns number of Contacts, RULE specifies contact Status.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string rule - Query used for filtering. (default None)
            # bool allContacts - True: Include every Contact in your Account. Otherwise, false (default False)
        # Returns ApiTypes::ContactStatusCounts
    sub CountByStatus
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        rule => shift,
                        allContacts => shift];
        return $Api::mainApi->Request('contact/countbystatus', "GET", \@params);
    }

        # Permanantly deletes the contacts provided.  You can provide either a qualified rule or a list of emails (comma separated string).
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string rule - Query used for filtering. (default None)
            # IEnumerable<string> emails - Comma delimited list of contact emails (default None)
            # bool allContacts - True: Include every Contact in your Account. Otherwise, false (default False)
    sub Delete
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        rule => shift,
                        emails => shift,
                        allContacts => shift];
        return $Api::mainApi->Request('contact/delete', "GET", \@params);
    }

        # Export selected Contacts to JSON.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # ApiTypes::ExportFileFormats fileFormat -  (default ApiTypes.ExportFileFormats.Csv)
            # string rule - Query used for filtering. (default None)
            # IEnumerable<string> emails - Comma delimited list of contact emails (default None)
            # bool allContacts - True: Include every Contact in your Account. Otherwise, false (default False)
            # ApiTypes::CompressionFormat compressionFormat - FileResponse compression format. None or Zip. (default ApiTypes.CompressionFormat.EENone)
            # string fileName - Name of your file. (default None)
        # Returns ApiTypes::ExportLink
    sub Export
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        fileFormat => shift,
                        rule => shift,
                        emails => shift,
                        allContacts => shift,
                        compressionFormat => shift,
                        fileName => shift];
        return $Api::mainApi->Request('contact/export', "GET", \@params);
    }

        # Finds all Lists and Segments this email belongs to.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string email - Proper email address.
        # Returns ApiTypes::ContactCollection
    sub FindContact
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        email => shift];
        return $Api::mainApi->Request('contact/findcontact', "GET", \@params);
    }

        # List of Contacts for provided List
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string listName - Name of your list.
            # int limit - Maximum of loaded items. (default 20)
            # int offset - How many items should be loaded ahead. (default 0)
        # Returns List<ApiTypes::Contact>
    sub GetContactsByList
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        listName => shift,
                        limit => shift,
                        offset => shift];
        return $Api::mainApi->Request('contact/getcontactsbylist', "GET", \@params);
    }

        # List of Contacts for provided Segment
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string segmentName - Name of your segment.
            # int limit - Maximum of loaded items. (default 20)
            # int offset - How many items should be loaded ahead. (default 0)
        # Returns List<ApiTypes::Contact>
    sub GetContactsBySegment
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        segmentName => shift,
                        limit => shift,
                        offset => shift];
        return $Api::mainApi->Request('contact/getcontactsbysegment', "GET", \@params);
    }

        # List of all contacts. If you have not specified RULE, all Contacts will be listed.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string rule - Query used for filtering. (default None)
            # bool allContacts - True: Include every Contact in your Account. Otherwise, false (default False)
            # int limit - Maximum of loaded items. (default 20)
            # int offset - How many items should be loaded ahead. (default 0)
        # Returns List<ApiTypes::Contact>
    sub List
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        rule => shift,
                        allContacts => shift,
                        limit => shift,
                        offset => shift];
        return $Api::mainApi->Request('contact/list', "GET", \@params);
    }

        # Load blocked contacts
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # IEnumerable<ApiTypes::ContactStatus> statuses - List of comma separated message statuses: 0 or all, 1 for ReadyToSend, 2 for InProgress, 4 for Bounced, 5 for Sent, 6 for Opened, 7 for Clicked, 8 for Unsubscribed, 9 for Abuse Report
            # string search - List of blocked statuses: Abuse, Bounced or Unsubscribed (default None)
            # int limit - Maximum of loaded items. (default 0)
            # int offset - How many items should be loaded ahead. (default 0)
        # Returns List<ApiTypes::BlockedContact>
    sub LoadBlocked
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        statuses => shift,
                        search => shift,
                        limit => shift,
                        offset => shift];
        return $Api::mainApi->Request('contact/loadblocked', "GET", \@params);
    }

        # Load detailed contact information
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string email - Proper email address.
        # Returns ApiTypes::Contact
    sub LoadContact
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        email => shift];
        return $Api::mainApi->Request('contact/loadcontact', "GET", \@params);
    }

        # Shows detailed history of chosen Contact.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string email - Proper email address.
            # int limit - Maximum of loaded items. (default 0)
            # int offset - How many items should be loaded ahead. (default 0)
        # Returns List<ApiTypes::ContactHistory>
    sub LoadHistory
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        email => shift,
                        limit => shift,
                        offset => shift];
        return $Api::mainApi->Request('contact/loadhistory', "GET", \@params);
    }

        # Add new Contact to one of your Lists.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # IEnumerable<string> emails - Comma delimited list of contact emails
            # string firstName - First name. (default None)
            # string lastName - Last name. (default None)
            # string title - Title (default None)
            # string organization - Name of organization (default None)
            # string industry - Industry contact works in (default None)
            # string city - City. (default None)
            # string country - Name of country. (default None)
            # string state - State or province. (default None)
            # string zip - Zip/postal code. (default None)
            # string publicListID - ID code of list (default None)
            # string listName - Name of your list. (default None)
            # ApiTypes::ContactStatus status - Name of status: Active, Engaged, Inactive, Abuse, Bounced, Unsubscribed. (default ApiTypes.ContactStatus.Active)
            # string notes - Free form field of notes (default None)
            # DateTime? consentDate - Date of consent to send this contact(s) your email. If not provided current date is used for consent. (default None)
            # string consentIP - IP address of consent to send this contact(s) your email. If not provided your current public IP address is used for consent. (default None)
            # string notifyEmail - Emails, separated by semicolon, to which the notification about contact subscribing should be sent to (default None)
    sub QuickAdd
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        emails => shift,
                        firstName => shift,
                        lastName => shift,
                        title => shift,
                        organization => shift,
                        industry => shift,
                        city => shift,
                        country => shift,
                        state => shift,
                        zip => shift,
                        publicListID => shift,
                        listName => shift,
                        status => shift,
                        notes => shift,
                        consentDate => shift,
                        consentIP => shift,
                        notifyEmail => shift];
        return $Api::mainApi->Request('contact/quickadd', "GET", \@params);
    }

        # Update selected contact. Omitted contact's fields will be reset by default (see the clearRestOfFields parameter)
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string email - Proper email address.
            # string firstName - First name. (default None)
            # string lastName - Last name. (default None)
            # string organizationName - Name of organization (default None)
            # string title - Title (default None)
            # string city - City. (default None)
            # string state - State or province. (default None)
            # string country - Name of country. (default None)
            # string zip - Zip/postal code. (default None)
            # string birthDate - Date of birth in YYYY-MM-DD format (default None)
            # string gender - Your gender (default None)
            # string phone - Phone number (default None)
            # bool? activate - True, if Contact should be activated. Otherwise, false (default None)
            # string industry - Industry contact works in (default None)
            # int numberOfEmployees - Number of employees (default 0)
            # string annualRevenue - Annual revenue of contact (default None)
            # int purchaseCount - Number of purchases contact has made (default 0)
            # string firstPurchase - Date of first purchase in YYYY-MM-DD format (default None)
            # string lastPurchase - Date of last purchase in YYYY-MM-DD format (default None)
            # string notes - Free form field of notes (default None)
            # string websiteUrl - Website of contact (default None)
            # string mobileNumber - Mobile phone number (default None)
            # string faxNumber - Fax number (default None)
            # string linkedInBio - Biography for Linked-In (default None)
            # int linkedInConnections - Number of Linked-In connections (default 0)
            # string twitterBio - Biography for Twitter (default None)
            # string twitterUsername - User name for Twitter (default None)
            # string twitterProfilePhoto - URL for Twitter photo (default None)
            # int twitterFollowerCount - Number of Twitter followers (default 0)
            # int pageViews - Number of page views (default 0)
            # int visits - Number of website visits (default 0)
            # bool clearRestOfFields - States if the fields that were omitted in this request are to be reset or should they be left with their current value (default True)
            # Dictionary<string, string> field - Custom contact field like firstname, lastname, city etc. Request parameters prefixed by field_ like field_firstname, field_lastname  (default None)
        # Returns ApiTypes::Contact
    sub Update
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        email => shift,
                        firstName => shift,
                        lastName => shift,
                        organizationName => shift,
                        title => shift,
                        city => shift,
                        state => shift,
                        country => shift,
                        zip => shift,
                        birthDate => shift,
                        gender => shift,
                        phone => shift,
                        activate => shift,
                        industry => shift,
                        numberOfEmployees => shift,
                        annualRevenue => shift,
                        purchaseCount => shift,
                        firstPurchase => shift,
                        lastPurchase => shift,
                        notes => shift,
                        websiteUrl => shift,
                        mobileNumber => shift,
                        faxNumber => shift,
                        linkedInBio => shift,
                        linkedInConnections => shift,
                        twitterBio => shift,
                        twitterUsername => shift,
                        twitterProfilePhoto => shift,
                        twitterFollowerCount => shift,
                        pageViews => shift,
                        visits => shift,
                        clearRestOfFields => shift,
                        field => shift];
        return $Api::mainApi->Request('contact/update', "GET", \@params);
    }

        # Upload contacts in CSV file.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # File contactFile - Name of CSV file with Contacts.
            # bool allowUnsubscribe - True: Allow unsubscribing from this (optional) newly created list. Otherwise, false (default False)
            # int? listID - ID number of selected list. (default None)
            # string listName - Name of your list to upload contacts to, or how the new, automatically created list should be named (default None)
            # ApiTypes::ContactStatus status - Name of status: Active, Engaged, Inactive, Abuse, Bounced, Unsubscribed. (default ApiTypes.ContactStatus.Active)
            # DateTime? consentDate - Date of consent to send this contact(s) your email. If not provided current date is used for consent. (default None)
            # string consentIP - IP address of consent to send this contact(s) your email. If not provided your current public IP address is used for consent. (default None)
        # Returns int
    sub Upload
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        allowUnsubscribe => shift,
                        listID => shift,
                        listName => shift,
                        status => shift,
                        consentDate => shift,
                        consentIP => shift];
        return $Api::mainApi->Request('contact/upload', "POST", \@params, \@_);
    }


#
# Managing sender domains. Creating new entries and validating domain records.
#
package Api::Domain;

        # Add new domain to account
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string domain - Name of selected domain.
            # ApiTypes::TrackingType trackingType -  (default ApiTypes.TrackingType.Http)
    sub Add
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        domain => shift,
                        trackingType => shift];
        return $Api::mainApi->Request('domain/add', "GET", \@params);
    }

        # Deletes configured domain from account
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string domain - Name of selected domain.
    sub Delete
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        domain => shift];
        return $Api::mainApi->Request('domain/delete', "GET", \@params);
    }

        # Lists all domains configured for this account.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns List<ApiTypes::DomainDetail>
    sub List
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('domain/list', "GET", \@params);
    }

        # Verification of email addres set for domain.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string domain - Default email sender, example: mail@yourdomain.com
    sub SetDefault
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        domain => shift];
        return $Api::mainApi->Request('domain/setdefault', "GET", \@params);
    }

        # Verification of DKIM record for domain
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string domain - Name of selected domain.
    sub VerifyDkim
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        domain => shift];
        return $Api::mainApi->Request('domain/verifydkim', "GET", \@params);
    }

        # Verification of MX record for domain
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string domain - Name of selected domain.
    sub VerifyMX
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        domain => shift];
        return $Api::mainApi->Request('domain/verifymx', "GET", \@params);
    }

        # Verification of SPF record for domain
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string domain - Name of selected domain.
    sub VerifySpf
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        domain => shift];
        return $Api::mainApi->Request('domain/verifyspf', "GET", \@params);
    }

        # Verification of tracking CNAME record for domain
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string domain - Name of selected domain.
            # ApiTypes::TrackingType trackingType -  (default ApiTypes.TrackingType.Http)
    sub VerifyTracking
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        domain => shift,
                        trackingType => shift];
        return $Api::mainApi->Request('domain/verifytracking', "GET", \@params);
    }


#
# 
#
package Api::Eksport;

        # Check the current status of the export.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # Guid publicExportID - 
        # Returns ApiTypes::ExportStatus
    sub CheckStatus
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        publicExportID => shift];
        return $Api::mainApi->Request('eksport/checkstatus', "GET", \@params);
    }

        # Summary of export type counts.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns ApiTypes::ExportTypeCounts
    sub CountByType
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('eksport/countbytype', "GET", \@params);
    }

        # Delete the specified export.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # Guid publicExportID - 
    sub Delete
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        publicExportID => shift];
        return $Api::mainApi->Request('eksport/delete', "GET", \@params);
    }

        # Returns a list of all exported data.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int limit - Maximum of loaded items. (default 0)
            # int offset - How many items should be loaded ahead. (default 0)
        # Returns List<ApiTypes::Export>
    sub List
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        limit => shift,
                        offset => shift];
        return $Api::mainApi->Request('eksport/list', "GET", \@params);
    }


#
# 
#
package Api::Email;

        # Get email batch status
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string transactionID - Transaction identifier
            # bool showFailed - Include Bounced email addresses. (default False)
            # bool showDelivered - Include Sent email addresses. (default False)
            # bool showPending - Include Ready to send email addresses. (default False)
            # bool showOpened - Include Opened email addresses. (default False)
            # bool showClicked - Include Clicked email addresses. (default False)
            # bool showAbuse - Include Reported as abuse email addresses. (default False)
            # bool showUnsubscribed - Include Unsubscribed email addresses. (default False)
            # bool showErrors - Include error messages for bounced emails. (default False)
            # bool showMessageIDs - Include all MessageIDs for this transaction (default False)
        # Returns ApiTypes::EmailJobStatus
    sub GetStatus
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        transactionID => shift,
                        showFailed => shift,
                        showDelivered => shift,
                        showPending => shift,
                        showOpened => shift,
                        showClicked => shift,
                        showAbuse => shift,
                        showUnsubscribed => shift,
                        showErrors => shift,
                        showMessageIDs => shift];
        return $Api::mainApi->Request('email/getstatus', "GET", \@params);
    }

        # Submit emails. The HTTP POST request is suggested. The default, maximum (accepted by us) size of an email is 10 MB in total, with or without attachments included. For suggested implementations please refer to https://elasticemail.com/support/http-api/
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string subject - Email subject (default None)
            # string from - From email address (default None)
            # string fromName - Display name for from email address (default None)
            # string sender - Email address of the sender (default None)
            # string senderName - Display name sender (default None)
            # string msgFrom - Optional parameter. Sets FROM MIME header. (default None)
            # string msgFromName - Optional parameter. Sets FROM name of MIME header. (default None)
            # string replyTo - Email address to reply to (default None)
            # string replyToName - Display name of the reply to address (default None)
            # IEnumerable<string> to - List of email recipients (each email is treated separately, like a BCC). Separated by comma or semicolon. We suggest using the "msgTo" parameter if backward compatibility with API version 1 is not a must. (default None)
            # string[] msgTo - Optional parameter. Will be ignored if the 'to' parameter is also provided. List of email recipients (visible to all other recipients of the message as TO MIME header). Separated by comma or semicolon. (default None)
            # string[] msgCC - Optional parameter. Will be ignored if the 'to' parameter is also provided. List of email recipients (visible to all other recipients of the message as CC MIME header). Separated by comma or semicolon. (default None)
            # string[] msgBcc - Optional parameter. Will be ignored if the 'to' parameter is also provided. List of email recipients (each email is treated seperately). Separated by comma or semicolon. (default None)
            # IEnumerable<string> lists - The name of a contact list you would like to send to. Separate multiple contact lists by commas or semicolons. (default None)
            # IEnumerable<string> segments - The name of a segment you would like to send to. Separate multiple segments by comma or semicolon. Insert "0" for all Active contacts. (default None)
            # string mergeSourceFilename - File name one of attachments which is a CSV list of Recipients. (default None)
            # string channel - An ID field (max 191 chars) that can be used for reporting [will default to HTTP API or SMTP API] (default None)
            # string bodyHtml - Html email body (default None)
            # string bodyText - Text email body (default None)
            # string charset - Text value of charset encoding for example: iso-8859-1, windows-1251, utf-8, us-ascii, windows-1250 and more… (default None)
            # string charsetBodyHtml - Sets charset for body html MIME part (overrides default value from charset parameter) (default None)
            # string charsetBodyText - Sets charset for body text MIME part (overrides default value from charset parameter) (default None)
            # ApiTypes::EncodingType encodingType - 0 for None, 1 for Raw7Bit, 2 for Raw8Bit, 3 for QuotedPrintable, 4 for Base64 (Default), 5 for Uue  note that you can also provide the text version such as "Raw7Bit" for value 1.  NOTE: Base64 or QuotedPrintable is recommended if you are validating your domain(s) with DKIM. (default ApiTypes.EncodingType.EENone)
            # string template - The name of an email template you have created in your account. (default None)
            # IEnumerableFile attachmentFiles - Attachment files. These files should be provided with the POST multipart file upload, not directly in the request's URL. Should also include merge CSV file (default None)
            # Dictionary<string, string> headers - Optional Custom Headers. Request parameters prefixed by headers_ like headers_customheader1, headers_customheader2. Note: a space is required after the colon before the custom header value. headers_xmailer=xmailer: header-value1 (default None)
            # string postBack - Optional header returned in notifications. (default None)
            # Dictionary<string, string> merge - Request parameters prefixed by merge_ like merge_firstname, merge_lastname. If sending to a template you can send merge_ fields to merge data with the template. Template fields are entered with {firstname}, {lastname} etc. (default None)
            # string timeOffSetMinutes - Number of minutes in the future this email should be sent (default None)
            # string poolName - Name of your custom IP Pool to be used in the sending process (default None)
            # bool isTransactional - True, if email is transactional (non-bulk, non-marketing, non-commercial). Otherwise, false (default False)
        # Returns ApiTypes::EmailSend
    sub Send
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        subject => shift,
                        from => shift,
                        fromName => shift,
                        sender => shift,
                        senderName => shift,
                        msgFrom => shift,
                        msgFromName => shift,
                        replyTo => shift,
                        replyToName => shift,
                        to => shift,
                        msgTo => shift,
                        msgCC => shift,
                        msgBcc => shift,
                        lists => shift,
                        segments => shift,
                        mergeSourceFilename => shift,
                        channel => shift,
                        bodyHtml => shift,
                        bodyText => shift,
                        charset => shift,
                        charsetBodyHtml => shift,
                        charsetBodyText => shift,
                        encodingType => shift,
                        template => shift,
                        headers => shift,
                        postBack => shift,
                        merge => shift,
                        timeOffSetMinutes => shift,
                        poolName => shift,
                        isTransactional => shift];
        return $Api::mainApi->Request('email/send', "POST", \@params, \@_);
    }

        # Detailed status of a unique email sent through your account. Returns a 'Email has expired and the status is unknown.' error, if the email has not been fully processed yet.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string messageID - Unique identifier for this email.
        # Returns ApiTypes::EmailStatus
    sub Status
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        messageID => shift];
        return $Api::mainApi->Request('email/status', "GET", \@params);
    }

        # View email
            # string messageID - Message identifier
        # Returns ApiTypes::EmailView
    sub View
    {
        shift;
        my @params = [messageID => shift];
        return $Api::mainApi->Request('email/view', "GET", \@params);
    }


#
# API methods for managing your Lists
#
package Api::List;

        # Create new list, based on filtering rule or list of IDs
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string listName - Name of your list.
            # bool createEmptyList - True to create an empty list, otherwise false. Ignores rule and emails parameters if provided. (default False)
            # bool allowUnsubscribe - True: Allow unsubscribing from this list. Otherwise, false (default False)
            # string rule - Query used for filtering. (default None)
            # IEnumerable<string> emails - Comma delimited list of contact emails (default None)
            # bool allContacts - True: Include every Contact in your Account. Otherwise, false (default False)
        # Returns int
    sub Add
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        listName => shift,
                        createEmptyList => shift,
                        allowUnsubscribe => shift,
                        rule => shift,
                        emails => shift,
                        allContacts => shift];
        return $Api::mainApi->Request('list/add', "GET", \@params);
    }

        # Add Contacts to chosen list
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string listName - Name of your list.
            # string rule - Query used for filtering. (default None)
            # IEnumerable<string> emails - Comma delimited list of contact emails (default None)
            # bool allContacts - True: Include every Contact in your Account. Otherwise, false (default False)
    sub AddContacts
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        listName => shift,
                        rule => shift,
                        emails => shift,
                        allContacts => shift];
        return $Api::mainApi->Request('list/addcontacts', "GET", \@params);
    }

        # Copy your existing List with the option to provide new settings to it. Some fields, when left empty, default to the source list's settings
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string sourceListName - The name of the list you want to copy
            # string newlistName - Name of your list if you want to change it. (default None)
            # bool? createEmptyList - True to create an empty list, otherwise false. Ignores rule and emails parameters if provided. (default None)
            # bool? allowUnsubscribe - True: Allow unsubscribing from this list. Otherwise, false (default None)
            # string rule - Query used for filtering. (default None)
        # Returns int
    sub Copy
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        sourceListName => shift,
                        newlistName => shift,
                        createEmptyList => shift,
                        allowUnsubscribe => shift,
                        rule => shift];
        return $Api::mainApi->Request('list/copy', "GET", \@params);
    }

        # Create a new list from the recipients of the given campaign, using the given statuses of Messages
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int campaignID - ID of the campaign which recipients you want to copy
            # string listName - Name of your list.
            # IEnumerable<ApiTypes::LogJobStatus> statuses - Statuses of a campaign's emails you want to include in the new list (but NOT the contacts' statuses) (default None)
        # Returns int
    sub CreateFromCampaign
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        campaignID => shift,
                        listName => shift,
                        statuses => shift];
        return $Api::mainApi->Request('list/createfromcampaign', "GET", \@params);
    }

        # Create a series of nth selection lists from an existing list or segment
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string listName - Name of your list.
            # int numberOfLists - The number of evenly distributed lists to create.
            # bool excludeBlocked - True if you want to exclude contacts that are currently in a blocked status of either unsubscribe, complaint or bounce. Otherwise, false. (default True)
            # bool allowUnsubscribe - True: Allow unsubscribing from this list. Otherwise, false (default False)
            # string rule - Query used for filtering. (default None)
            # bool allContacts - True: Include every Contact in your Account. Otherwise, false (default False)
    sub CreateNthSelectionLists
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        listName => shift,
                        numberOfLists => shift,
                        excludeBlocked => shift,
                        allowUnsubscribe => shift,
                        rule => shift,
                        allContacts => shift];
        return $Api::mainApi->Request('list/createnthselectionlists', "GET", \@params);
    }

        # Create a new list with randomized contacts from an existing list or segment
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string listName - Name of your list.
            # int count - Number of items.
            # bool excludeBlocked - True if you want to exclude contacts that are currently in a blocked status of either unsubscribe, complaint or bounce. Otherwise, false. (default True)
            # bool allowUnsubscribe - True: Allow unsubscribing from this list. Otherwise, false (default False)
            # string rule - Query used for filtering. (default None)
            # bool allContacts - True: Include every Contact in your Account. Otherwise, false (default False)
        # Returns int
    sub CreateRandomList
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        listName => shift,
                        count => shift,
                        excludeBlocked => shift,
                        allowUnsubscribe => shift,
                        rule => shift,
                        allContacts => shift];
        return $Api::mainApi->Request('list/createrandomlist', "GET", \@params);
    }

        # Deletes List and removes all the Contacts from it (does not delete Contacts).
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string listName - Name of your list.
    sub Delete
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        listName => shift];
        return $Api::mainApi->Request('list/delete', "GET", \@params);
    }

        # Exports all the contacts from the provided list
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string listName - Name of your list.
            # ApiTypes::ExportFileFormats fileFormat -  (default ApiTypes.ExportFileFormats.Csv)
            # ApiTypes::CompressionFormat compressionFormat - FileResponse compression format. None or Zip. (default ApiTypes.CompressionFormat.EENone)
            # string fileName - Name of your file. (default None)
        # Returns ApiTypes::ExportLink
    sub Export
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        listName => shift,
                        fileFormat => shift,
                        compressionFormat => shift,
                        fileName => shift];
        return $Api::mainApi->Request('list/export', "GET", \@params);
    }

        # Shows all your existing lists
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # DateTime? from - Starting date for search in YYYY-MM-DDThh:mm:ss format. (default None)
            # DateTime? to - Ending date for search in YYYY-MM-DDThh:mm:ss format. (default None)
        # Returns List<ApiTypes::List>
    sub list
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        from => shift,
                        to => shift];
        return $Api::mainApi->Request('list/list', "GET", \@params);
    }

        # Returns detailed information about specific list.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string listName - Name of your list.
        # Returns ApiTypes::List
    sub Load
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        listName => shift];
        return $Api::mainApi->Request('list/load', "GET", \@params);
    }

        # Move selected contacts from one List to another
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string oldListName - The name of the list from which the contacts will be copied from
            # string newListName - The name of the list to copy the contacts to
            # IEnumerable<string> emails - Comma delimited list of contact emails (default None)
            # bool? moveAll - TRUE - moves all contacts; FALSE - moves contacts provided in the 'emails' parameter. This is ignored if the 'statuses' parameter has been provided (default None)
            # IEnumerable<ApiTypes::ContactStatus> statuses - List of contact statuses which are eligible to move. This ignores the 'moveAll' parameter (default None)
    sub MoveContacts
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        oldListName => shift,
                        newListName => shift,
                        emails => shift,
                        moveAll => shift,
                        statuses => shift];
        return $Api::mainApi->Request('list/movecontacts', "GET", \@params);
    }

        # Remove selected Contacts from your list
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string listName - Name of your list.
            # string rule - Query used for filtering. (default None)
            # IEnumerable<string> emails - Comma delimited list of contact emails (default None)
    sub RemoveContacts
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        listName => shift,
                        rule => shift,
                        emails => shift];
        return $Api::mainApi->Request('list/removecontacts', "GET", \@params);
    }

        # Update existing list
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string listName - Name of your list.
            # string newListName - Name of your list if you want to change it. (default None)
            # bool allowUnsubscribe - True: Allow unsubscribing from this list. Otherwise, false (default False)
    sub Update
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        listName => shift,
                        newListName => shift,
                        allowUnsubscribe => shift];
        return $Api::mainApi->Request('list/update', "GET", \@params);
    }


#
# Methods to check logs of your campaigns
#
package Api::Log;

        # Cancels emails that are waiting to be sent.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string channelName - Name of selected channel. (default None)
            # string transactionID - ID number of transaction (default None)
    sub CancelInProgress
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        channelName => shift,
                        transactionID => shift];
        return $Api::mainApi->Request('log/cancelinprogress', "GET", \@params);
    }

        # Export email log information to the specified file format.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # IEnumerable<ApiTypes::LogJobStatus> statuses - List of comma separated message statuses: 0 or all, 1 for ReadyToSend, 2 for InProgress, 4 for Bounced, 5 for Sent, 6 for Opened, 7 for Clicked, 8 for Unsubscribed, 9 for Abuse Report
            # ApiTypes::ExportFileFormats fileFormat -  (default ApiTypes.ExportFileFormats.Csv)
            # DateTime? from - Start date. (default None)
            # DateTime? to - End date. (default None)
            # int channelID - ID number of selected Channel. (default 0)
            # int limit - Maximum of loaded items. (default 0)
            # int offset - How many items should be loaded ahead. (default 0)
            # bool includeEmail - True: Search includes emails. Otherwise, false. (default True)
            # bool includeSms - True: Search includes SMS. Otherwise, false. (default True)
            # IEnumerable<ApiTypes::MessageCategory> messageCategory - ID of message category (default None)
            # ApiTypes::CompressionFormat compressionFormat - FileResponse compression format. None or Zip. (default ApiTypes.CompressionFormat.EENone)
            # string fileName - Name of your file. (default None)
            # string email - Proper email address. (default None)
        # Returns ApiTypes::ExportLink
    sub Export
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        statuses => shift,
                        fileFormat => shift,
                        from => shift,
                        to => shift,
                        channelID => shift,
                        limit => shift,
                        offset => shift,
                        includeEmail => shift,
                        includeSms => shift,
                        messageCategory => shift,
                        compressionFormat => shift,
                        fileName => shift,
                        email => shift];
        return $Api::mainApi->Request('log/export', "GET", \@params);
    }

        # Export detailed link tracking information to the specified file format.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int channelID - ID number of selected Channel.
            # DateTime? from - Start date.
            # DateTime? to - End Date.
            # ApiTypes::ExportFileFormats fileFormat -  (default ApiTypes.ExportFileFormats.Csv)
            # int limit - Maximum of loaded items. (default 0)
            # int offset - How many items should be loaded ahead. (default 0)
            # ApiTypes::CompressionFormat compressionFormat - FileResponse compression format. None or Zip. (default ApiTypes.CompressionFormat.EENone)
            # string fileName - Name of your file. (default None)
        # Returns ApiTypes::ExportLink
    sub ExportLinkTracking
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        channelID => shift,
                        from => shift,
                        to => shift,
                        fileFormat => shift,
                        limit => shift,
                        offset => shift,
                        compressionFormat => shift,
                        fileName => shift];
        return $Api::mainApi->Request('log/exportlinktracking', "GET", \@params);
    }

        # Track link clicks
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # DateTime? from - Starting date for search in YYYY-MM-DDThh:mm:ss format. (default None)
            # DateTime? to - Ending date for search in YYYY-MM-DDThh:mm:ss format. (default None)
            # int limit - Maximum of loaded items. (default 0)
            # int offset - How many items should be loaded ahead. (default 0)
            # string channelName - Name of selected channel. (default None)
        # Returns ApiTypes::LinkTrackingDetails
    sub LinkTracking
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        from => shift,
                        to => shift,
                        limit => shift,
                        offset => shift,
                        channelName => shift];
        return $Api::mainApi->Request('log/linktracking', "GET", \@params);
    }

        # Returns logs filtered by specified parameters.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # IEnumerable<ApiTypes::LogJobStatus> statuses - List of comma separated message statuses: 0 or all, 1 for ReadyToSend, 2 for InProgress, 4 for Bounced, 5 for Sent, 6 for Opened, 7 for Clicked, 8 for Unsubscribed, 9 for Abuse Report
            # DateTime? from - Starting date for search in YYYY-MM-DDThh:mm:ss format. (default None)
            # DateTime? to - Ending date for search in YYYY-MM-DDThh:mm:ss format. (default None)
            # string channelName - Name of selected channel. (default None)
            # int limit - Maximum of loaded items. (default 0)
            # int offset - How many items should be loaded ahead. (default 0)
            # bool includeEmail - True: Search includes emails. Otherwise, false. (default True)
            # bool includeSms - True: Search includes SMS. Otherwise, false. (default True)
            # IEnumerable<ApiTypes::MessageCategory> messageCategory - ID of message category (default None)
            # string email - Proper email address. (default None)
            # bool useStatusChangeDate - True, if 'from' and 'to' parameters should resolve to the Status Change date. To resolve to the creation date - false (default False)
        # Returns ApiTypes::Log
    sub Load
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        statuses => shift,
                        from => shift,
                        to => shift,
                        channelName => shift,
                        limit => shift,
                        offset => shift,
                        includeEmail => shift,
                        includeSms => shift,
                        messageCategory => shift,
                        email => shift,
                        useStatusChangeDate => shift];
        return $Api::mainApi->Request('log/load', "GET", \@params);
    }

        # Retry sending of temporarily not delivered message.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string msgID - ID number of selected message.
    sub RetryNow
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        msgID => shift];
        return $Api::mainApi->Request('log/retrynow', "GET", \@params);
    }

        # Loads summary information about activity in chosen date range.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # DateTime from - Starting date for search in YYYY-MM-DDThh:mm:ss format.
            # DateTime to - Ending date for search in YYYY-MM-DDThh:mm:ss format.
            # string channelName - Name of selected channel. (default None)
            # string interval - 'Hourly' for detailed information, 'summary' for daily overview (default "summary")
            # string transactionID - ID number of transaction (default None)
        # Returns ApiTypes::LogSummary
    sub Summary
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        from => shift,
                        to => shift,
                        channelName => shift,
                        interval => shift,
                        transactionID => shift];
        return $Api::mainApi->Request('log/summary', "GET", \@params);
    }


#
# Manages your segments - dynamically created lists of contacts
#
package Api::Segment;

        # Create new segment, based on specified RULE.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string segmentName - Name of your segment.
            # string rule - Query used for filtering.
        # Returns ApiTypes::Segment
    sub Add
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        segmentName => shift,
                        rule => shift];
        return $Api::mainApi->Request('segment/add', "GET", \@params);
    }

        # Copy your existing Segment with the optional new rule and custom name
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string sourceSegmentName - The name of the segment you want to copy
            # string newSegmentName - New name of your segment if you want to change it. (default None)
            # string rule - Query used for filtering. (default None)
        # Returns ApiTypes::Segment
    sub Copy
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        sourceSegmentName => shift,
                        newSegmentName => shift,
                        rule => shift];
        return $Api::mainApi->Request('segment/copy', "GET", \@params);
    }

        # Delete existing segment.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string segmentName - Name of your segment.
    sub Delete
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        segmentName => shift];
        return $Api::mainApi->Request('segment/delete', "GET", \@params);
    }

        # Exports all the contacts from the provided segment
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string segmentName - Name of your segment.
            # ApiTypes::ExportFileFormats fileFormat -  (default ApiTypes.ExportFileFormats.Csv)
            # ApiTypes::CompressionFormat compressionFormat - FileResponse compression format. None or Zip. (default ApiTypes.CompressionFormat.EENone)
            # string fileName - Name of your file. (default None)
        # Returns ApiTypes::ExportLink
    sub Export
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        segmentName => shift,
                        fileFormat => shift,
                        compressionFormat => shift,
                        fileName => shift];
        return $Api::mainApi->Request('segment/export', "GET", \@params);
    }

        # Lists all your available Segments
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # bool includeHistory - True: Include history of last 30 days. Otherwise, false. (default False)
            # DateTime? from - From what date should the segment history be shown (default None)
            # DateTime? to - To what date should the segment history be shown (default None)
        # Returns List<ApiTypes::Segment>
    sub List
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        includeHistory => shift,
                        from => shift,
                        to => shift];
        return $Api::mainApi->Request('segment/list', "GET", \@params);
    }

        # Lists your available Segments using the provided names
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # IEnumerable<string> segmentNames - Names of segments you want to load. Will load all contacts if left empty or the 'All Contacts' name has been provided
            # bool includeHistory - True: Include history of last 30 days. Otherwise, false. (default False)
            # DateTime? from - From what date should the segment history be shown (default None)
            # DateTime? to - To what date should the segment history be shown (default None)
        # Returns List<ApiTypes::Segment>
    sub LoadByName
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        segmentNames => shift,
                        includeHistory => shift,
                        from => shift,
                        to => shift];
        return $Api::mainApi->Request('segment/loadbyname', "GET", \@params);
    }

        # Rename or change RULE for your segment
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string segmentName - Name of your segment.
            # string newSegmentName - New name of your segment if you want to change it. (default None)
            # string rule - Query used for filtering. (default None)
        # Returns ApiTypes::Segment
    sub Update
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        segmentName => shift,
                        newSegmentName => shift,
                        rule => shift];
        return $Api::mainApi->Request('segment/update', "GET", \@params);
    }


#
# Managing texting to your clients.
#
package Api::SMS;

        # Send a short SMS Message (maximum of 1600 characters) to any mobile phone.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string to - Mobile number you want to message. Can be any valid mobile number in E.164 format. To provide the country code you need to provide "+" before the number.  If your URL is not encoded then you need to replace the "+" with "%2B" instead.
            # string body - Body of your message. The maximum body length is 160 characters.  If the message body is greater than 160 characters it is split into multiple messages and you are charged per message for the number of message required to send your length
    sub Send
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        to => shift,
                        body => shift];
        return $Api::mainApi->Request('sms/send', "GET", \@params);
    }


#
# Methods to organize and get results of your surveys
#
package Api::Survey;

        # Adds a new survey
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # ApiTypes::Survey survey - Json representation of a survey
        # Returns ApiTypes::Survey
    sub Add
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        survey => shift];
        return $Api::mainApi->Request('survey/add', "GET", \@params);
    }

        # Deletes the survey
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # Guid publicSurveyID - Survey identifier
    sub Delete
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        publicSurveyID => shift];
        return $Api::mainApi->Request('survey/delete', "GET", \@params);
    }

        # Export given survey's data to provided format
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # Guid publicSurveyID - Survey identifier
            # string fileName - Name of your file.
            # ApiTypes::ExportFileFormats fileFormat -  (default ApiTypes.ExportFileFormats.Csv)
            # ApiTypes::CompressionFormat compressionFormat - FileResponse compression format. None or Zip. (default ApiTypes.CompressionFormat.EENone)
        # Returns ApiTypes::ExportLink
    sub Export
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        publicSurveyID => shift,
                        fileName => shift,
                        fileFormat => shift,
                        compressionFormat => shift];
        return $Api::mainApi->Request('survey/export', "GET", \@params);
    }

        # Shows all your existing surveys
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
        # Returns List<ApiTypes::Survey>
    sub List
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}];
        return $Api::mainApi->Request('survey/list', "GET", \@params);
    }

        # Get list of personal answers for the specific survey
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # Guid publicSurveyID - Survey identifier
        # Returns List<ApiTypes::SurveyResultInfo>
    sub LoadResponseList
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        publicSurveyID => shift];
        return $Api::mainApi->Request('survey/loadresponselist', "GET", \@params);
    }

        # Get general results of the specific survey
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # Guid publicSurveyID - Survey identifier
        # Returns ApiTypes::SurveyResultsSummaryInfo
    sub LoadResults
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        publicSurveyID => shift];
        return $Api::mainApi->Request('survey/loadresults', "GET", \@params);
    }

        # Update the survey information
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # ApiTypes::Survey survey - Json representation of a survey
        # Returns ApiTypes::Survey
    sub Update
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        survey => shift];
        return $Api::mainApi->Request('survey/update', "GET", \@params);
    }


#
# Managing and editing templates of your emails
#
package Api::Template;

        # Create new Template. Needs to be sent using POST method
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # ApiTypes::TemplateType templateType - 0 for API connections
            # string templateName - Name of template.
            # string subject - Default subject of email.
            # string fromEmail - Default From: email address.
            # string fromName - Default From: name.
            # ApiTypes::TemplateScope templateScope - Enum: 0 - private, 1 - public, 2 - mockup (default ApiTypes.TemplateScope.Private)
            # string bodyHtml - HTML code of email (needs escaping). (default None)
            # string bodyText - Text body of email. (default None)
            # string css - CSS style (default None)
            # int originalTemplateID - ID number of original template. (default 0)
        # Returns int
    sub Add
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        templateType => shift,
                        templateName => shift,
                        subject => shift,
                        fromEmail => shift,
                        fromName => shift,
                        templateScope => shift,
                        bodyHtml => shift,
                        bodyText => shift,
                        css => shift,
                        originalTemplateID => shift];
        return $Api::mainApi->Request('template/add', "GET", \@params);
    }

        # Check if template is used by campaign.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int templateID - ID number of template.
        # Returns bool
    sub CheckUsage
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        templateID => shift];
        return $Api::mainApi->Request('template/checkusage', "GET", \@params);
    }

        # Copy Selected Template
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int templateID - ID number of template.
            # string templateName - Name of template.
            # string subject - Default subject of email.
            # string fromEmail - Default From: email address.
            # string fromName - Default From: name.
        # Returns ApiTypes::Template
    sub Copy
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        templateID => shift,
                        templateName => shift,
                        subject => shift,
                        fromEmail => shift,
                        fromName => shift];
        return $Api::mainApi->Request('template/copy', "GET", \@params);
    }

        # Delete template with the specified ID
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int templateID - ID number of template.
    sub Delete
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        templateID => shift];
        return $Api::mainApi->Request('template/delete', "GET", \@params);
    }

        # Search for references to images and replaces them with base64 code.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int templateID - ID number of template.
        # Returns string
    sub GetEmbeddedHtml
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        templateID => shift];
        return $Api::mainApi->Request('template/getembeddedhtml', "GET", \@params);
    }

        # Lists your templates
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int limit - Maximum of loaded items. (default 500)
            # int offset - How many items should be loaded ahead. (default 0)
        # Returns ApiTypes::TemplateList
    sub GetList
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        limit => shift,
                        offset => shift];
        return $Api::mainApi->Request('template/getlist', "GET", \@params);
    }

        # Load template with content
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int templateID - ID number of template.
            # bool ispublic -  (default False)
        # Returns ApiTypes::Template
    sub LoadTemplate
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        templateID => shift,
                        ispublic => shift];
        return $Api::mainApi->Request('template/loadtemplate', "GET", \@params);
    }

        # Removes previously generated screenshot of template
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int templateID - ID number of template.
    sub RemoveScreenshot
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        templateID => shift];
        return $Api::mainApi->Request('template/removescreenshot', "GET", \@params);
    }

        # Saves screenshot of chosen Template
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # string base64Image - Image, base64 coded.
            # int templateID - ID number of template.
        # Returns string
    sub SaveScreenshot
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        base64Image => shift,
                        templateID => shift];
        return $Api::mainApi->Request('template/savescreenshot', "GET", \@params);
    }

        # Update existing template, overwriting existing data. Needs to be sent using POST method.
            # string apikey - ApiKey that gives you access to our SMTP and HTTP API's.
            # int templateID - ID number of template.
            # ApiTypes::TemplateScope templateScope - Enum: 0 - private, 1 - public, 2 - mockup (default ApiTypes.TemplateScope.Private)
            # string templateName - Name of template. (default None)
            # string subject - Default subject of email. (default None)
            # string fromEmail - Default From: email address. (default None)
            # string fromName - Default From: name. (default None)
            # string bodyHtml - HTML code of email (needs escaping). (default None)
            # string bodyText - Text body of email. (default None)
            # string css - CSS style (default None)
            # bool removeScreenshot -  (default True)
    sub Update
    {
        shift;
        my @params = [apikey => $Api::mainApi->{apikey}, 
                        templateID => shift,
                        templateScope => shift,
                        templateName => shift,
                        subject => shift,
                        fromEmail => shift,
                        fromName => shift,
                        bodyHtml => shift,
                        bodyText => shift,
                        css => shift,
                        removeScreenshot => shift];
        return $Api::mainApi->Request('template/update', "GET", \@params);
    }



package ApiTypes;
    # 
    # Detailed information about your account
    # 
    package ApiTypes::Account;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Code used for tax purposes.
        #
        TaxCode => shift,

        #
        # Public key for limited access to your account such as contact/add so you can use it safely on public websites.
        #
        PublicAccountID => shift,

        #
        # ApiKey that gives you access to our SMTP and HTTP API's.
        #
        ApiKey => shift,

        #
        # Second ApiKey that gives you access to our SMTP and HTTP API's.  Used mainly for changing ApiKeys without disrupting services.
        #
        ApiKey2 => shift,

        #
        # True, if account is a subaccount. Otherwise, false
        #
        IsSub => shift,

        #
        # The number of subaccounts this account has.
        #
        SubAccountsCount => shift,

        #
        # Number of status: 1 - Active
        #
        StatusNumber => shift,

        #
        # Account status: Active
        #
        StatusFormatted => shift,

        #
        # URL form for payments.
        #
        PaymentFormUrl => shift,

        #
        # URL to your logo image.
        #
        LogoUrl => shift,

        #
        # HTTP address of your website.
        #
        Website => shift,

        #
        # True: Turn on or off ability to send mails under your brand. Otherwise, false
        #
        EnablePrivateBranding => shift,

        #
        # Address to your support.
        #
        SupportLink => shift,

        #
        # Subdomain for your rebranded service
        #
        PrivateBrandingUrl => shift,

        #
        # First name.
        #
        FirstName => shift,

        #
        # Last name.
        #
        LastName => shift,

        #
        # Company name.
        #
        Company => shift,

        #
        # First line of address.
        #
        Address1 => shift,

        #
        # Second line of address.
        #
        Address2 => shift,

        #
        # City.
        #
        City => shift,

        #
        # State or province.
        #
        State => shift,

        #
        # Zip/postal code.
        #
        Zip => shift,

        #
        # Numeric ID of country. A file with the list of countries is available <a href="http://api.elasticemail.com/public/countries"><b>here</b></a>
        #
        CountryID => shift,

        #
        # Phone number
        #
        Phone => shift,

        #
        # Proper email address.
        #
        Email => shift,

        #
        # URL for affiliating.
        #
        AffiliateLink => shift,

        #
        # Numeric reputation
        #
        Reputation => shift,

        #
        # Amount of emails sent from this account
        #
        TotalEmailsSent => shift,

        #
        # Amount of emails sent from this account
        #
        MonthlyEmailsSent => shift,

        #
        # Amount of emails sent from this account
        #
        Credit => shift,

        #
        # Amount of email credits
        #
        EmailCredits => shift,

        #
        # Amount of emails sent from this account
        #
        PricePerEmail => shift,

        #
        # Why your clients are receiving your emails.
        #
        DeliveryReason => shift,

        #
        # URL for making payments.
        #
        AccountPaymentUrl => shift,

        #
        # Address of SMTP server.
        #
        Smtp => shift,

        #
        # Address of alternative SMTP server.
        #
        SmtpAlternative => shift,

        #
        # Status of automatic payments configuration.
        #
        AutoCreditStatus => shift,

        #
        # When AutoCreditStatus is Enabled, the credit level that triggers the credit to be recharged.
        #
        AutoCreditLevel => shift,

        #
        # When AutoCreditStatus is Enabled, the amount of credit to be recharged.
        #
        AutoCreditAmount => shift,

        #
        # Amount of emails account can send daily
        #
        DailySendLimit => shift,

        #
        # Creation date.
        #
        DateCreated => shift,

        #
        # True, if you have enabled link tracking. Otherwise, false
        #
        LinkTracking => shift,

        #
        # Type of content encoding
        #
        ContentTransferEncoding => shift,

        #
        # Amount of Litmus credits
        #
        LitmusCredits => shift,

        #
        # Enable advanced tools on your Account.
        #
        EnableContactFeatures => shift,

        #
        # 
        #
        NeedsSMSVerification => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Basic overview of your account
    # 
    package ApiTypes::AccountOverview;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Amount of emails sent from this account
        #
        TotalEmailsSent => shift,

        #
        # Amount of emails sent from this account
        #
        Credit => shift,

        #
        # Cost of 1000 emails
        #
        CostPerThousand => shift,

        #
        # Number of messages in progress
        #
        InProgressCount => shift,

        #
        # Number of contacts currently with blocked status of Unsubscribed, Complaint, Bounced or InActive
        #
        BlockedContactsCount => shift,

        #
        # Numeric reputation
        #
        Reputation => shift,

        #
        # Number of contacts
        #
        ContactCount => shift,

        #
        # Number of created campaigns
        #
        CampaignCount => shift,

        #
        # Number of available templates
        #
        TemplateCount => shift,

        #
        # Number of created subaccounts
        #
        SubAccountCount => shift,

        #
        # Number of active referrals
        #
        ReferralCount => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Lists advanced sending options of your account.
    # 
    package ApiTypes::AdvancedOptions;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # True, if you want to track clicks. Otherwise, false
        #
        EnableClickTracking => shift,

        #
        # True, if you want to track by link tracking. Otherwise, false
        #
        EnableLinkClickTracking => shift,

        #
        # True, if you want to use template scripting in your emails {{}}. Otherwise, false
        #
        EnableTemplateScripting => shift,

        #
        # True, if text BODY of message should be created automatically. Otherwise, false
        #
        AutoTextFormat => shift,

        #
        # True, if you want bounce notifications returned. Otherwise, false
        #
        EmailNotificationForError => shift,

        #
        # True, if you want to send web notifications for sent email. Otherwise, false
        #
        WebNotificationForSent => shift,

        #
        # True, if you want to send web notifications for opened email. Otherwise, false
        #
        WebNotificationForOpened => shift,

        #
        # True, if you want to send web notifications for clicked email. Otherwise, false
        #
        WebNotificationForClicked => shift,

        #
        # True, if you want to send web notifications for unsubscribed email. Otherwise, false
        #
        WebnotificationForUnsubscribed => shift,

        #
        # True, if you want to send web notifications for complaint email. Otherwise, false
        #
        WebNotificationForAbuse => shift,

        #
        # True, if you want to send web notifications for bounced email. Otherwise, false
        #
        WebNotificationForError => shift,

        #
        # True, if you want to receive low credit email notifications. Otherwise, false
        #
        LowCreditNotification => shift,

        #
        # True, if you want inbound email to only process contacts from your account. Otherwise, false
        #
        InboundContactsOnly => shift,

        #
        # True, if this account is a sub-account. Otherwise, false
        #
        IsSubAccount => shift,

        #
        # True, if this account resells Elastic Email. Otherwise, false.
        #
        IsOwnedByReseller => shift,

        #
        # True, if you want to enable list-unsubscribe header. Otherwise, false
        #
        EnableUnsubscribeHeader => shift,

        #
        # True, if you want to display your labels on your unsubscribe form. Otherwise, false
        #
        ManageSubscriptions => shift,

        #
        # True, if you want to only display labels that the contact is subscribed to on your unsubscribe form. Otherwise, false
        #
        ManageSubscribedOnly => shift,

        #
        # True, if you want to display an option for the contact to opt into transactional email only on your unsubscribe form. Otherwise, false
        #
        TransactionalOnUnsubscribe => shift,

        #
        # 
        #
        PreviewMessageID => shift,

        #
        # True, if you want to apply custom headers to your emails. Otherwise, false
        #
        AllowCustomHeaders => shift,

        #
        # Email address to send a copy of all email to.
        #
        BccEmail => shift,

        #
        # Type of content encoding
        #
        ContentTransferEncoding => shift,

        #
        # True, if you want to receive bounce email notifications. Otherwise, false
        #
        EmailNotification => shift,

        #
        # Email addresses to send a copy of all notifications from our system. Separated by semicolon
        #
        NotificationsEmails => shift,

        #
        # Emails, separated by semicolon, to which the notification about contact unsubscribing should be sent to
        #
        UnsubscribeNotificationEmails => shift,

        #
        # URL address to receive web notifications to parse and process.
        #
        WebNotificationUrl => shift,

        #
        # URL used for tracking action of inbound emails
        #
        HubCallbackUrl => shift,

        #
        # Domain you use as your inbound domain
        #
        InboundDomain => shift,

        #
        # True, if account has tooltips active. Otherwise, false
        #
        EnableUITooltips => shift,

        #
        # True, if you want to use Advanced Tools.  Otherwise, false
        #
        EnableContactFeatures => shift,

        #
        # URL to your logo image.
        #
        LogoUrl => shift,

        #
        # (0 means this functionality is NOT enabled) Score, depending on the number of times you have sent to a recipient, at which the given recipient should be moved to the Stale status
        #
        StaleContactScore => shift,

        #
        # (0 means this functionality is NOT enabled) Number of days of inactivity for a contact after which the given recipient should be moved to the Stale status
        #
        StaleContactInactiveDays => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::APIKeyAction;
    use constant {
        #
        # Add an additional APIKey to your Account.
        #
        ADD => '1',

        #
        # Change this APIKey to a new one.
        #
        CHANGE => '2',

        #
        # Delete this APIKey
        #
        DELETE => '3',

    };

    # 
    # Attachment data
    # 
    package ApiTypes::Attachment;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Name of your file.
        #
        FileName => shift,

        #
        # ID number of your attachment
        #
        ID => shift,

        #
        # Size of your attachment.
        #
        Size => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Blocked Contact - Contact returning Hard Bounces
    # 
    package ApiTypes::BlockedContact;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Proper email address.
        #
        Email => shift,

        #
        # Name of status: Active, Engaged, Inactive, Abuse, Bounced, Unsubscribed.
        #
        Status => shift,

        #
        # RFC error message
        #
        FriendlyErrorMessage => shift,

        #
        # Last change date
        #
        DateUpdated => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Summary of bounced categories, based on specified date range.
    # 
    package ApiTypes::BouncedCategorySummary;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Number of messages marked as SPAM
        #
        Spam => shift,

        #
        # Number of blacklisted messages
        #
        BlackListed => shift,

        #
        # Number of messages flagged with 'No Mailbox'
        #
        NoMailbox => shift,

        #
        # Number of messages flagged with 'Grey Listed'
        #
        GreyListed => shift,

        #
        # Number of messages flagged with 'Throttled'
        #
        Throttled => shift,

        #
        # Number of messages flagged with 'Timeout'
        #
        Timeout => shift,

        #
        # Number of messages flagged with 'Connection Problem'
        #
        ConnectionProblem => shift,

        #
        # Number of messages flagged with 'SPF Problem'
        #
        SpfProblem => shift,

        #
        # Number of messages flagged with 'Account Problem'
        #
        AccountProblem => shift,

        #
        # Number of messages flagged with 'DNS Problem'
        #
        DnsProblem => shift,

        #
        # Number of messages flagged with 'WhiteListing Problem'
        #
        WhitelistingProblem => shift,

        #
        # Number of messages flagged with 'Code Error'
        #
        CodeError => shift,

        #
        # Number of messages flagged with 'Not Delivered'
        #
        NotDelivered => shift,

        #
        # Number of manually cancelled messages
        #
        ManualCancel => shift,

        #
        # Number of messages flagged with 'Connection terminated'
        #
        ConnectionTerminated => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Campaign
    # 
    package ApiTypes::Campaign;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # ID number of selected Channel.
        #
        ChannelID => shift,

        #
        # Campaign's name
        #
        Name => shift,

        #
        # Name of campaign's status
        #
        Status => shift,

        #
        # List of Segment and List IDs, comma separated
        #
        Targets => shift,

        #
        # Number of event, triggering mail sending
        #
        TriggerType => shift,

        #
        # Date of triggered send
        #
        TriggerDate => shift,

        #
        # How far into the future should the campaign be sent, in minutes
        #
        TriggerDelay => shift,

        #
        # When your next automatic mail will be sent, in days
        #
        TriggerFrequency => shift,

        #
        # Date of send
        #
        TriggerCount => shift,

        #
        # ID number of transaction
        #
        TriggerChannelID => shift,

        #
        # Data for filtering event campaigns such as specific link addresses.
        #
        TriggerData => shift,

        #
        # What should be checked for choosing the winner: opens or clicks
        #
        SplitOptimization => shift,

        #
        # Number of minutes between sends during optimization period
        #
        SplitOptimizationMinutes => shift,

        #
        # 
        #
        TimingOption => shift,

        #
        # 
        #
        CampaignTemplates => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Channel
    # 
    package ApiTypes::CampaignChannel;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # ID number of selected Channel.
        #
        ChannelID => shift,

        #
        # Filename
        #
        Name => shift,

        #
        # True, if you are sending a campaign. Otherwise, false.
        #
        IsCampaign => shift,

        #
        # Name of your custom IP Pool to be used in the sending process
        #
        PoolName => shift,

        #
        # Date of creation in YYYY-MM-DDThh:ii:ss format
        #
        DateAdded => shift,

        #
        # Name of campaign's status
        #
        Status => shift,

        #
        # Date of last activity on account
        #
        LastActivity => shift,

        #
        # Datetime of last action done on campaign.
        #
        LastProcessed => shift,

        #
        # Id number of parent channel
        #
        ParentChannelID => shift,

        #
        # List of Segment and List IDs, comma separated
        #
        Targets => shift,

        #
        # Number of event, triggering mail sending
        #
        TriggerType => shift,

        #
        # Date of triggered send
        #
        TriggerDate => shift,

        #
        # How far into the future should the campaign be sent, in minutes
        #
        TriggerDelay => shift,

        #
        # When your next automatic mail will be sent, in days
        #
        TriggerFrequency => shift,

        #
        # Date of send
        #
        TriggerCount => shift,

        #
        # ID number of transaction
        #
        TriggerChannelID => shift,

        #
        # Data for filtering event campaigns such as specific link addresses.
        #
        TriggerData => shift,

        #
        # What should be checked for choosing the winner: opens or clicks
        #
        SplitOptimization => shift,

        #
        # Number of minutes between sends during optimization period
        #
        SplitOptimizationMinutes => shift,

        #
        # 
        #
        TimingOption => shift,

        #
        # ID number of template.
        #
        TemplateID => shift,

        #
        # Default subject of email.
        #
        TemplateSubject => shift,

        #
        # Default From: email address.
        #
        TemplateFromEmail => shift,

        #
        # Default From: name.
        #
        TemplateFromName => shift,

        #
        # Default Reply: email address.
        #
        TemplateReplyEmail => shift,

        #
        # Default Reply: name.
        #
        TemplateReplyName => shift,

        #
        # Total emails clicked
        #
        ClickedCount => shift,

        #
        # Total emails opened.
        #
        OpenedCount => shift,

        #
        # Overall number of recipients
        #
        RecipientCount => shift,

        #
        # Total emails sent.
        #
        SentCount => shift,

        #
        # Total emails sent.
        #
        FailedCount => shift,

        #
        # Total emails clicked
        #
        UnsubscribedCount => shift,

        #
        # Abuses - mails sent to user without their consent
        #
        FailedAbuse => shift,

        #
        # List of CampaignTemplate for sending A-X split testing.
        #
        TemplateChannels => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::CampaignStatus;
    use constant {
        #
        # Campaign is logically deleted and not returned by API or interface calls.
        #
        DELETED => '-1',

        #
        # Campaign is curently active and available.
        #
        ACTIVE => '0',

        #
        # Campaign is currently being processed for delivery.
        #
        PROCESSING => '1',

        #
        # Campaign is currently sending.
        #
        SENDING => '2',

        #
        # Campaign has completed sending.
        #
        COMPLETED => '3',

        #
        # Campaign is currently paused and not sending.
        #
        PAUSED => '4',

        #
        # Campaign has been cancelled during delivery.
        #
        CANCELLED => '5',

        #
        # Campaign is save as draft and not processing.
        #
        DRAFT => '6',

    };

    # 
    # 
    # 
    package ApiTypes::CampaignTemplate;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # ID number of selected Channel.
        #
        ChannelID => shift,

        #
        # Name of campaign's status
        #
        Status => shift,

        #
        # Name of your custom IP Pool to be used in the sending process
        #
        PoolName => shift,

        #
        # ID number of template.
        #
        TemplateID => shift,

        #
        # Default subject of email.
        #
        TemplateSubject => shift,

        #
        # Default From: email address.
        #
        TemplateFromEmail => shift,

        #
        # Default From: name.
        #
        TemplateFromName => shift,

        #
        # Default Reply: email address.
        #
        TemplateReplyEmail => shift,

        #
        # Default Reply: name.
        #
        TemplateReplyName => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::CampaignTriggerType;
    use constant {
        #
        # 
        #
        SENDNOW => '1',

        #
        # 
        #
        FUTURESCHEDULED => '2',

        #
        # 
        #
        ONADD => '3',

        #
        # 
        #
        ONOPEN => '4',

        #
        # 
        #
        ONCLICK => '5',

    };

    # 
    # SMTP and HTTP API channel for grouping email delivery
    # 
    package ApiTypes::Channel;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Descriptive name of the channel.
        #
        Name => shift,

        #
        # The date the channel was added to your account.
        #
        DateAdded => shift,

        #
        # The date the channel was last sent through.
        #
        LastActivity => shift,

        #
        # The number of email jobs this channel has been used with.
        #
        JobCount => shift,

        #
        # The number of emails that have been clicked within this channel.
        #
        ClickedCount => shift,

        #
        # The number of emails that have been opened within this channel.
        #
        OpenedCount => shift,

        #
        # The number of emails attempted to be sent within this channel.
        #
        RecipientCount => shift,

        #
        # The number of emails that have been sent within this channel.
        #
        SentCount => shift,

        #
        # The number of emails that have been bounced within this channel.
        #
        FailedCount => shift,

        #
        # The number of emails that have been unsubscribed within this channel.
        #
        UnsubscribedCount => shift,

        #
        # The number of emails that have been marked as abuse or complaint within this channel.
        #
        FailedAbuse => shift,

        #
        # The total cost for emails/attachments within this channel.
        #
        Cost => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # FileResponse compression format
    # 
    package ApiTypes::CompressionFormat;
    use constant {
        #
        # No compression
        #
        EENONE => '0',

        #
        # Zip compression
        #
        ZIP => '1',

    };

    # 
    # Contact
    # 
    package ApiTypes::Contact;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # 
        #
        ContactScore => shift,

        #
        # Date of creation in YYYY-MM-DDThh:ii:ss format
        #
        DateAdded => shift,

        #
        # Proper email address.
        #
        Email => shift,

        #
        # First name.
        #
        FirstName => shift,

        #
        # Last name.
        #
        LastName => shift,

        #
        # Title
        #
        Title => shift,

        #
        # Name of organization
        #
        OrganizationName => shift,

        #
        # City.
        #
        City => shift,

        #
        # Name of country.
        #
        Country => shift,

        #
        # State or province.
        #
        State => shift,

        #
        # Zip/postal code.
        #
        Zip => shift,

        #
        # Phone number
        #
        Phone => shift,

        #
        # Date of birth in YYYY-MM-DD format
        #
        BirthDate => shift,

        #
        # Your gender
        #
        Gender => shift,

        #
        # Name of status: Active, Engaged, Inactive, Abuse, Bounced, Unsubscribed.
        #
        Status => shift,

        #
        # RFC Error code
        #
        BouncedErrorCode => shift,

        #
        # RFC error message
        #
        BouncedErrorMessage => shift,

        #
        # Total emails sent.
        #
        TotalSent => shift,

        #
        # Total emails sent.
        #
        TotalFailed => shift,

        #
        # Total emails opened.
        #
        TotalOpened => shift,

        #
        # Total emails clicked
        #
        TotalClicked => shift,

        #
        # Date of first failed message
        #
        FirstFailedDate => shift,

        #
        # Number of fails in sending to this Contact
        #
        LastFailedCount => shift,

        #
        # Last change date
        #
        DateUpdated => shift,

        #
        # Source of URL of payment
        #
        Source => shift,

        #
        # RFC Error code
        #
        ErrorCode => shift,

        #
        # RFC error message
        #
        FriendlyErrorMessage => shift,

        #
        # IP address
        #
        CreatedFromIP => shift,

        #
        # Yearly revenue for the contact
        #
        Revenue => shift,

        #
        # Number of purchases contact has made
        #
        PurchaseCount => shift,

        #
        # Mobile phone number
        #
        MobileNumber => shift,

        #
        # Fax number
        #
        FaxNumber => shift,

        #
        # Biography for Linked-In
        #
        LinkedInBio => shift,

        #
        # Number of Linked-In connections
        #
        LinkedInConnections => shift,

        #
        # Biography for Twitter
        #
        TwitterBio => shift,

        #
        # User name for Twitter
        #
        TwitterUsername => shift,

        #
        # URL for Twitter photo
        #
        TwitterProfilePhoto => shift,

        #
        # Number of Twitter followers
        #
        TwitterFollowerCount => shift,

        #
        # Unsubscribed date in YYYY-MM-DD format
        #
        UnsubscribedDate => shift,

        #
        # Industry contact works in
        #
        Industry => shift,

        #
        # Number of employees
        #
        NumberOfEmployees => shift,

        #
        # Annual revenue of contact
        #
        AnnualRevenue => shift,

        #
        # Date of first purchase in YYYY-MM-DD format
        #
        FirstPurchase => shift,

        #
        # Date of last purchase in YYYY-MM-DD format
        #
        LastPurchase => shift,

        #
        # Free form field of notes
        #
        Notes => shift,

        #
        # Website of contact
        #
        WebsiteUrl => shift,

        #
        # Number of page views
        #
        PageViews => shift,

        #
        # Number of website visits
        #
        Visits => shift,

        #
        # Number of messages sent last month
        #
        LastMonthSent => shift,

        #
        # Date this contact last opened an email
        #
        LastOpened => shift,

        #
        # 
        #
        LastClicked => shift,

        #
        # Your gravatar hash for image
        #
        GravatarHash => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Collection of lists and segments
    # 
    package ApiTypes::ContactCollection;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Lists which contain the requested contact
        #
        Lists => shift,

        #
        # Segments which contain the requested contact
        #
        Segments => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # List's or segment's short info
    # 
    package ApiTypes::ContactContainer;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # ID of the list/segment
        #
        ID => shift,

        #
        # Name of the list/segment
        #
        Name => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # History of chosen Contact
    # 
    package ApiTypes::ContactHistory;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # ID of history of selected Contact.
        #
        ContactHistoryID => shift,

        #
        # Type of event occured on this Contact.
        #
        EventType => shift,

        #
        # Numeric code of event occured on this Contact.
        #
        EventTypeValue => shift,

        #
        # Formatted date of event.
        #
        EventDate => shift,

        #
        # Name of selected channel.
        #
        ChannelName => shift,

        #
        # Name of template.
        #
        TemplateName => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::ContactSource;
    use constant {
        #
        # Source of the contact is from sending an email via our SMTP or HTTP API's
        #
        DELIVERYAPI => '0',

        #
        # Contact was manually entered from the interface.
        #
        MANUALINPUT => '1',

        #
        # Contact was uploaded via a file such as CSV.
        #
        FILEUPLOAD => '2',

        #
        # Contact was added from a public web form.
        #
        WEBFORM => '3',

        #
        # Contact was added from the contact api.
        #
        CONTACTAPI => '4',

    };

    # 
    # 
    # 
    package ApiTypes::ContactStatus;
    use constant {
        #
        # Only transactional email can be sent to contacts with this status.
        #
        TRANSACTIONAL => '-2',

        #
        # Contact has had an open or click in the last 6 months.
        #
        ENGAGED => '-1',

        #
        # Contact is eligible to be sent to.
        #
        ACTIVE => '0',

        #
        # Contact has had a hard bounce and is no longer eligible to be sent to.
        #
        BOUNCED => '1',

        #
        # Contact has unsubscribed and is no longer eligible to be sent to.
        #
        UNSUBSCRIBED => '2',

        #
        # Contact has complained and is no longer eligible to be sent to.
        #
        ABUSE => '3',

        #
        # Contact has not been activated or has been de-activated and is not eligible to be sent to.
        #
        INACTIVE => '4',

        #
        # Contact has not been opening emails for a long period of time and is not eligible to be sent to.
        #
        STALE => '5',

    };

    # 
    # Number of Contacts, grouped by Status;
    # 
    package ApiTypes::ContactStatusCounts;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Number of engaged contacts
        #
        Engaged => shift,

        #
        # Number of active contacts
        #
        Active => shift,

        #
        # Number of complaint messages
        #
        Complaint => shift,

        #
        # Number of unsubscribed messages
        #
        Unsubscribed => shift,

        #
        # Number of bounced messages
        #
        Bounced => shift,

        #
        # Number of inactive contacts
        #
        Inactive => shift,

        #
        # Number of transactional contacts
        #
        Transactional => shift,

        #
        # 
        #
        Stale => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Type of credits
    # 
    package ApiTypes::CreditType;
    use constant {
        #
        # Used to send emails.  One credit = one email.
        #
        EMAIL => '9',

        #
        # Used to run a litmus test on a template.  1 credit = 1 test.
        #
        LITMUS => '17',

    };

    # 
    # Daily summary of log status, based on specified date range.
    # 
    package ApiTypes::DailyLogStatusSummary;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Date in YYYY-MM-DDThh:ii:ss format
        #
        Date => shift,

        #
        # Proper email address.
        #
        Email => shift,

        #
        # Number of SMS
        #
        Sms => shift,

        #
        # Number of delivered messages
        #
        Delivered => shift,

        #
        # Number of opened messages
        #
        Opened => shift,

        #
        # Number of clicked messages
        #
        Clicked => shift,

        #
        # Number of unsubscribed messages
        #
        Unsubscribed => shift,

        #
        # Number of complaint messages
        #
        Complaint => shift,

        #
        # Number of bounced messages
        #
        Bounced => shift,

        #
        # Number of inbound messages
        #
        Inbound => shift,

        #
        # Number of manually cancelled messages
        #
        ManualCancel => shift,

        #
        # Number of messages flagged with 'Not Delivered'
        #
        NotDelivered => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Domain data, with information about domain records.
    # 
    package ApiTypes::DomainDetail;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Name of selected domain.
        #
        Domain => shift,

        #
        # True, if domain is used as default. Otherwise, false,
        #
        DefaultDomain => shift,

        #
        # True, if SPF record is verified
        #
        Spf => shift,

        #
        # True, if DKIM record is verified
        #
        Dkim => shift,

        #
        # True, if MX record is verified
        #
        MX => shift,

        #
        # 
        #
        DMARC => shift,

        #
        # True, if tracking CNAME record is verified
        #
        IsRewriteDomainValid => shift,

        #
        # True, if verification is available
        #
        Verify => shift,

        #
        # 
        #
        Type => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Detailed information about email credits
    # 
    package ApiTypes::EmailCredits;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Date in YYYY-MM-DDThh:ii:ss format
        #
        Date => shift,

        #
        # Amount of money in transaction
        #
        Amount => shift,

        #
        # Source of URL of payment
        #
        Source => shift,

        #
        # Free form field of notes
        #
        Notes => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::EmailJobFailedStatus;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # 
        #
        Address => shift,

        #
        # 
        #
        Error => shift,

        #
        # RFC Error code
        #
        ErrorCode => shift,

        #
        # 
        #
        Category => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::EmailJobStatus;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # ID number of your attachment
        #
        ID => shift,

        #
        # Name of status: submitted, complete, in_progress
        #
        Status => shift,

        #
        # 
        #
        RecipientsCount => shift,

        #
        # 
        #
        Failed => shift,

        #
        # Total emails sent.
        #
        FailedCount => shift,

        #
        # Number of delivered messages
        #
        Delivered => shift,

        #
        # 
        #
        DeliveredCount => shift,

        #
        # 
        #
        Pending => shift,

        #
        # 
        #
        PendingCount => shift,

        #
        # Number of opened messages
        #
        Opened => shift,

        #
        # Total emails opened.
        #
        OpenedCount => shift,

        #
        # Number of clicked messages
        #
        Clicked => shift,

        #
        # Total emails clicked
        #
        ClickedCount => shift,

        #
        # Number of unsubscribed messages
        #
        Unsubscribed => shift,

        #
        # Total emails clicked
        #
        UnsubscribedCount => shift,

        #
        # 
        #
        AbuseReports => shift,

        #
        # 
        #
        AbuseReportsCount => shift,

        #
        # List of all MessageIDs for this job.
        #
        MessageIDs => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::EmailSend;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # ID number of transaction
        #
        TransactionID => shift,

        #
        # Unique identifier for this email.
        #
        MessageID => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Status information of the specified email
    # 
    package ApiTypes::EmailStatus;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Email address this email was sent from.
        #
        From => shift,

        #
        # Email address this email was sent to.
        #
        To => shift,

        #
        # Date the email was submitted.
        #
        Date => shift,

        #
        # Value of email's status
        #
        Status => shift,

        #
        # Name of email's status
        #
        StatusName => shift,

        #
        # Date of last status change.
        #
        StatusChangeDate => shift,

        #
        # Detailed error or bounced message.
        #
        ErrorMessage => shift,

        #
        # ID number of transaction
        #
        TransactionID => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Email details formatted in json
    # 
    package ApiTypes::EmailView;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Body (text) of your message.
        #
        Body => shift,

        #
        # Default subject of email.
        #
        Subject => shift,

        #
        # Starting date for search in YYYY-MM-DDThh:mm:ss format.
        #
        From => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Encoding type for the email headers
    # 
    package ApiTypes::EncodingType;
    use constant {
        #
        # Encoding of the email is provided by the sender and not altered.
        #
        USERPROVIDED => '-1',

        #
        # No endcoding is set for the email.
        #
        EENONE => '0',

        #
        # Encoding of the email is in Raw7bit format.
        #
        RAW7BIT => '1',

        #
        # Encoding of the email is in Raw8bit format.
        #
        RAW8BIT => '2',

        #
        # Encoding of the email is in QuotedPrintable format.
        #
        QUOTEDPRINTABLE => '3',

        #
        # Encoding of the email is in Base64 format.
        #
        BASE64 => '4',

        #
        # Encoding of the email is in Uue format.
        #
        UUE => '5',

    };

    # 
    # Record of exported data from the system.
    # 
    package ApiTypes::Export;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # 
        #
        PublicExportID => shift,

        #
        # Date the export was created
        #
        DateAdded => shift,

        #
        # Type of export
        #
        Type => shift,

        #
        # Current status of export
        #
        Status => shift,

        #
        # Long description of the export
        #
        Info => shift,

        #
        # Name of the file
        #
        Filename => shift,

        #
        # Link to download the export
        #
        Link => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Type of export
    # 
    package ApiTypes::ExportFileFormats;
    use constant {
        #
        # Export in comma separated values format.
        #
        CSV => '1',

        #
        # Export in xml format
        #
        XML => '2',

        #
        # Export in json format
        #
        JSON => '3',

    };

    # 
    # 
    # 
    package ApiTypes::ExportLink;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Direct URL to the exported file
        #
        Link => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Current status of export
    # 
    package ApiTypes::ExportStatus;
    use constant {
        #
        # Export had an error and can not be downloaded.
        #
        ERROR => '-1',

        #
        # Export is currently loading and can not be downloaded.
        #
        LOADING => '0',

        #
        # Export is currently available for downloading.
        #
        READY => '1',

        #
        # Export is no longer available for downloading.
        #
        EXPIRED => '2',

    };

    # 
    # Number of Exports, grouped by export type
    # 
    package ApiTypes::ExportTypeCounts;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # 
        #
        Log => shift,

        #
        # 
        #
        Contact => shift,

        #
        # Json representation of a campaign
        #
        Campaign => shift,

        #
        # True, if you have enabled link tracking. Otherwise, false
        #
        LinkTracking => shift,

        #
        # Json representation of a survey
        #
        Survey => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Object containig tracking data.
    # 
    package ApiTypes::LinkTrackingDetails;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Number of items.
        #
        Count => shift,

        #
        # True, if there are more detailed data available. Otherwise, false
        #
        MoreAvailable => shift,

        #
        # 
        #
        TrackedLink => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # List of Contacts, with detailed data about its contents.
    # 
    package ApiTypes::List;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # ID number of selected list.
        #
        ListID => shift,

        #
        # Name of your list.
        #
        ListName => shift,

        #
        # Number of items.
        #
        Count => shift,

        #
        # ID code of list
        #
        PublicListID => shift,

        #
        # Date of creation in YYYY-MM-DDThh:ii:ss format
        #
        DateAdded => shift,

        #
        # True: Allow unsubscribing from this list. Otherwise, false
        #
        AllowUnsubscribe => shift,

        #
        # Query used for filtering.
        #
        Rule => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Detailed information about litmus credits
    # 
    package ApiTypes::LitmusCredits;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Date in YYYY-MM-DDThh:ii:ss format
        #
        Date => shift,

        #
        # Amount of money in transaction
        #
        Amount => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Logs for selected date range
    # 
    package ApiTypes::Log;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Starting date for search in YYYY-MM-DDThh:mm:ss format.
        #
        From => shift,

        #
        # Ending date for search in YYYY-MM-DDThh:mm:ss format.
        #
        To => shift,

        #
        # Number of recipients
        #
        Recipients => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::LogJobStatus;
    use constant {
        #
        # Email has been submitted successfully and is queued for sending.
        #
        READYTOSEND => '1',

        #
        # Email has soft bounced and is scheduled to retry.
        #
        WAITINGTORETRY => '2',

        #
        # Email is currently sending.
        #
        SENDING => '3',

        #
        # Email has errored or bounced for some reason.
        #
        ERROR => '4',

        #
        # Email has been successfully delivered.
        #
        SENT => '5',

        #
        # Email has been opened by the recipient.
        #
        OPENED => '6',

        #
        # Email has had at least one link clicked by the recipient.
        #
        CLICKED => '7',

        #
        # Email has been unsubscribed by the recipient.
        #
        UNSUBSCRIBED => '8',

        #
        # Email has been complained about or marked as spam by the recipient.
        #
        ABUSEREPORT => '9',

    };

    # 
    # Summary of log status, based on specified date range.
    # 
    package ApiTypes::LogStatusSummary;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Starting date for search in YYYY-MM-DDThh:mm:ss format.
        #
        From => shift,

        #
        # Ending date for search in YYYY-MM-DDThh:mm:ss format.
        #
        To => shift,

        #
        # Overall duration
        #
        Duration => shift,

        #
        # Number of recipients
        #
        Recipients => shift,

        #
        # Number of emails
        #
        EmailTotal => shift,

        #
        # Number of SMS
        #
        SmsTotal => shift,

        #
        # Number of delivered messages
        #
        Delivered => shift,

        #
        # Number of bounced messages
        #
        Bounced => shift,

        #
        # Number of messages in progress
        #
        InProgress => shift,

        #
        # Number of opened messages
        #
        Opened => shift,

        #
        # Number of clicked messages
        #
        Clicked => shift,

        #
        # Number of unsubscribed messages
        #
        Unsubscribed => shift,

        #
        # Number of complaint messages
        #
        Complaints => shift,

        #
        # Number of inbound messages
        #
        Inbound => shift,

        #
        # Number of manually cancelled messages
        #
        ManualCancel => shift,

        #
        # Number of messages flagged with 'Not Delivered'
        #
        NotDelivered => shift,

        #
        # ID number of template used
        #
        TemplateChannel => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Overall log summary information.
    # 
    package ApiTypes::LogSummary;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Summary of log status, based on specified date range.
        #
        LogStatusSummary => shift,

        #
        # Summary of bounced categories, based on specified date range.
        #
        BouncedCategorySummary => shift,

        #
        # Daily summary of log status, based on specified date range.
        #
        DailyLogStatusSummary => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::MessageCategory;
    use constant {
        #
        # 
        #
        UNKNOWN => '0',

        #
        # 
        #
        IGNORE => '1',

        #
        # Number of messages marked as SPAM
        #
        SPAM => '2',

        #
        # Number of blacklisted messages
        #
        BLACKLISTED => '3',

        #
        # Number of messages flagged with 'No Mailbox'
        #
        NOMAILBOX => '4',

        #
        # Number of messages flagged with 'Grey Listed'
        #
        GREYLISTED => '5',

        #
        # Number of messages flagged with 'Throttled'
        #
        THROTTLED => '6',

        #
        # Number of messages flagged with 'Timeout'
        #
        TIMEOUT => '7',

        #
        # Number of messages flagged with 'Connection Problem'
        #
        CONNECTIONPROBLEM => '8',

        #
        # Number of messages flagged with 'SPF Problem'
        #
        SPFPROBLEM => '9',

        #
        # Number of messages flagged with 'Account Problem'
        #
        ACCOUNTPROBLEM => '10',

        #
        # Number of messages flagged with 'DNS Problem'
        #
        DNSPROBLEM => '11',

        #
        # 
        #
        NOTDELIVEREDCANCELLED => '12',

        #
        # Number of messages flagged with 'Code Error'
        #
        CODEERROR => '13',

        #
        # Number of manually cancelled messages
        #
        MANUALCANCEL => '14',

        #
        # Number of messages flagged with 'Connection terminated'
        #
        CONNECTIONTERMINATED => '15',

        #
        # Number of messages flagged with 'Not Delivered'
        #
        NOTDELIVERED => '16',

    };

    # 
    # Queue of notifications
    # 
    package ApiTypes::NotificationQueue;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Creation date.
        #
        DateCreated => shift,

        #
        # Date of last status change.
        #
        StatusChangeDate => shift,

        #
        # Actual status.
        #
        NewStatus => shift,

        #
        # 
        #
        Reference => shift,

        #
        # Error message.
        #
        ErrorMessage => shift,

        #
        # Number of previous delivery attempts
        #
        RetryCount => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Detailed information about existing money transfers.
    # 
    package ApiTypes::Payment;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Date in YYYY-MM-DDThh:ii:ss format
        #
        Date => shift,

        #
        # Amount of money in transaction
        #
        Amount => shift,

        #
        # Source of URL of payment
        #
        Source => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Basic information about your profile
    # 
    package ApiTypes::Profile;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # First name.
        #
        FirstName => shift,

        #
        # Last name.
        #
        LastName => shift,

        #
        # Company name.
        #
        Company => shift,

        #
        # First line of address.
        #
        Address1 => shift,

        #
        # Second line of address.
        #
        Address2 => shift,

        #
        # City.
        #
        City => shift,

        #
        # State or province.
        #
        State => shift,

        #
        # Zip/postal code.
        #
        Zip => shift,

        #
        # Numeric ID of country. A file with the list of countries is available <a href="http://api.elasticemail.com/public/countries"><b>here</b></a>
        #
        CountryID => shift,

        #
        # Phone number
        #
        Phone => shift,

        #
        # Proper email address.
        #
        Email => shift,

        #
        # Code used for tax purposes.
        #
        TaxCode => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::QuestionType;
    use constant {
        #
        # 
        #
        RADIOBUTTONS => '1',

        #
        # 
        #
        DROPDOWNMENU => '2',

        #
        # 
        #
        CHECKBOXES => '3',

        #
        # 
        #
        LONGANSWER => '4',

        #
        # 
        #
        TEXTBOX => '5',

        #
        # Date in YYYY-MM-DDThh:ii:ss format
        #
        DATE => '6',

    };

    # 
    # Detailed information about message recipient
    # 
    package ApiTypes::Recipient;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # True, if message is SMS. Otherwise, false
        #
        IsSms => shift,

        #
        # ID number of selected message.
        #
        MsgID => shift,

        #
        # Ending date for search in YYYY-MM-DDThh:mm:ss format.
        #
        To => shift,

        #
        # Name of recipient's status: Submitted, ReadyToSend, WaitingToRetry, Sending, Bounced, Sent, Opened, Clicked, Unsubscribed, AbuseReport
        #
        Status => shift,

        #
        # Name of selected Channel.
        #
        Channel => shift,

        #
        # Date in YYYY-MM-DDThh:ii:ss format
        #
        Date => shift,

        #
        # Content of message, HTML encoded
        #
        Message => shift,

        #
        # True, if message category should be shown. Otherwise, false
        #
        ShowCategory => shift,

        #
        # Name of message category
        #
        MessageCategory => shift,

        #
        # ID of message category
        #
        MessageCategoryID => shift,

        #
        # Date of last status change.
        #
        StatusChangeDate => shift,

        #
        # Date of next try
        #
        NextTryOn => shift,

        #
        # Default subject of email.
        #
        Subject => shift,

        #
        # Default From: email address.
        #
        FromEmail => shift,

        #
        # ID of certain mail job
        #
        JobID => shift,

        #
        # True, if message is a SMS and status is not yet confirmed. Otherwise, false
        #
        SmsUpdateRequired => shift,

        #
        # Content of message
        #
        TextMessage => shift,

        #
        # Comma separated ID numbers of messages.
        #
        MessageSid => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Referral details for this account.
    # 
    package ApiTypes::Referral;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Current amount of dolars you have from referring.
        #
        CurrentReferralCredit => shift,

        #
        # Number of active referrals.
        #
        CurrentReferralCount => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Detailed sending reputation of your account.
    # 
    package ApiTypes::ReputationDetail;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Overall reputation impact, based on the most important factors.
        #
        Impact => shift,

        #
        # Percent of Complaining users - those, who do not want to receive email from you.
        #
        AbusePercent => shift,

        #
        # Percent of Unknown users - users that couldn't be found
        #
        UnknownUsersPercent => shift,

        #
        # 
        #
        OpenedPercent => shift,

        #
        # 
        #
        ClickedPercent => shift,

        #
        # Penalty from messages marked as spam.
        #
        AverageSpamScore => shift,

        #
        # Percent of Bounced users
        #
        FailedSpamPercent => shift,

        #
        # Points from quantity of your emails.
        #
        RepEmailsSent => shift,

        #
        # Average reputation.
        #
        AverageReputation => shift,

        #
        # Actual price level.
        #
        PriceLevelReputation => shift,

        #
        # Reputation needed to change pricing.
        #
        NextPriceLevelReputation => shift,

        #
        # Amount of emails sent from this account
        #
        PriceLevel => shift,

        #
        # True, if tracking domain is correctly configured. Otherwise, false.
        #
        TrackingDomainValid => shift,

        #
        # True, if sending domain is correctly configured. Otherwise, false.
        #
        SenderDomainValid => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Reputation history of your account.
    # 
    package ApiTypes::ReputationHistory;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Creation date.
        #
        DateCreated => shift,

        #
        # Percent of Complaining users - those, who do not want to receive email from you.
        #
        AbusePercent => shift,

        #
        # Percent of Unknown users - users that couldn't be found
        #
        UnknownUsersPercent => shift,

        #
        # 
        #
        OpenedPercent => shift,

        #
        # 
        #
        ClickedPercent => shift,

        #
        # Penalty from messages marked as spam.
        #
        AverageSpamScore => shift,

        #
        # Points from proper setup of your account
        #
        SetupScore => shift,

        #
        # Points from quantity of your emails.
        #
        RepEmailsSent => shift,

        #
        # Numeric reputation
        #
        Reputation => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Overall reputation impact, based on the most important factors.
    # 
    package ApiTypes::ReputationImpact;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Abuses - mails sent to user without their consent
        #
        Abuse => shift,

        #
        # Users, that could not be reached.
        #
        UnknownUsers => shift,

        #
        # Number of opened messages
        #
        Opened => shift,

        #
        # Number of clicked messages
        #
        Clicked => shift,

        #
        # Penalty from messages marked as spam.
        #
        AverageSpamScore => shift,

        #
        # Content analysis.
        #
        ServerFilter => shift,

        #
        # Tracking domain.
        #
        TrackingDomain => shift,

        #
        # Sending domain.
        #
        SenderDomain => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Information about Contact Segment, selected by RULE.
    # 
    package ApiTypes::Segment;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # ID number of your segment.
        #
        SegmentID => shift,

        #
        # Filename
        #
        Name => shift,

        #
        # Query used for filtering.
        #
        Rule => shift,

        #
        # Number of items from last check.
        #
        LastCount => shift,

        #
        # History of segment information.
        #
        History => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Segment History
    # 
    package ApiTypes::SegmentHistory;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # ID number of history.
        #
        SegmentHistoryID => shift,

        #
        # ID number of your segment.
        #
        SegmentID => shift,

        #
        # Date in YYYY-MM-DD format
        #
        Day => shift,

        #
        # Number of items.
        #
        Count => shift,

        #
        # 
        #
        EngagedCount => shift,

        #
        # 
        #
        ActiveCount => shift,

        #
        # 
        #
        BouncedCount => shift,

        #
        # Total emails clicked
        #
        UnsubscribedCount => shift,

        #
        # 
        #
        AbuseCount => shift,

        #
        # 
        #
        InactiveCount => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::SendingPermission;
    use constant {
        #
        # Sending not allowed.
        #
        EENONE => '0',

        #
        # Allow sending via SMTP only.
        #
        SMTP => '1',

        #
        # Allow sending via HTTP API only.
        #
        HTTPAPI => '2',

        #
        # Allow sending via SMTP and HTTP API.
        #
        SMTPANDHTTPAPI => '3',

        #
        # Allow sending via the website interface only.
        #
        INTERFACE => '4',

        #
        # Allow sending via SMTP and the website interface.
        #
        SMTPANDINTERFACE => '5',

        #
        # Allow sendnig via HTTP API and the website interface.
        #
        HTTPAPIANDINTERFACE => '6',

        #
        # Sending allowed via SMTP, HTTP API and the website interface.
        #
        ALL => '255',

    };

    # 
    # Spam check of specified message.
    # 
    package ApiTypes::SpamCheck;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Total spam score from
        #
        TotalScore => shift,

        #
        # Date in YYYY-MM-DDThh:ii:ss format
        #
        Date => shift,

        #
        # Default subject of email.
        #
        Subject => shift,

        #
        # Default From: email address.
        #
        FromEmail => shift,

        #
        # ID number of selected message.
        #
        MsgID => shift,

        #
        # Name of selected channel.
        #
        ChannelName => shift,

        #
        # 
        #
        Rules => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Single spam score
    # 
    package ApiTypes::SpamRule;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Spam score
        #
        Score => shift,

        #
        # Name of rule
        #
        Key => shift,

        #
        # Description of rule.
        #
        Description => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::SplitOptimization;
    use constant {
        #
        # Number of opened messages
        #
        OPENED => '0',

        #
        # Number of clicked messages
        #
        CLICKED => '1',

    };

    # 
    # Subaccount. Contains detailed data of your Subaccount.
    # 
    package ApiTypes::SubAccount;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Public key for limited access to your account such as contact/add so you can use it safely on public websites.
        #
        PublicAccountID => shift,

        #
        # ApiKey that gives you access to our SMTP and HTTP API's.
        #
        ApiKey => shift,

        #
        # Proper email address.
        #
        Email => shift,

        #
        # ID number of mailer
        #
        MailerID => shift,

        #
        # Name of your custom IP Pool to be used in the sending process
        #
        PoolName => shift,

        #
        # Date of last activity on account
        #
        LastActivity => shift,

        #
        # Amount of email credits
        #
        EmailCredits => shift,

        #
        # True, if account needs credits to send emails. Otherwise, false
        #
        RequiresEmailCredits => shift,

        #
        # Amount of credits added to account automatically
        #
        MonthlyRefillCredits => shift,

        #
        # True, if account needs credits to buy templates. Otherwise, false
        #
        RequiresTemplateCredits => shift,

        #
        # Amount of Litmus credits
        #
        LitmusCredits => shift,

        #
        # True, if account is able to send template tests to Litmus. Otherwise, false
        #
        EnableLitmusTest => shift,

        #
        # True, if account needs credits to send emails. Otherwise, false
        #
        RequiresLitmusCredits => shift,

        #
        # True, if account can buy templates on its own. Otherwise, false
        #
        EnablePremiumTemplates => shift,

        #
        # True, if account can request for private IP on its own. Otherwise, false
        #
        EnablePrivateIPRequest => shift,

        #
        # Amount of emails sent from this account
        #
        TotalEmailsSent => shift,

        #
        # Percent of Unknown users - users that couldn't be found
        #
        UnknownUsersPercent => shift,

        #
        # Percent of Complaining users - those, who do not want to receive email from you.
        #
        AbusePercent => shift,

        #
        # Percent of Bounced users
        #
        FailedSpamPercent => shift,

        #
        # Numeric reputation
        #
        Reputation => shift,

        #
        # Amount of emails account can send daily
        #
        DailySendLimit => shift,

        #
        # Name of account's status: Deleted, Disabled, UnderReview, NoPaymentsAllowed, NeverSignedIn, Active, SystemPaused
        #
        Status => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Detailed account settings.
    # 
    package ApiTypes::SubAccountSettings;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Proper email address.
        #
        Email => shift,

        #
        # True, if account needs credits to send emails. Otherwise, false
        #
        RequiresEmailCredits => shift,

        #
        # True, if account needs credits to buy templates. Otherwise, false
        #
        RequiresTemplateCredits => shift,

        #
        # Amount of credits added to account automatically
        #
        MonthlyRefillCredits => shift,

        #
        # Amount of Litmus credits
        #
        LitmusCredits => shift,

        #
        # True, if account is able to send template tests to Litmus. Otherwise, false
        #
        EnableLitmusTest => shift,

        #
        # True, if account needs credits to send emails. Otherwise, false
        #
        RequiresLitmusCredits => shift,

        #
        # Maximum size of email including attachments in MB's
        #
        EmailSizeLimit => shift,

        #
        # Amount of emails account can send daily
        #
        DailySendLimit => shift,

        #
        # Maximum number of contacts the account can have
        #
        MaxContacts => shift,

        #
        # True, if account can request for private IP on its own. Otherwise, false
        #
        EnablePrivateIPRequest => shift,

        #
        # True, if you want to use Advanced Tools.  Otherwise, false
        #
        EnableContactFeatures => shift,

        #
        # Sending permission setting for account
        #
        SendingPermission => shift,

        #
        # Name of your custom IP Pool to be used in the sending process
        #
        PoolName => shift,

        #
        # Public key for limited access to your account such as contact/add so you can use it safely on public websites.
        #
        PublicAccountID => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # A survey object
    # 
    package ApiTypes::Survey;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Survey identifier
        #
        PublicSurveyID => shift,

        #
        # Creation date.
        #
        DateCreated => shift,

        #
        # Last change date
        #
        DateUpdated => shift,

        #
        # Filename
        #
        Name => shift,

        #
        # Activate, delete, or pause your survey
        #
        Status => shift,

        #
        # Number of results count
        #
        ResultCount => shift,

        #
        # Survey's steps info
        #
        SurveyStep => shift,

        #
        # URL of the survey
        #
        SurveyLink => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Object with the single answer's data
    # 
    package ApiTypes::SurveyResultAnswerInfo;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Answer's content
        #
        content => shift,

        #
        # Identifier of the step
        #
        surveystepid => shift,

        #
        # Identifier of the answer of the step
        #
        surveystepanswerid => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Single answer's data with user's specific info
    # 
    package ApiTypes::SurveyResultInfo;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Identifier of the result
        #
        SurveyResultID => shift,

        #
        # IP address
        #
        CreatedFromIP => shift,

        #
        # Completion date
        #
        DateCompleted => shift,

        #
        # Start date
        #
        DateStart => shift,

        #
        # Answers for the survey
        #
        SurveyResultAnswers => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Summary with all the answers
    # 
    package ApiTypes::SurveyResultsSummary;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Answers' statistics
        #
        Answers => shift,

        #
        # Open answers for the question
        #
        OpenAnswers => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Data on the survey's result
    # 
    package ApiTypes::SurveyResultsSummaryInfo;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Number of items.
        #
        Count => shift,

        #
        # Summary statistics
        #
        Summary => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::SurveyStatus;
    use constant {
        #
        # The survey is deleted
        #
        DELETED => '-1',

        #
        # The survey is not receiving result for now
        #
        PAUSED => '0',

        #
        # The survey is active and receiving answers
        #
        ACTIVE => '1',

    };

    # 
    # Survey's single step info with the answers
    # 
    package ApiTypes::SurveyStep;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Identifier of the step
        #
        SurveyStepID => shift,

        #
        # Type of the step
        #
        SurveyStepType => shift,

        #
        # Type of the question
        #
        QuestionType => shift,

        #
        # Answer's content
        #
        Content => shift,

        #
        # Is the answer required
        #
        Required => shift,

        #
        # Sequence of the answers
        #
        Sequence => shift,

        #
        # Answer object of the step
        #
        SurveyStepAnswer => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # Single step's answer object
    # 
    package ApiTypes::SurveyStepAnswer;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # Identifier of the answer of the step
        #
        SurveyStepAnswerID => shift,

        #
        # Answer's content
        #
        Content => shift,

        #
        # Sequence of the answers
        #
        Sequence => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::SurveyStepType;
    use constant {
        #
        # 
        #
        PAGEBREAK => '1',

        #
        # 
        #
        QUESTION => '2',

        #
        # 
        #
        TEXTMEDIA => '3',

        #
        # 
        #
        CONFIRMATIONPAGE => '4',

        #
        # 
        #
        EXPIREDPAGE => '5',

    };

    # 
    # Template
    # 
    package ApiTypes::Template;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # ID number of template.
        #
        TemplateID => shift,

        #
        # 0 for API connections
        #
        TemplateType => shift,

        #
        # Filename
        #
        Name => shift,

        #
        # Date of creation in YYYY-MM-DDThh:ii:ss format
        #
        DateAdded => shift,

        #
        # CSS style
        #
        Css => shift,

        #
        # Default subject of email.
        #
        Subject => shift,

        #
        # Default From: email address.
        #
        FromEmail => shift,

        #
        # Default From: name.
        #
        FromName => shift,

        #
        # HTML code of email (needs escaping).
        #
        BodyHtml => shift,

        #
        # Text body of email.
        #
        BodyText => shift,

        #
        # ID number of original template.
        #
        OriginalTemplateID => shift,

        #
        # Enum: 0 - private, 1 - public, 2 - mockup
        #
        TemplateScope => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # List of templates (including drafts)
    # 
    package ApiTypes::TemplateList;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # List of templates
        #
        Templates => shift,

        #
        # List of draft templates
        #
        DraftTemplate => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::TemplateScope;
    use constant {
        #
        # Template is available for this account only.
        #
        PRIVATE => '0',

        #
        # Template is available for this account and it's sub-accounts.
        #
        PUBLIC => '1',

    };

    # 
    # 
    # 
    package ApiTypes::TemplateType;
    use constant {
        #
        # Template supports any valid HTML
        #
        RAWHTML => '0',

        #
        # Template is created and can only be modified in drag and drop editor
        #
        DRAGDROPEDITOR => '1',

    };

    # 
    # Information about tracking link and its clicks.
    # 
    package ApiTypes::TrackedLink;
    sub new
    {
        my $class = shift;
        my $self = {
        #
        # URL clicked
        #
        Link => shift,

        #
        # Number of clicks
        #
        Clicks => shift,

        #
        # Percent of clicks
        #
        Percent => shift,

        };
        bless $self, $class;
        return $self;
    }

    # 
    # 
    # 
    package ApiTypes::TrackingType;
    use constant {
        #
        # 
        #
        HTTP => '0',

        #
        # 
        #
        EXTERNALHTTPS => '1',

    };

    # 
    # Account usage
    # 
    package ApiTypes::Usage;
    sub new
    {
        my $class = shift;
        my $self = {
        };
        bless $self, $class;
        return $self;
    }

# EXAMPLE USAGE: 
#package main;

# my @postFiles = ("localfile.txt", "C:\path\to\file\file.csv");
# my @params = [subject => 'mysubject', body_text => 'Hello World', to => 'example@email.com', from => 'example@email.com', ...more params];
# my $response = Api::Email->Send(@params, @postFiles);
# print $response, "\n"


=head1 NAME

ElasticEmail - The great new ElasticEmail!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use ElasticEmail;

    my $foo = ElasticEmail->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Elastic Email, C<< <support at elasticemail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-elasticemail at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ElasticEmail>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ElasticEmail


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ElasticEmail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ElasticEmail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ElasticEmail>

=item * Search CPAN

L<http://search.cpan.org/dist/ElasticEmail/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Elastic Email.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of ElasticEmail
