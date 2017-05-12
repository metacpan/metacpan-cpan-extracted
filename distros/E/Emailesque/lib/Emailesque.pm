# ABSTRACT: Lightweight To-The-Point Email
package Emailesque;

use Carp;
use File::Slurp;
use Email::AddressParser;
use Email::Sender::Transport::Sendmail;
use Email::Sender::Transport::SMTP;
use Email::Stuffer;
use Hash::Merge::Simple;

use Exporter 'import';
our @EXPORT_OK = qw(email);

use Moo;

our $VERSION = '1.26'; # VERSION

my %headers = map {
    my $name = lc $_;
       $name =~ s/\W+/_/g;
       $name => $_;
}
my @headers = (
    my @kheaders = (
        'Accept-Language',
        'Alternate-Recipient',
        'Apparently-To',
        'Archived-At',
        'Authentication-Results',
        'Auto-Submitted',
        'Autoforwarded',
        'Autosubmitted',
        'Bcc',
        'Cc',
        'Comments',
        'Content-Identifier',
        'Content-Return',
        'Conversion-With-Loss',
        'Conversion',
        'DKIM-Signature',
        'DL-Expansion-History',
        'Date',
        'Deferred-Delivery',
        'Delivery-Date',
        'Discarded-X400-IPMS-Extensions',
        'Discarded-X400-MTS-Extensions',
        'Disclose-Recipients',
        'Disposition-Notification-Options',
        'Disposition-Notification-To',
        'Downgraded-Bcc',
        'Downgraded-Cc',
        'Downgraded-Disposition-Notification-To',
        'Downgraded-Final-Recipient',
        'Downgraded-From',
        'Downgraded-In-Reply-To',
        'Downgraded-Mail-From',
        'Downgraded-Message-Id',
        'Downgraded-Original-Recipient',
        'Downgraded-Rcpt-To',
        'Downgraded-References',
        'Downgraded-Reply-To',
        'Downgraded-Resent-Bcc',
        'Downgraded-Resent-Cc',
        'Downgraded-Resent-From',
        'Downgraded-Resent-Reply-To',
        'Downgraded-Resent-Sender',
        'Downgraded-Resent-To',
        'Downgraded-Return-Path',
        'Downgraded-Sender',
        'Downgraded-To',
        'EDIINT-Features',
        'Encoding',
        'Encrypted',
        'Errors-To',
        'Expires',
        'Expiry-Date',
        'From',
        'Generate-Delivery-Report',
        'Importance',
        'In-Reply-To',
        'Incomplete-Copy',
        'Jabber-ID',
        'Keywords',
        'Language',
        'Latest-Delivery-Time',
        'List-Archive',
        'List-Help',
        'List-ID',
        'List-Owner',
        'List-Post',
        'List-Subscribe',
        'List-Unsubscribe',
        'MMHS-Acp127-Message-Identifier',
        'MMHS-Codress-Message-Indicator',
        'MMHS-Copy-Precedence',
        'MMHS-Exempted-Address',
        'MMHS-Extended-Authorisation-Info',
        'MMHS-Handling-Instructions',
        'MMHS-Message-Instructions',
        'MMHS-Message-Type',
        'MMHS-Originator-PLAD',
        'MMHS-Originator-Reference',
        'MMHS-Other-Recipients-Indicator-CC',
        'MMHS-Other-Recipients-Indicator-To',
        'MMHS-Primary-Precedence',
        'MMHS-Subject-Indicator-Codes',
        'MT-Priority',
        'Message-Context',
        'Message-ID',
        'Message-Type',
        'Obsoletes',
        'Original-Encoded-Information-Types',
        'Original-From',
        'Original-Message-ID',
        'Original-Recipient',
        'Original-Subject',
        'Originator-Return-Address',
        'PICS-Label',
        'Prevent-NonDelivery-Report',
        'Priority',
        'Privicon',
        'Received-SPF',
        'Received',
        'References',
        'Reply-By',
        'Reply-To',
        'Require-Recipient-Valid-Since',
        'Resent-Bcc',
        'Resent-Cc',
        'Resent-Date',
        'Resent-From',
        'Resent-Message-ID',
        'Resent-Reply-To',
        'Resent-Sender',
        'Resent-To',
        'Return-Path',
        'SIO-Label-History',
        'SIO-Label',
        'Sender',
        'Sensitivity',
        'Solicitation',
        'Subject',
        'Supersedes',
        'To',
        'VBR-Info',
        'X-Archived-At',
        'X400-Content-Identifier',
        'X400-Content-Return',
        'X400-Content-Type',
        'X400-MTS-Identifier',
        'X400-Originator',
        'X400-Received',
        'X400-Recipients',
        'X400-Trace',
    ),
    my @xheaders = (
        'X-Abuse-Info',
        'X-Accept-Language',
        'X-Admin',
        'X-Article-Creation-Date',
        'X-Attribution',
        'X-Authenticated-IP',
        'X-Authenticated-Sender',
        'X-Authentication-Warning',
        'X-Cache',
        'X-Comments',
        'X-Complaints-To',
        'X-Confirm-reading-to',
        'X-Envelope-From',
        'X-Envelope-To',
        'X-Face',
        'X-Flags',
        'X-Folder',
        'X-IMAP',
        'X-Last-Updated',
        'X-List-Host',
        'X-Listserver',
        'X-Loop',
        'X-Mailer',
        'X-Mailer-Info',
        'X-Mailing-List',
        'X-MIME-Autoconverted',
        'X-MimeOLE',
        'X-MIMETrack',
        'X-MSMail-Priority',
        'X-MyDeja-Info',
        'X-Newsreader',
        'X-NNTP-Posting-Host',
        'X-No-Archive',
        'X-Notice',
        'X-Orig-Message-ID',
        'X-Original-Envelope-From',
        'X-Original-NNTP-Posting-Host',
        'X-Original-Trace',
        'X-OriginalArrivalTime',
        'X-Originating-IP',
        'X-PMFLAGS',
        'X-Posted-By',
        'X-Posting-Agent',
        'X-Priority',
        'X-RCPT-TO',
        'X-Report',
        'X-Report-Abuse-To',
        'X-Sender',
        'X-Server-Date',
        'X-Trace',
        'X-URI',
        'X-URL',
        'X-X-Sender',
    ),
);

around new => sub {
    my ($orig, $class, @args) = @_;
    my $data = @args % 2 ? $args[0] : {@args};
    $data = {} unless ref($data) eq 'HASH';
    my $self = $class->$orig($data);
    $self->{$_} //= $data->{$_} for keys %{$data};
    return $self;
};

sub email {
    unshift @_, __PACKAGE__->new({}) and goto &send;
}

sub message {
    my ($self, $argument) = @_;
    return $self->{message} = $argument;
}

sub send {
    my ($self, $options, @arguments) = @_;
    my $package = $self->prepare_package($options, @arguments);
    return $package->send;
}

sub accept_language {
    my $name = 'Accept-Language';
    unshift @_, shift, $name and goto &header;
}

sub alternate_recipient {
    my $name = 'Alternate-Recipient';
    unshift @_, shift, $name and goto &header;
}

sub apparently_to {
    my $name = 'Apparently-To';
    unshift @_, shift, $name and goto &header;
}

sub archived_at {
    my $name = 'Archived-At';
    unshift @_, shift, $name and goto &header;
}

sub authentication_results {
    my $name = 'Authentication-Results';
    unshift @_, shift, $name and goto &header;
}

sub auto_submitted {
    my $name = 'Auto-Submitted';
    unshift @_, shift, $name and goto &header;
}

sub autoforwarded {
    my $name = 'Autoforwarded';
    unshift @_, shift, $name and goto &header;
}

sub autosubmitted {
    my $name = 'Autosubmitted';
    unshift @_, shift, $name and goto &header;
}

sub bcc {
    my $name = 'Bcc';
    unshift @_, shift, $name and goto &header;
}

sub cc {
    my $name = 'Cc';
    unshift @_, shift, $name and goto &header;
}

sub comments {
    my $name = 'Comments';
    unshift @_, shift, $name and goto &header;
}

sub content_identifier {
    my $name = 'Content-Identifier';
    unshift @_, shift, $name and goto &header;
}

sub content_return {
    my $name = 'Content-Return';
    unshift @_, shift, $name and goto &header;
}

sub conversion {
    my $name = 'Conversion';
    unshift @_, shift, $name and goto &header;
}

sub conversion_with_loss {
    my $name = 'Conversion-With-Loss';
    unshift @_, shift, $name and goto &header;
}

sub dkim_signature {
    my $name = 'DKIM-Signature';
    unshift @_, shift, $name and goto &header;
}

sub dl_expansion_history {
    my $name = 'DL-Expansion-History';
    unshift @_, shift, $name and goto &header;
}

sub date {
    my $name = 'Date';
    unshift @_, shift, $name and goto &header;
}

sub deferred_delivery {
    my $name = 'Deferred-Delivery';
    unshift @_, shift, $name and goto &header;
}

sub delivery_date {
    my $name = 'Delivery-Date';
    unshift @_, shift, $name and goto &header;
}

sub discarded_x400_ipms_extensions {
    my $name = 'Discarded-X400-IPMS-Extensions';
    unshift @_, shift, $name and goto &header;
}

sub discarded_x400_mts_extensions {
    my $name = 'Discarded-X400-MTS-Extensions';
    unshift @_, shift, $name and goto &header;
}

sub disclose_recipients {
    my $name = 'Disclose-Recipients';
    unshift @_, shift, $name and goto &header;
}

sub disposition_notification_options {
    my $name = 'Disposition-Notification-Options';
    unshift @_, shift, $name and goto &header;
}

sub disposition_notification_to {
    my $name = 'Disposition-Notification-To';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_bcc {
    my $name = 'Downgraded-Bcc';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_cc {
    my $name = 'Downgraded-Cc';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_disposition_notification_to {
    my $name = 'Downgraded-Disposition-Notification-To';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_final_recipient {
    my $name = 'Downgraded-Final-Recipient';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_from {
    my $name = 'Downgraded-From';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_in_reply_to {
    my $name = 'Downgraded-In-Reply-To';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_mail_from {
    my $name = 'Downgraded-Mail-From';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_message_id {
    my $name = 'Downgraded-Message-Id';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_original_recipient {
    my $name = 'Downgraded-Original-Recipient';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_rcpt_to {
    my $name = 'Downgraded-Rcpt-To';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_references {
    my $name = 'Downgraded-References';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_reply_to {
    my $name = 'Downgraded-Reply-To';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_resent_bcc {
    my $name = 'Downgraded-Resent-Bcc';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_resent_cc {
    my $name = 'Downgraded-Resent-Cc';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_resent_from {
    my $name = 'Downgraded-Resent-From';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_resent_reply_to {
    my $name = 'Downgraded-Resent-Reply-To';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_resent_sender {
    my $name = 'Downgraded-Resent-Sender';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_resent_to {
    my $name = 'Downgraded-Resent-To';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_return_path {
    my $name = 'Downgraded-Return-Path';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_sender {
    my $name = 'Downgraded-Sender';
    unshift @_, shift, $name and goto &header;
}

sub downgraded_to {
    my $name = 'Downgraded-To';
    unshift @_, shift, $name and goto &header;
}

sub ediint_features {
    my $name = 'EDIINT-Features';
    unshift @_, shift, $name and goto &header;
}

sub encoding {
    my $name = 'Encoding';
    unshift @_, shift, $name and goto &header;
}

sub encrypted {
    my $name = 'Encrypted';
    unshift @_, shift, $name and goto &header;
}

sub errors_to {
    my $name = 'Errors-To';
    unshift @_, shift, $name and goto &header;
}

sub expires {
    my $name = 'Expires';
    unshift @_, shift, $name and goto &header;
}

sub expiry_date {
    my $name = 'Expiry-Date';
    unshift @_, shift, $name and goto &header;
}

sub from {
    my $name = 'From';
    unshift @_, shift, $name and goto &header;
}

sub generate_delivery_report {
    my $name = 'Generate-Delivery-Report';
    unshift @_, shift, $name and goto &header;
}

sub importance {
    my $name = 'Importance';
    unshift @_, shift, $name and goto &header;
}

sub in_reply_to {
    my $name = 'In-Reply-To';
    unshift @_, shift, $name and goto &header;
}

sub incomplete_copy {
    my $name = 'Incomplete-Copy';
    unshift @_, shift, $name and goto &header;
}

sub jabber_id {
    my $name = 'Jabber-ID';
    unshift @_, shift, $name and goto &header;
}

sub keywords {
    my $name = 'Keywords';
    unshift @_, shift, $name and goto &header;
}

sub language {
    my $name = 'Language';
    unshift @_, shift, $name and goto &header;
}

sub latest_delivery_time {
    my $name = 'Latest-Delivery-Time';
    unshift @_, shift, $name and goto &header;
}

sub list_archive {
    my $name = 'List-Archive';
    unshift @_, shift, $name and goto &header;
}

sub list_help {
    my $name = 'List-Help';
    unshift @_, shift, $name and goto &header;
}

sub list_id {
    my $name = 'List-ID';
    unshift @_, shift, $name and goto &header;
}

sub list_owner {
    my $name = 'List-Owner';
    unshift @_, shift, $name and goto &header;
}

sub list_post {
    my $name = 'List-Post';
    unshift @_, shift, $name and goto &header;
}

sub list_subscribe {
    my $name = 'List-Subscribe';
    unshift @_, shift, $name and goto &header;
}

sub list_unsubscribe {
    my $name = 'List-Unsubscribe';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_acp127_message_identifier {
    my $name = 'MMHS-Acp127-Message-Identifier';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_codress_message_indicator {
    my $name = 'MMHS-Codress-Message-Indicator';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_copy_precedence {
    my $name = 'MMHS-Copy-Precedence';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_exempted_address {
    my $name = 'MMHS-Exempted-Address';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_extended_authorisation_info {
    my $name = 'MMHS-Extended-Authorisation-Info';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_handling_instructions {
    my $name = 'MMHS-Handling-Instructions';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_message_instructions {
    my $name = 'MMHS-Message-Instructions';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_message_type {
    my $name = 'MMHS-Message-Type';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_originator_plad {
    my $name = 'MMHS-Originator-PLAD';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_originator_reference {
    my $name = 'MMHS-Originator-Reference';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_other_recipients_indicator_cc {
    my $name = 'MMHS-Other-Recipients-Indicator-CC';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_other_recipients_indicator_to {
    my $name = 'MMHS-Other-Recipients-Indicator-To';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_primary_precedence {
    my $name = 'MMHS-Primary-Precedence';
    unshift @_, shift, $name and goto &header;
}

sub mmhs_subject_indicator_codes {
    my $name = 'MMHS-Subject-Indicator-Codes';
    unshift @_, shift, $name and goto &header;
}

sub mt_priority {
    my $name = 'MT-Priority';
    unshift @_, shift, $name and goto &header;
}

sub message_context {
    my $name = 'Message-Context';
    unshift @_, shift, $name and goto &header;
}

sub message_id {
    my $name = 'Message-ID';
    unshift @_, shift, $name and goto &header;
}

sub message_type {
    my $name = 'Message-Type';
    unshift @_, shift, $name and goto &header;
}

sub obsoletes {
    my $name = 'Obsoletes';
    unshift @_, shift, $name and goto &header;
}

sub original_encoded_information_types {
    my $name = 'Original-Encoded-Information-Types';
    unshift @_, shift, $name and goto &header;
}

sub original_from {
    my $name = 'Original-From';
    unshift @_, shift, $name and goto &header;
}

sub original_message_id {
    my $name = 'Original-Message-ID';
    unshift @_, shift, $name and goto &header;
}

sub original_recipient {
    my $name = 'Original-Recipient';
    unshift @_, shift, $name and goto &header;
}

sub original_subject {
    my $name = 'Original-Subject';
    unshift @_, shift, $name and goto &header;
}

sub originator_return_address {
    my $name = 'Originator-Return-Address';
    unshift @_, shift, $name and goto &header;
}

sub pics_label {
    my $name = 'PICS-Label';
    unshift @_, shift, $name and goto &header;
}

sub prevent_nondelivery_report {
    my $name = 'Prevent-NonDelivery-Report';
    unshift @_, shift, $name and goto &header;
}

sub priority {
    my $name = 'Priority';
    unshift @_, shift, $name and goto &header;
}

sub privicon {
    my $name = 'Privicon';
    unshift @_, shift, $name and goto &header;
}

sub received {
    my $name = 'Received';
    unshift @_, shift, $name and goto &header;
}

sub received_spf {
    my $name = 'Received-SPF';
    unshift @_, shift, $name and goto &header;
}

sub references {
    my $name = 'References';
    unshift @_, shift, $name and goto &header;
}

sub reply_by {
    my $name = 'Reply-By';
    unshift @_, shift, $name and goto &header;
}

sub reply_to {
    my $name = 'Reply-To';
    unshift @_, shift, $name and goto &header;
}

sub require_recipient_valid_since {
    my $name = 'Require-Recipient-Valid-Since';
    unshift @_, shift, $name and goto &header;
}

sub resent_bcc {
    my $name = 'Resent-Bcc';
    unshift @_, shift, $name and goto &header;
}

sub resent_cc {
    my $name = 'Resent-Cc';
    unshift @_, shift, $name and goto &header;
}

sub resent_date {
    my $name = 'Resent-Date';
    unshift @_, shift, $name and goto &header;
}

sub resent_from {
    my $name = 'Resent-From';
    unshift @_, shift, $name and goto &header;
}

sub resent_message_id {
    my $name = 'Resent-Message-ID';
    unshift @_, shift, $name and goto &header;
}

sub resent_reply_to {
    my $name = 'Resent-Reply-To';
    unshift @_, shift, $name and goto &header;
}

sub resent_sender {
    my $name = 'Resent-Sender';
    unshift @_, shift, $name and goto &header;
}

sub resent_to {
    my $name = 'Resent-To';
    unshift @_, shift, $name and goto &header;
}

sub return_path {
    my $name = 'Return-Path';
    unshift @_, shift, $name and goto &header;
}

sub sio_label {
    my $name = 'SIO-Label';
    unshift @_, shift, $name and goto &header;
}

sub sio_label_history {
    my $name = 'SIO-Label-History';
    unshift @_, shift, $name and goto &header;
}

sub sender {
    my $name = 'Sender';
    unshift @_, shift, $name and goto &header;
}

sub sensitivity {
    my $name = 'Sensitivity';
    unshift @_, shift, $name and goto &header;
}

sub solicitation {
    my $name = 'Solicitation';
    unshift @_, shift, $name and goto &header;
}

sub subject {
    my $name = 'Subject';
    unshift @_, shift, $name and goto &header;
}

sub supersedes {
    my $name = 'Supersedes';
    unshift @_, shift, $name and goto &header;
}

sub to {
    my $name = 'To';
    unshift @_, shift, $name and goto &header;
}

sub vbr_info {
    my $name = 'VBR-Info';
    unshift @_, shift, $name and goto &header;
}

sub x_archived_at {
    my $name = 'X-Archived-At';
    unshift @_, shift, $name and goto &header;
}

sub x400_content_identifier {
    my $name = 'X400-Content-Identifier';
    unshift @_, shift, $name and goto &header;
}

sub x400_content_return {
    my $name = 'X400-Content-Return';
    unshift @_, shift, $name and goto &header;
}

sub x400_content_type {
    my $name = 'X400-Content-Type';
    unshift @_, shift, $name and goto &header;
}

sub x400_mts_identifier {
    my $name = 'X400-MTS-Identifier';
    unshift @_, shift, $name and goto &header;
}

sub x400_originator {
    my $name = 'X400-Originator';
    unshift @_, shift, $name and goto &header;
}

sub x400_received {
    my $name = 'X400-Received';
    unshift @_, shift, $name and goto &header;
}

sub x400_recipients {
    my $name = 'X400-Recipients';
    unshift @_, shift, $name and goto &header;
}

sub x400_trace {
    my $name = 'X400-Trace';
    unshift @_, shift, $name and goto &header;
}

sub header {
    my ($self, $name) = (shift, shift);
    $name = $headers{$name} // $name;

    my $headers = $self->{headers} //= {};

    return $headers->{$name} = shift if @_;
    return $headers->{$name};
}

sub prepare_address {
    my ($self, $field, @arguments) = @_;

    my $headers = $self->{headers} //= {};
    my $value   = $headers->{$field};

    return join ",", map $_->format, Email::AddressParser->parse(
        ref($value) eq 'ARRAY' ? join(',',@{$value}) : $value
    );
}

sub prepare_package {
    my ($self, $options, @arguments) = @_;
$DB::single=1;
    $options = Hash::Merge::Simple::merge($self, $options // {});

    my $stuff = Email::Stuffer->new;
    my $email = __PACKAGE__->new();

    $email->{$_} = $options->{$_} for keys %{$options};

    # remap references
    $_[0] = $self = $email;

    # configure headers
    my $headers = $email->{headers} //= {};

    # extract headers
    for my $key (keys %headers) {
        my $name  = $headers{$key};
        my $value = delete $email->{$key} or next;
        $headers->{$name} = $value if $name and not defined $headers->{$name};
    }

    # required fields
    my @required = @{$headers}{qw(From Subject To)};
    confess "Can't send email without a to, from, and subject property"
        unless @required == 3;

    # process address headers
    my @address_headers = qw(
        Abuse-Reports-To
        Apparently-To
        Delivered-To
        Disposition-Notification-To
        Errors-To
        Followup-To
        In-Reply-To
        Mail-Copies-To
        Posted-To
        Read-Receipt-To
        Resent-Reply-To
        Resent-To
        Return-Receipt-To
    );
    for my $key (qw(Cc Bcc From Reply-To To), @address_headers) {
        $stuff->header($key => $email->prepare_address($key))
            if defined $headers->{$key};
    }

    # process subject
    $stuff->subject($headers->{Subject}) if defined $headers->{Subject};

    # process message
    if (defined $email->{message}) {
        my $type     = $email->{type};
        my $message  = $email->{message};

        my $multi = ref($email->{message}) eq 'HASH';

        my $html_msg = $email->{message}{html} if $multi;
        my $text_msg = $email->{message}{text} if $multi;

        # multipart send using plain text and html
        if (($type and lc($type) eq 'multi') or ($html_msg and $text_msg)) {
            $stuff->html_body("$html_msg") if defined $html_msg;
            $stuff->text_body("$text_msg") if defined $text_msg;
        }
        elsif (($type and lc($type) ne 'multi') and $message) {
            # standard send using html or plain text
            $stuff->html_body("$message") if $type and $type eq 'html';
            $stuff->text_body("$message") if $type and $type eq 'text';
        }
        else {
            $stuff->text_body("$message");
        }
    }

    confess "Can't send email without a message property"
        unless defined $email->{message};

    # process additional headers
    my %excluded_headers = map { $_ => 1 } @address_headers, qw(
        Cc
        Bcc
        From
        Reply-To
        Subject
        To
    );
    for my $key (grep { !$excluded_headers{$_} } @headers) {
        $stuff->header($key => $headers->{$key})
            if defined $headers->{$key}
    }

    # process attachments - old behavior
    if (my $attachments = $email->{attach}) {
        if (ref($attachments) eq 'ARRAY') {
            my %files = @{$attachments};
            foreach my $file (keys %files) {
                if ($files{$file}) {
                    my $data = read_file($files{$file}, binmode => ':raw');
                    $stuff->attach($data, name => $file, filename => $file);
                }
                else {
                    $stuff->attach_file($file);
                }
            }
        }
    }

    # process attachments - new behavior
    if (my $attachments = $email->{files}) {
        if (ref($attachments) eq 'ARRAY') {
            $stuff->attach_file($_) for @{$attachments};
        }
    }

    # transport email explicitly
    $stuff->transport(@arguments) if @arguments;
    return $stuff if @arguments;

    # transport email implicitly
    my $driver   = $email->{driver};
    my $sendmail = lc($driver) eq 'sendmail';
    my $smtpmail = lc($driver) eq 'smtp';

    # default transport to sendmail
    $sendmail = 1 unless $sendmail or $smtpmail;

    if ($sendmail) {
        my $path = $email->{path};

        $path ||= '/usr/bin/sendmail'  if -f '/usr/bin/sendmail';
        $path ||= '/usr/sbin/sendmail' if -f '/usr/sbin/sendmail';

        $stuff->transport('Sendmail' => (sendmail => $path));
    }

    if ($smtpmail) {
        my %map  = (
            user => 'sasl_username',
            pass => 'sasl_password'
        );
        my @keys = qw(
            debug
            host
            pass
            password
            port
            ssl
            user
            username
        );
        my @params = ();

        for my $key (@keys) {
            push @params, $map{$key} // $key, $email->{$key}
                if defined $email->{$key};
        }

        push @params, 'proto' => 'tcp'; # no longer used
        push @params, 'reuse' => 1;     # no longer used

        $stuff->transport('SMTP' => @params);
    }

    return $stuff;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Emailesque - Lightweight To-The-Point Email

=head1 VERSION

version 1.26

=head1 SYNOPSIS

    use Emailesque qw(
        email
    );

    email {
        to      => '...',
        from    => '...',
        subject => '...',
        message => '...',
    };

=head1 DESCRIPTION

Emailesque provides an easy way of handling text or html email messages
with or without attachments. Simply define how you wish to send the email,
then call the email keyword passing the necessary parameters as outlined above.
This module is basically a wrapper around the email interface Email::Stuffer.
The following is an example of the object-oriented interface:

=head1 OVERVIEW

    use Emailesque;

    my $email = Emailesque->new(
        to      => '...',
        from    => '...',
        subject => '...',
        message => '...',
        files   => [ '/path/to/file/1', '/path/to/file/2' ],
    );

    my $result = $email->send;

    if ($result->isa('Email::Sender::Failure')) {
        die $result->message;
    }

The Emailesque object-oriented interface is designed to accept parameters at
instatiation and when calling the send method. This allows you to build-up an
email object with a few base parameters, then create and send multiple email
messages by calling the send method with only the unique parameters. The
following is an example of that:

    use Emailesque;

    my $email = Emailesque->new(
        from     => '...',
        subject  => '...',
        x_mailer => "MyApp-Newletter 0.019876",
        x_url    => "https://mail.to/u/123/welcome",
        type     => 'text',
    );

    for my $user (@users) {
        my $message = msg_generation $user;
        $email->send({ to => $user, message => $message });
    }

The default email format is plain-text, this can be changed to html by setting
the option 'type' to 'html'. The following are options that can be passed within
the hashref of arguments to the keyword, constructor and/or the send method:

    # send message to
    $email->to('...')

    # send messages from
    $email->from('...')

    # email subject
    $email->subject('...')

    # message body
    $email->message('...') # html or text data

    # email message content type (type: text, html, or multi)
    $email->send({ type => 'text' })

    # message multipart content
    $email->type('multi') # must set type to multi
    $email->message({ text => $text_message, html => $html_messase })

    # carbon-copy other email addresses
    $email->send({ cc => 'user@site.com' })
    $email->send({ cc => 'usr1@site.com, usr2@site.com, usr3@site.com' })
    $email->send({ cc => [qw(usr1@site.com usr2@site.com usr3@site.com)] })

    # blind carbon-copy other email addresses
    $email->send({ bcc => 'user@site.com' })
    $email->send({ bcc => 'usr1@site.com, usr2@site.com, usr3@site.com' })
    $email->send({ bcc => [qw(usr1@site.com usr2@site.com usr3@site.com)] })

    # specify where email responses should be directed
    $email->send({ reply_to => 'other_email@website.com' })

    # attach files to the email
    $email->send({ files => [ $file_path_1, $file_path_2 ] })

    # attach files to the email (and specify attachment name)
    # set attachment name to undef to use the filename
    $email->send({ attach => [ $file_path => $attachment_name ] })
    $email->send({ attach => [ $file_path => undef ] })

    # send additional headers explicitly
    $email->send({ headers  => { 'X-Mailer' => '...' } })

    # send additional headers implicitly
    $email->send({ x_mailer => '...' } # simpler

The default email transport is sendmail. This can be changed by specifying a
different driver parameter, e.g. smtp, as well as any additional arguments
required by the transport:

    # send mail via smtp
    $email->send({
        ...,
        driver  => 'smtp',
        host    => 'smtp.googlemail.com',
        user    => 'account@gmail.com',
        pass    => '****'
    })

    # send mail via smtp via Google (gmail)
    $email->send({
        ...,
        ssl     => 1,
        driver  => 'smtp',
        host    => 'smtp.googlemail.com',
        port    => 465,
        user    => 'account@gmail.com',
        pass    => '****'
    })

    # send mail via smtp via Mailchimp (mandrill)
    $email->send({
        ...,
        ssl     => 0,
        driver  => 'smtp',
        host    => 'smtp.mandrillapp.com',
        port    => 587,
        user    => 'account@domain.com',
        pass    => '****'
    })

    # send mail via sendmail
    # path is optional if installed in a standard location
    $email->send({
        ...,
        driver  => 'sendmail',
        path    => '/usr/bin/sendmail',
    })

=head1 METHODS

=head2 accept_language

    my $header = $email->accept_language;
       $header = $email->accept_language('...');

The accept_language method is a shortcut for getting and setting the
C<Accept-Language> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 alternate_recipient

    my $header = $email->alternate_recipient;
       $header = $email->alternate_recipient('...');

The alternate_recipient method is a shortcut for getting and setting the
C<Alternate-Recipient> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 apparently_to

    my $header = $email->apparently_to;
       $header = $email->apparently_to('...');

The apparently_to method is a shortcut for getting and setting the
C<Apparently-To> header. This header is described in more detail within RFC2076
L<http://www.iana.org/go/rfc2076>.

=head2 archived_at

    my $header = $email->archived_at;
       $header = $email->archived_at('...');

The archived_at method is a shortcut for getting and setting the C<Archived-At>
header. This header is described in more detail within RFC5064
L<http://www.iana.org/go/rfc5064>.

=head2 authentication_results

    my $header = $email->authentication_results;
       $header = $email->authentication_results('...');

The authentication_results method is a shortcut for getting and setting the
C<Authentication-Results> header. This header is described in more detail
within RFC7001 L<http://www.iana.org/go/rfc7001>.

=head2 auto_submitted

    my $header = $email->auto_submitted;
       $header = $email->auto_submitted('...');

The auto_submitted method is a shortcut for getting and setting the
C<Auto-Submitted> header. This header is described in more detail within
RFC3834 L<http://www.iana.org/go/rfc3834>.

=head2 autoforwarded

    my $header = $email->autoforwarded;
       $header = $email->autoforwarded('...');

The autoforwarded method is a shortcut for getting and setting the
C<Autoforwarded> header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 autosubmitted

    my $header = $email->autosubmitted;
       $header = $email->autosubmitted('...');

The autosubmitted method is a shortcut for getting and setting the
C<Autosubmitted> header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 bcc

    my $header = $email->bcc;
       $header = $email->bcc('...');

The bcc method is a shortcut for getting and setting the C<Bcc> header. This
header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 cc

    my $header = $email->cc;
       $header = $email->cc('...');

The cc method is a shortcut for getting and setting the C<Cc> header. This
header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 comments

    my $header = $email->comments;
       $header = $email->comments('...');

The comments method is a shortcut for getting and setting the C<Comments>
header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 content_identifier

    my $header = $email->content_identifier;
       $header = $email->content_identifier('...');

The content_identifier method is a shortcut for getting and setting the
C<Content-Identifier> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 content_return

    my $header = $email->content_return;
       $header = $email->content_return('...');

The content_return method is a shortcut for getting and setting the
C<Content-Return> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 conversion

    my $header = $email->conversion;
       $header = $email->conversion('...');

The conversion method is a shortcut for getting and setting the C<Conversion>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 conversion_with_loss

    my $header = $email->conversion_with_loss;
       $header = $email->conversion_with_loss('...');

The conversion_with_loss method is a shortcut for getting and setting the
C<Conversion-With-Loss> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 dkim_signature

    my $header = $email->dkim_signature;
       $header = $email->dkim_signature('...');

The dkim_signature method is a shortcut for getting and setting the
C<DKIM-Signature> header. This header is described in more detail within
RFC6376 L<http://www.iana.org/go/rfc6376>.

=head2 dl_expansion_history

    my $header = $email->dl_expansion_history;
       $header = $email->dl_expansion_history('...');

The dl_expansion_history method is a shortcut for getting and setting the
C<DL-Expansion-History> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 date

    my $header = $email->date;
       $header = $email->date('...');

The date method is a shortcut for getting and setting the C<Date> header. This
header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 deferred_delivery

    my $header = $email->deferred_delivery;
       $header = $email->deferred_delivery('...');

The deferred_delivery method is a shortcut for getting and setting the
C<Deferred-Delivery> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 delivery_date

    my $header = $email->delivery_date;
       $header = $email->delivery_date('...');

The delivery_date method is a shortcut for getting and setting the
C<Delivery-Date> header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 discarded_x400_ipms_extensions

    my $header = $email->discarded_x400_ipms_extensions;
       $header = $email->discarded_x400_ipms_extensions('...');

The discarded_x400_ipms_extensions method is a shortcut for getting and setting
the C<Discarded-X400-IPMS-Extensions> header. This header is described in more
detail within RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 discarded_x400_mts_extensions

    my $header = $email->discarded_x400_mts_extensions;
       $header = $email->discarded_x400_mts_extensions('...');

The discarded_x400_mts_extensions method is a shortcut for getting and setting
the C<Discarded-X400-MTS-Extensions> header. This header is described in more
detail within RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 disclose_recipients

    my $header = $email->disclose_recipients;
       $header = $email->disclose_recipients('...');

The disclose_recipients method is a shortcut for getting and setting the
C<Disclose-Recipients> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 disposition_notification_options

    my $header = $email->disposition_notification_options;
       $header = $email->disposition_notification_options('...');

The disposition_notification_options method is a shortcut for getting and
setting the C<Disposition-Notification-Options> header. This header is
described in more detail within RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 disposition_notification_to

    my $header = $email->disposition_notification_to;
       $header = $email->disposition_notification_to('...');

The disposition_notification_to method is a shortcut for getting and setting
the C<Disposition-Notification-To> header. This header is described in more
detail within RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 downgraded_bcc

    my $header = $email->downgraded_bcc;
       $header = $email->downgraded_bcc('...');

The downgraded_bcc method is a shortcut for getting and setting the
C<Downgraded-Bcc> header. This header is described in more detail within
RFC5504 L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_cc

    my $header = $email->downgraded_cc;
       $header = $email->downgraded_cc('...');

The downgraded_cc method is a shortcut for getting and setting the
C<Downgraded-Cc> header. This header is described in more detail within RFC5504
L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_disposition_notification_to

    my $header = $email->downgraded_disposition_notification_to;
       $header = $email->downgraded_disposition_notification_to('...');

The downgraded_disposition_notification_to method is a shortcut for getting and
setting the C<Downgraded-Disposition-Notification-To> header. This header is
described in more detail within RFC5504 L<http://www.iana.org/go/rfc5504> and
RFC6857 L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_final_recipient

    my $header = $email->downgraded_final_recipient;
       $header = $email->downgraded_final_recipient('...');

The downgraded_final_recipient method is a shortcut for getting and setting the
C<Downgraded-Final-Recipient> header. This header is described in more detail
within RFC6857 L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_from

    my $header = $email->downgraded_from;
       $header = $email->downgraded_from('...');

The downgraded_from method is a shortcut for getting and setting the
C<Downgraded-From> header. This header is described in more detail within
RFC5504 L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_in_reply_to

    my $header = $email->downgraded_in_reply_to;
       $header = $email->downgraded_in_reply_to('...');

The downgraded_in_reply_to method is a shortcut for getting and setting the
C<Downgraded-In-Reply-To> header. This header is described in more detail
within RFC6857 L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_mail_from

    my $header = $email->downgraded_mail_from;
       $header = $email->downgraded_mail_from('...');

The downgraded_mail_from method is a shortcut for getting and setting the
C<Downgraded-Mail-From> header. This header is described in more detail within
RFC5504 L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_message_id

    my $header = $email->downgraded_message_id;
       $header = $email->downgraded_message_id('...');

The downgraded_message_id method is a shortcut for getting and setting the
C<Downgraded-Message-Id> header. This header is described in more detail within
RFC6857 L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_original_recipient

    my $header = $email->downgraded_original_recipient;
       $header = $email->downgraded_original_recipient('...');

The downgraded_original_recipient method is a shortcut for getting and setting
the C<Downgraded-Original-Recipient> header. This header is described in more
detail within RFC6857 L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_rcpt_to

    my $header = $email->downgraded_rcpt_to;
       $header = $email->downgraded_rcpt_to('...');

The downgraded_rcpt_to method is a shortcut for getting and setting the
C<Downgraded-Rcpt-To> header. This header is described in more detail within
RFC5504 L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_references

    my $header = $email->downgraded_references;
       $header = $email->downgraded_references('...');

The downgraded_references method is a shortcut for getting and setting the
C<Downgraded-References> header. This header is described in more detail within
RFC6857 L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_reply_to

    my $header = $email->downgraded_reply_to;
       $header = $email->downgraded_reply_to('...');

The downgraded_reply_to method is a shortcut for getting and setting the
C<Downgraded-Reply-To> header. This header is described in more detail within
RFC5504 L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_resent_bcc

    my $header = $email->downgraded_resent_bcc;
       $header = $email->downgraded_resent_bcc('...');

The downgraded_resent_bcc method is a shortcut for getting and setting the
C<Downgraded-Resent-Bcc> header. This header is described in more detail within
RFC5504 L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_resent_cc

    my $header = $email->downgraded_resent_cc;
       $header = $email->downgraded_resent_cc('...');

The downgraded_resent_cc method is a shortcut for getting and setting the
C<Downgraded-Resent-Cc> header. This header is described in more detail within
RFC5504 L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_resent_from

    my $header = $email->downgraded_resent_from;
       $header = $email->downgraded_resent_from('...');

The downgraded_resent_from method is a shortcut for getting and setting the
C<Downgraded-Resent-From> header. This header is described in more detail
within RFC5504 L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_resent_reply_to

    my $header = $email->downgraded_resent_reply_to;
       $header = $email->downgraded_resent_reply_to('...');

The downgraded_resent_reply_to method is a shortcut for getting and setting the
C<Downgraded-Resent-Reply-To> header. This header is described in more detail
within RFC5504 L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_resent_sender

    my $header = $email->downgraded_resent_sender;
       $header = $email->downgraded_resent_sender('...');

The downgraded_resent_sender method is a shortcut for getting and setting the
C<Downgraded-Resent-Sender> header. This header is described in more detail
within RFC5504 L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_resent_to

    my $header = $email->downgraded_resent_to;
       $header = $email->downgraded_resent_to('...');

The downgraded_resent_to method is a shortcut for getting and setting the
C<Downgraded-Resent-To> header. This header is described in more detail within
RFC5504 L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_return_path

    my $header = $email->downgraded_return_path;
       $header = $email->downgraded_return_path('...');

The downgraded_return_path method is a shortcut for getting and setting the
C<Downgraded-Return-Path> header. This header is described in more detail
within RFC5504 L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_sender

    my $header = $email->downgraded_sender;
       $header = $email->downgraded_sender('...');

The downgraded_sender method is a shortcut for getting and setting the
C<Downgraded-Sender> header. This header is described in more detail within
RFC5504 L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 downgraded_to

    my $header = $email->downgraded_to;
       $header = $email->downgraded_to('...');

The downgraded_to method is a shortcut for getting and setting the
C<Downgraded-To> header. This header is described in more detail within RFC5504
L<http://www.iana.org/go/rfc5504> and RFC6857
L<http://www.iana.org/go/rfc6857>.

=head2 ediint_features

    my $header = $email->ediint_features;
       $header = $email->ediint_features('...');

The ediint_features method is a shortcut for getting and setting the
C<EDIINT-Features> header. This header is described in more detail within
RFC6017 L<http://www.iana.org/go/rfc6017>.

=head2 encoding

    my $header = $email->encoding;
       $header = $email->encoding('...');

The encoding method is a shortcut for getting and setting the C<Encoding>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 encrypted

    my $header = $email->encrypted;
       $header = $email->encrypted('...');

The encrypted method is a shortcut for getting and setting the C<Encrypted>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 errors_to

    my $header = $email->errors_to;
       $header = $email->errors_to('...');

The errors_to method is a shortcut for getting and setting the C<Errors-To>
header. This header is described in more detail within RFC2076
L<http://www.iana.org/go/rfc2076>.

=head2 expires

    my $header = $email->expires;
       $header = $email->expires('...');

The expires method is a shortcut for getting and setting the C<Expires> header.
This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 expiry_date

    my $header = $email->expiry_date;
       $header = $email->expiry_date('...');

The expiry_date method is a shortcut for getting and setting the C<Expiry-Date>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 from

    my $header = $email->from;
       $header = $email->from('...');

The from method is a shortcut for getting and setting the C<From> header. This
header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322> and RFC6854
L<http://www.iana.org/go/rfc6854>.

=head2 generate_delivery_report

    my $header = $email->generate_delivery_report;
       $header = $email->generate_delivery_report('...');

The generate_delivery_report method is a shortcut for getting and setting the
C<Generate-Delivery-Report> header. This header is described in more detail
within RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 header

    my $header = $email->header('X-Tag');
       $header = $email->header('X-Tag', '...');

The header method is used for getting and setting arbitrary headers by name.

=head2 importance

    my $header = $email->importance;
       $header = $email->importance('...');

The importance method is a shortcut for getting and setting the C<Importance>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 in_reply_to

    my $header = $email->in_reply_to;
       $header = $email->in_reply_to('...');

The in_reply_to method is a shortcut for getting and setting the C<In-Reply-To>
header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 incomplete_copy

    my $header = $email->incomplete_copy;
       $header = $email->incomplete_copy('...');

The incomplete_copy method is a shortcut for getting and setting the
C<Incomplete-Copy> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 jabber_id

    my $header = $email->jabber_id;
       $header = $email->jabber_id('...');

The jabber_id method is a shortcut for getting and setting the C<Jabber-ID>
header. This header is described in more detail within RFC7259
L<http://www.iana.org/go/rfc7259>.

=head2 keywords

    my $header = $email->keywords;
       $header = $email->keywords('...');

The keywords method is a shortcut for getting and setting the C<Keywords>
header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 language

    my $header = $email->language;
       $header = $email->language('...');

The language method is a shortcut for getting and setting the C<Language>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 latest_delivery_time

    my $header = $email->latest_delivery_time;
       $header = $email->latest_delivery_time('...');

The latest_delivery_time method is a shortcut for getting and setting the
C<Latest-Delivery-Time> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 list_archive

    my $header = $email->list_archive;
       $header = $email->list_archive('...');

The list_archive method is a shortcut for getting and setting the
C<List-Archive> header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 list_help

    my $header = $email->list_help;
       $header = $email->list_help('...');

The list_help method is a shortcut for getting and setting the C<List-Help>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 list_id

    my $header = $email->list_id;
       $header = $email->list_id('...');

The list_id method is a shortcut for getting and setting the C<List-ID> header.
This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 list_owner

    my $header = $email->list_owner;
       $header = $email->list_owner('...');

The list_owner method is a shortcut for getting and setting the C<List-Owner>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 list_post

    my $header = $email->list_post;
       $header = $email->list_post('...');

The list_post method is a shortcut for getting and setting the C<List-Post>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 list_subscribe

    my $header = $email->list_subscribe;
       $header = $email->list_subscribe('...');

The list_subscribe method is a shortcut for getting and setting the
C<List-Subscribe> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 list_unsubscribe

    my $header = $email->list_unsubscribe;
       $header = $email->list_unsubscribe('...');

The list_unsubscribe method is a shortcut for getting and setting the
C<List-Unsubscribe> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 mmhs_acp127_message_identifier

    my $header = $email->mmhs_acp127_message_identifier;
       $header = $email->mmhs_acp127_message_identifier('...');

The mmhs_acp127_message_identifier method is a shortcut for getting and setting
the C<MMHS-Acp127-Message-Identifier> header. This header is described in more
detail within RFC6477 L<http://www.iana.org/go/rfc6477> and ACP123
L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mmhs_codress_message_indicator

    my $header = $email->mmhs_codress_message_indicator;
       $header = $email->mmhs_codress_message_indicator('...');

The mmhs_codress_message_indicator method is a shortcut for getting and setting
the C<MMHS-Codress-Message-Indicator> header. This header is described in more
detail within RFC6477 L<http://www.iana.org/go/rfc6477> and ACP123
L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mmhs_copy_precedence

    my $header = $email->mmhs_copy_precedence;
       $header = $email->mmhs_copy_precedence('...');

The mmhs_copy_precedence method is a shortcut for getting and setting the
C<MMHS-Copy-Precedence> header. This header is described in more detail within
RFC6477 L<http://www.iana.org/go/rfc6477> and ACP123
L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mmhs_exempted_address

    my $header = $email->mmhs_exempted_address;
       $header = $email->mmhs_exempted_address('...');

The mmhs_exempted_address method is a shortcut for getting and setting the
C<MMHS-Exempted-Address> header. This header is described in more detail within
RFC6477 L<http://www.iana.org/go/rfc6477> and ACP123
L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mmhs_extended_authorisation_info

    my $header = $email->mmhs_extended_authorisation_info;
       $header = $email->mmhs_extended_authorisation_info('...');

The mmhs_extended_authorisation_info method is a shortcut for getting and
setting the C<MMHS-Extended-Authorisation-Info> header. This header is
described in more detail within RFC6477 L<http://www.iana.org/go/rfc6477> and
ACP123 L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mmhs_handling_instructions

    my $header = $email->mmhs_handling_instructions;
       $header = $email->mmhs_handling_instructions('...');

The mmhs_handling_instructions method is a shortcut for getting and setting the
C<MMHS-Handling-Instructions> header. This header is described in more detail
within RFC6477 L<http://www.iana.org/go/rfc6477> and ACP123
L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mmhs_message_instructions

    my $header = $email->mmhs_message_instructions;
       $header = $email->mmhs_message_instructions('...');

The mmhs_message_instructions method is a shortcut for getting and setting the
C<MMHS-Message-Instructions> header. This header is described in more detail
within RFC6477 L<http://www.iana.org/go/rfc6477> and ACP123
L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mmhs_message_type

    my $header = $email->mmhs_message_type;
       $header = $email->mmhs_message_type('...');

The mmhs_message_type method is a shortcut for getting and setting the
C<MMHS-Message-Type> header. This header is described in more detail within
RFC6477 L<http://www.iana.org/go/rfc6477> and ACP123
L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mmhs_originator_plad

    my $header = $email->mmhs_originator_plad;
       $header = $email->mmhs_originator_plad('...');

The mmhs_originator_plad method is a shortcut for getting and setting the
C<MMHS-Originator-PLAD> header. This header is described in more detail within
RFC6477 L<http://www.iana.org/go/rfc6477> and ACP123
L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mmhs_originator_reference

    my $header = $email->mmhs_originator_reference;
       $header = $email->mmhs_originator_reference('...');

The mmhs_originator_reference method is a shortcut for getting and setting the
C<MMHS-Originator-Reference> header. This header is described in more detail
within RFC6477 L<http://www.iana.org/go/rfc6477> and ACP123
L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mmhs_other_recipients_indicator_cc

    my $header = $email->mmhs_other_recipients_indicator_cc;
       $header = $email->mmhs_other_recipients_indicator_cc('...');

The mmhs_other_recipients_indicator_cc method is a shortcut for getting and
setting the C<MMHS-Other-Recipients-Indicator-CC> header. This header is
described in more detail within RFC6477 L<http://www.iana.org/go/rfc6477> and
ACP123 L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mmhs_other_recipients_indicator_to

    my $header = $email->mmhs_other_recipients_indicator_to;
       $header = $email->mmhs_other_recipients_indicator_to('...');

The mmhs_other_recipients_indicator_to method is a shortcut for getting and
setting the C<MMHS-Other-Recipients-Indicator-To> header. This header is
described in more detail within RFC6477 L<http://www.iana.org/go/rfc6477> and
ACP123 L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mmhs_primary_precedence

    my $header = $email->mmhs_primary_precedence;
       $header = $email->mmhs_primary_precedence('...');

The mmhs_primary_precedence method is a shortcut for getting and setting the
C<MMHS-Primary-Precedence> header. This header is described in more detail
within RFC6477 L<http://www.iana.org/go/rfc6477> and ACP123
L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mmhs_subject_indicator_codes

    my $header = $email->mmhs_subject_indicator_codes;
       $header = $email->mmhs_subject_indicator_codes('...');

The mmhs_subject_indicator_codes method is a shortcut for getting and setting
the C<MMHS-Subject-Indicator-Codes> header. This header is described in more
detail within RFC6477 L<http://www.iana.org/go/rfc6477> and ACP123
L<http://jcs.dtic.mil/j6/cceb/acps/acp123/ACP123B.pdf>.

=head2 mt_priority

    my $header = $email->mt_priority;
       $header = $email->mt_priority('...');

The mt_priority method is a shortcut for getting and setting the C<MT-Priority>
header. This header is described in more detail within RFC6758
L<http://www.iana.org/go/rfc6758>.

=head2 message

    my $data = $email->message({
        text => '...',
        html => '...',
    });

The message method is used for getting and setting the message attribute which
is used along with the type attribute to determine how the email message should
be constructed. This attribute can be assigned a string or hash reference with
text and/or html key/value pairs.

=head2 message_context

    my $header = $email->message_context;
       $header = $email->message_context('...');

The message_context method is a shortcut for getting and setting the
C<Message-Context> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 message_id

    my $header = $email->message_id;
       $header = $email->message_id('...');

The message_id method is a shortcut for getting and setting the C<Message-ID>
header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 message_type

    my $header = $email->message_type;
       $header = $email->message_type('...');

The message_type method is a shortcut for getting and setting the
C<Message-Type> header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 obsoletes

    my $header = $email->obsoletes;
       $header = $email->obsoletes('...');

The obsoletes method is a shortcut for getting and setting the C<Obsoletes>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 original_encoded_information_types

    my $header = $email->original_encoded_information_types;
       $header = $email->original_encoded_information_types('...');

The original_encoded_information_types method is a shortcut for getting and
setting the C<Original-Encoded-Information-Types> header. This header is
described in more detail within RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 original_from

    my $header = $email->original_from;
       $header = $email->original_from('...');

The original_from method is a shortcut for getting and setting the
C<Original-From> header. This header is described in more detail within RFC5703
L<http://www.iana.org/go/rfc5703>.

=head2 original_message_id

    my $header = $email->original_message_id;
       $header = $email->original_message_id('...');

The original_message_id method is a shortcut for getting and setting the
C<Original-Message-ID> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 original_recipient

    my $header = $email->original_recipient;
       $header = $email->original_recipient('...');

The original_recipient method is a shortcut for getting and setting the
C<Original-Recipient> header. This header is described in more detail within
RFC3798 L<http://www.iana.org/go/rfc3798> and RFC5337
L<http://www.iana.org/go/rfc5337>.

=head2 original_subject

    my $header = $email->original_subject;
       $header = $email->original_subject('...');

The original_subject method is a shortcut for getting and setting the
C<Original-Subject> header. This header is described in more detail within
RFC5703 L<http://www.iana.org/go/rfc5703>.

=head2 originator_return_address

    my $header = $email->originator_return_address;
       $header = $email->originator_return_address('...');

The originator_return_address method is a shortcut for getting and setting the
C<Originator-Return-Address> header. This header is described in more detail
within RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 pics_label

    my $header = $email->pics_label;
       $header = $email->pics_label('...');

The pics_label method is a shortcut for getting and setting the C<PICS-Label>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 prevent_nondelivery_report

    my $header = $email->prevent_nondelivery_report;
       $header = $email->prevent_nondelivery_report('...');

The prevent_nondelivery_report method is a shortcut for getting and setting the
C<Prevent-NonDelivery-Report> header. This header is described in more detail
within RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 priority

    my $header = $email->priority;
       $header = $email->priority('...');

The priority method is a shortcut for getting and setting the C<Priority>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 privicon

    my $header = $email->privicon;
       $header = $email->privicon('...');

The privicon method is a shortcut for getting and setting the C<Privicon>
header. This header is described in more detail within
L<http://www.iana.org/go/draft-koenig-privicons>.

=head2 received

    my $header = $email->received;
       $header = $email->received('...');

The received method is a shortcut for getting and setting the C<Received>
header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322> and RFC5321
L<http://www.iana.org/go/rfc5321>.

=head2 received_spf

    my $header = $email->received_spf;
       $header = $email->received_spf('...');

The received_spf method is a shortcut for getting and setting the
C<Received-SPF> header. This header is described in more detail within RFC7208
L<http://www.iana.org/go/rfc7208>.

=head2 references

    my $header = $email->references;
       $header = $email->references('...');

The references method is a shortcut for getting and setting the C<References>
header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 reply_by

    my $header = $email->reply_by;
       $header = $email->reply_by('...');

The reply_by method is a shortcut for getting and setting the C<Reply-By>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 reply_to

    my $header = $email->reply_to;
       $header = $email->reply_to('...');

The reply_to method is a shortcut for getting and setting the C<Reply-To>
header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 require_recipient_valid_since

    my $header = $email->require_recipient_valid_since;
       $header = $email->require_recipient_valid_since('...');

The require_recipient_valid_since method is a shortcut for getting and setting
the C<Require-Recipient-Valid-Since> header. This header is described in more
detail within RFC7293 L<http://www.iana.org/go/rfc7293>.

=head2 resent_bcc

    my $header = $email->resent_bcc;
       $header = $email->resent_bcc('...');

The resent_bcc method is a shortcut for getting and setting the C<Resent-Bcc>
header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 resent_cc

    my $header = $email->resent_cc;
       $header = $email->resent_cc('...');

The resent_cc method is a shortcut for getting and setting the C<Resent-Cc>
header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 resent_date

    my $header = $email->resent_date;
       $header = $email->resent_date('...');

The resent_date method is a shortcut for getting and setting the C<Resent-Date>
header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 resent_from

    my $header = $email->resent_from;
       $header = $email->resent_from('...');

The resent_from method is a shortcut for getting and setting the C<Resent-From>
header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322> and RFC6854
L<http://www.iana.org/go/rfc6854>.

=head2 resent_message_id

    my $header = $email->resent_message_id;
       $header = $email->resent_message_id('...');

The resent_message_id method is a shortcut for getting and setting the
C<Resent-Message-ID> header. This header is described in more detail within
RFC5322 L<http://www.iana.org/go/rfc5322>.

=head2 resent_reply_to

    my $header = $email->resent_reply_to;
       $header = $email->resent_reply_to('...');

The resent_reply_to method is a shortcut for getting and setting the
C<Resent-Reply-To> header. This header is described in more detail within
RFC5322 L<http://www.iana.org/go/rfc5322>.

=head2 resent_sender

    my $header = $email->resent_sender;
       $header = $email->resent_sender('...');

The resent_sender method is a shortcut for getting and setting the
C<Resent-Sender> header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322> and RFC6854
L<http://www.iana.org/go/rfc6854>.

=head2 resent_to

    my $header = $email->resent_to;
       $header = $email->resent_to('...');

The resent_to method is a shortcut for getting and setting the C<Resent-To>
header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 return_path

    my $header = $email->return_path;
       $header = $email->return_path('...');

The return_path method is a shortcut for getting and setting the C<Return-Path>
header. This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 sio_label

    my $header = $email->sio_label;
       $header = $email->sio_label('...');

The sio_label method is a shortcut for getting and setting the C<SIO-Label>
header. This header is described in more detail within RFC7444
L<http://www.iana.org/go/rfc7444>.

=head2 sio_label_history

    my $header = $email->sio_label_history;
       $header = $email->sio_label_history('...');

The sio_label_history method is a shortcut for getting and setting the
C<SIO-Label-History> header. This header is described in more detail within
RFC7444 L<http://www.iana.org/go/rfc7444>.

=head2 send

    my $result = $email->send($attributes, @transport_args);

The send method generates a L<Email::Stuffer> object based on the stashed and
passed in attributes, and attempts delivery using the configured transport.

=head2 sender

    my $header = $email->sender;
       $header = $email->sender('...');

The sender method is a shortcut for getting and setting the C<Sender> header.
This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322> and RFC6854
L<http://www.iana.org/go/rfc6854>.

=head2 sensitivity

    my $header = $email->sensitivity;
       $header = $email->sensitivity('...');

The sensitivity method is a shortcut for getting and setting the C<Sensitivity>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 solicitation

    my $header = $email->solicitation;
       $header = $email->solicitation('...');

The solicitation method is a shortcut for getting and setting the
C<Solicitation> header. This header is described in more detail within RFC3865
L<http://www.iana.org/go/rfc3865>.

=head2 subject

    my $header = $email->subject;
       $header = $email->subject('...');

The subject method is a shortcut for getting and setting the C<Subject> header.
This header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 supersedes

    my $header = $email->supersedes;
       $header = $email->supersedes('...');

The supersedes method is a shortcut for getting and setting the C<Supersedes>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 to

    my $header = $email->to;
       $header = $email->to('...');

The to method is a shortcut for getting and setting the C<To> header. This
header is described in more detail within RFC5322
L<http://www.iana.org/go/rfc5322>.

=head2 vbr_info

    my $header = $email->vbr_info;
       $header = $email->vbr_info('...');

The vbr_info method is a shortcut for getting and setting the C<VBR-Info>
header. This header is described in more detail within RFC5518
L<http://www.iana.org/go/rfc5518>.

=head2 x_archived_at

    my $header = $email->x_archived_at;
       $header = $email->x_archived_at('...');

The x_archived_at method is a shortcut for getting and setting the
C<X-Archived-At> header. This header is described in more detail within RFC5064
L<http://www.iana.org/go/rfc5064>.

=head2 x400_content_identifier

    my $header = $email->x400_content_identifier;
       $header = $email->x400_content_identifier('...');

The x400_content_identifier method is a shortcut for getting and setting the
C<X400-Content-Identifier> header. This header is described in more detail
within RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 x400_content_return

    my $header = $email->x400_content_return;
       $header = $email->x400_content_return('...');

The x400_content_return method is a shortcut for getting and setting the
C<X400-Content-Return> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 x400_content_type

    my $header = $email->x400_content_type;
       $header = $email->x400_content_type('...');

The x400_content_type method is a shortcut for getting and setting the
C<X400-Content-Type> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 x400_mts_identifier

    my $header = $email->x400_mts_identifier;
       $header = $email->x400_mts_identifier('...');

The x400_mts_identifier method is a shortcut for getting and setting the
C<X400-MTS-Identifier> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 x400_originator

    my $header = $email->x400_originator;
       $header = $email->x400_originator('...');

The x400_originator method is a shortcut for getting and setting the
C<X400-Originator> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 x400_received

    my $header = $email->x400_received;
       $header = $email->x400_received('...');

The x400_received method is a shortcut for getting and setting the
C<X400-Received> header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head2 x400_recipients

    my $header = $email->x400_recipients;
       $header = $email->x400_recipients('...');

The x400_recipients method is a shortcut for getting and setting the
C<X400-Recipients> header. This header is described in more detail within
RFC4021 L<http://www.iana.org/go/rfc4021>.

=head2 x400_trace

    my $header = $email->x400_trace;
       $header = $email->x400_trace('...');

The x400_trace method is a shortcut for getting and setting the C<X400-Trace>
header. This header is described in more detail within RFC4021
L<http://www.iana.org/go/rfc4021>.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 CONTRIBUTORS

=for stopwords Andrew Beverley Eric Johnson Stefan Hornburg

=over 4

=item *

Andrew Beverley <a.beverley@ctrlo.com>

=item *

Eric Johnson <eric.git@iijo.org>

=item *

Stefan Hornburg <racke@linuxia.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
