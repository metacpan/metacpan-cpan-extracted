package Email::SendGrid::V3;

our $AUTHORITY = 'cpan:GSG';
our $VERSION   = '0.90';

use v5.10.1;
use strict;
use warnings;

use Carp;
use JSON;
use HTTP::Tiny;

use constant DEFAULT_ENDPOINT => 'https://api.sendgrid.com/v3/mail/send';

use namespace::clean;  # don't export the above

=encoding utf8

=head1 NAME

Email::SendGrid::V3 - Class for building a message to be sent through the SendGrid v3 Web API

=head1 VERSION

version 0.90

=head1 SYNOPSIS

    use Email::SendGrid::V3;

    my $sg = Email::SendGrid::V3->new(api_key => 'XYZ123');

    my $result = $sg->from('nobody@example.com')
                    ->subject('A test message for you')
                    ->add_content('text/plain', 'This is a test message sent with SendGrid')
                    ->add_envelope( to => [ 'nobody@example.com' ] )
                    ->send;

    print $result->{success} ? "It worked" : "It failed: " . $result->{reason};

=head1 DESCRIPTION

This module allows for easy integration with the SendGrid email distribution
service and its v3 Web API.  All instance methods are chainable.

For the full details of the SendGrid v3 API, see L<https://sendgrid.com/docs/API_Reference/api_v3.html>

=head1 CLASS METHODS

=head2 Creation

=head3 new(%args)

Creates a new Email::SendGrid object.  Optional param: 'api_key'

=cut

sub new {
    my ($class, %args) = @_;
    $class = ref($class) || $class;

    my $self = bless +{
        %args,
        data => {},
    }, $class;

    return $self;
}

=head1 INSTANCE METHODS

=head2 Sending / Validating

=head3 send(%args)

Sends the API request and returns a result hashref with these keys:

=over 4

=item *

C<success> - Boolean indicating whether the operation returned a 2XX status code

=item *

C<status> - The HTTP status code of the response

=item *

C<reason> - The response phrase returned by the server

=item *

C<content> - The body of the response, including a detailed error message, if any.

=back

=cut

sub send {
    my ($self, %args) = @_;
    my $api_key = $args{api_key} || $self->{api_key} or croak "API key is required to send";
    my $endpoint = $args{endpoint} || $self->{endpoint} || DEFAULT_ENDPOINT;
    my $payload = $self->_payload;

    my $http = HTTP::Tiny->new(
        keep_alive => 0,
        default_headers => {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer $api_key",
        },
    );

    my $response = $http->post(
        $endpoint, { content => $payload },
    );

    return $response;
}

=head3 validate(%args)

Temporarily sets the 'sandbox_mode' flag to true, and submits the API request
to SendGrid.  Returns the same hashref format as send().  If the 'success' key
is true, the API request is valid.

=cut

sub validate {
    my ($self, %args) = @_;

    local $self->{data}{mail_settings}{sandbox_mode} = { enable => JSON::true };

    return $self->send(%args);
}

sub _payload {
    my ($self) = @_;
    return JSON->new->canonical->encode( $self->{data} );
}

=head2 Personalizations / Envelopes

=head3 $self->add_envelope(%args);

Once you've defined the general message parameters (by setting from, content, etc)
You must add at least one envelope.  Each envelope represents one personalized copy
of a message, and who should receive it.  Some parameters can only be set at the message
level, some only at the envelope level, and some at both (the envelop-level settings will
override the message-level settings).

You must specify at least the 'to' argument, which is an array of recipient emails.  This
can be a plain array of addresses, or an array of hashes with 'email' and 'name' keys.

The 'cc' and 'bcc' arguments are optional, but follow the same format of the 'to' argument.

In addition to specifying the envelope recipients via to/cc/bcc, you can also override the
message 'subject', 'send_at', 'headers' hash, 'substitutions' hash, and 'custom_args' hash.
See the message-level methods for more details on those parameters.

=cut

sub add_envelope {
    my ($self, %args) = @_;

    my $to = _standardize_recips('to', $args{to});
    my $cc = _standardize_recips('cc', $args{cc});
    my $bcc = _standardize_recips('bcc', $args{bcc});

    croak "Envelope must include at least one 'to' address" unless @$to;

    my $envelope = { to => $to };
    $envelope->{cc} = $cc if @$cc;
    $envelope->{bcc} = $bcc if @$bcc;

    $envelope->{subject} = $args{subject} if $args{subject};
    $envelope->{send_at} = $args{send_at} if $args{send_at};

    if ($args{headers}) {
        croak "Envelope headers must be a hashref" unless ref $args{headers} eq 'HASH';
        $envelope->{headers} = $args{headers};
    }

    if ($args{substitutions}) {
        croak "Envelope substitutions must be a hashref" unless ref $args{substitutions} eq 'HASH';
        $envelope->{substitutions} = $args{substitutions};
    }

    if ($args{dynamic_template_data}) {
        croak "Envelope dynamic_template_data must be a hashref" unless ref $args{dynamic_template_data} eq 'HASH';
        $envelope->{dynamic_template_data} = $args{dynamic_template_data};
    }

    if ($args{custom_args}) {
        croak "Envelope custom args must be a hashref" unless ref $args{custom_args} eq 'HASH';
        $envelope->{custom_args} = $args{custom_args};
    }

    $self->{data}{personalizations} ||= [];

    push @{ $self->{data}{personalizations} }, $envelope;

    return $self;
}

sub _standardize_recips {
    my ($name, $data) = @_;
    my $reftype = ref $data;

    return [] unless $data;

    if (! $reftype) {
        $data = [$data];
    }
    elsif ($reftype eq 'HASH') {
        $data = [$data];
    }
    elsif ($reftype ne 'ARRAY') {
        croak "Envelope $name must be an array";
    }

    my @return;
    foreach my $recip (@$data) {
        next unless $recip;

        my $recipreftype = ref $recip;

        if (! $recipreftype) {
            push @return, {
                email => $recip,
            };
        }
        elsif ($recipreftype eq 'HASH') {
            push @return, $recip;
        }
        else {
            croak "Invalid envelope $name";
        }
    }

    return \@return;
}

=head3 $self->clear_envelopes();

Clears all of the currently defined envelopes from this message.

=cut

sub clear_envelopes {
    my ($self) = @_;

    delete $self->{data}{personalizations};

    return $self;
}

=head2 Messages

=head3 $self->from($email, $name);

Sets the name/email address of the sender.
Email is required, name is optional.

=cut

sub from {
    my ($self, $email, $name) = @_;

    croak "From email is required" unless $email;

    $self->{data}{from} = { email => $email };
    $self->{data}{from}{name} = $name if $name;

    return $self;
}

=head3 $self->subject($subject);

Sets the subject of the message.
Required, but can be overridden at the message personalization level.

=cut

sub subject {
    my ($self, $subject) = @_;

    croak "Subject is required" unless $subject;

    $self->{data}{subject} = $subject;

    return $self;
}

=head3 $self->reply_to($email, $name);

Sets the target that will be used if the recipient wants to reply to this message.
Email is required, name is optional.

=cut

sub reply_to {
    my ($self, $email, $name) = @_;

    croak "Reply-to email is required" unless $email;

    $self->{data}{reply_to} = { email => $email };
    $self->{data}{reply_to}{name} = $name if $name;

    return $self;
}

=head3 $self->clear_content();

Clears out all of the message body parts.

=cut

sub clear_content {
    my ($self) = @_;

    delete $self->{data}{content};

    return $self;
}

=head3 $self->add_content($type, $value);

Adds a message body part. Both type and value are required.
$type should be something like "text/plain" or "text/html".

=cut

sub add_content {
    my ($self, $type, $value) = @_;

    croak "Content type and value are required" unless $type && $value;

    $self->{data}{content} ||= [];

    push @{ $self->{data}{content} }, {
        type => $type,
        value => $value,
    };

    return $self;
}

=head3 $self->clear_attachments();

Removes all attachments from this message.

=cut

sub clear_attachments {
    my ($self) = @_;

    delete $self->{data}{attachments};

    return $self;
}

=head3 $self->add_attachment($filename, $content, %args);

Adds a new attachment to this message.  $filename specifies the file name the recipient will see.
$content should be the Base64-encoded data of the file. Optional arguments are 'type' (the mime type
of the file, such as "image/jpeg"), 'disposition' must be "inline" or "attachment", and 'content_id'
which is used to identify embedded inline attachments.

=cut

sub add_attachment {
    my ($self, $filename, $content, %args) = @_;

    croak "Attachment filename and content are required" unless $filename && $content;

    my $new_attachment = {
        filename => $filename,
        content => $content,
    };

    $new_attachment->{type} = $args{type} if $args{type};
    $new_attachment->{disposition} = $args{disposition} if $args{disposition};
    $new_attachment->{content_id} = $args{content_id} if $args{content_id};

    $self->{data}{attachments} ||= [];
    push @{ $self->{data}{attachments} }, $new_attachment;

    return $self;
}

=head3 $self->template_id($template_id);

Specifies the template you'd like to use for this message.  Templates are managed via the
SendGrid application website.  If the template includes a subject or body, those do not need
to be specified via this api.

=cut

sub template_id {
    my ($self, $template_id) = @_;

    delete $self->{data}{template_id};
    $self->{data}{template_id} = $template_id if $template_id;

    return $self;
}

=head3 $self->clear_sections();

Clears all substitution sections defined in this message.

=cut

sub clear_sections {
    my ($self) = @_;

    delete $self->{data}{sections};

    return $self;
}

=head3 $self->remove_section($key);

Removes one substitution section defined in this message.

=cut

sub remove_section {
    my ($self, $key) = @_;

    croak "Section key name is required" unless $key;

    delete $self->{data}{sections}{$key};

    return $self;
}

=head3 $self->set_section($key, $value);

Sets one new substitution section for this message.  Each occurrence of $key
in each body part will be replaced with $value prior to personalization
substitutions (if any).

=cut

sub set_section {
    my ($self, $key, $value) = @_;

    croak "Section key name is required" unless $key;

    $self->{data}{sections} ||= {};
    $self->{data}{sections}{$key} = $value;

    return $self;
}

=head3 $self->set_sections(%sections);

Sets all substitution sections for this message at once.  For each key/val pair,
occurrences of the key in the message body will be replaced by the value prior to
personalization substitutions (if any).

=cut

sub set_sections {
    my ($self, %sections) = @_;

    delete $self->{data}{sections};
    $self->{data}{sections} = \%sections if %sections;

    return $self;
}

=head3 $self->clear_headers();

Clears all custom headers defined for this message.

=cut

sub clear_headers {
    my ($self) = @_;

    delete $self->{data}{headers};

    return $self;
}

=head3 $self->set_headers(%headers);

Sets all custom SMTP headers for this message at once. These must be properly encoded
if they contain unicode characters. Must not be one of the reserved headers.

These can be overridden at the message personalization level.

=cut

sub set_headers {
    my ($self, %headers) = @_;

    delete $self->{data}{headers};
    $self->{data}{headers} = \%headers if %headers;

    return $self;
}

=head3 $self->clear_categories();

Clears out all categories defined for this message.

=cut

sub clear_categories {
    my ($self) = @_;

    delete $self->{data}{categories};

    return $self;
}

=head3 $self->set_categories(@categories);

Sets the list of categories for this message.  The list of categories must be
unique and contain no more than 10 items.

=cut

sub set_categories {
    my ($self, @categories) = @_;

    croak "Cannot set more than 10 categories"
        if scalar( @categories ) > 10;

    delete $self->{data}{categories};

    $self->{data}{categories} = \@categories if @categories;

    return $self;
}

=head3 $self->add_category($name);

Adds a new category for this message.  The list of categories must be
unique and contain no more than 10 items.

=cut

sub add_category {
    my ($self, $name) = @_;

    croak "Category name is required" unless $name;

    $self->{data}{categories} ||= [];

    croak "Cannot add more than 10 categories"
        if scalar( @{ $self->{data}{categories} } ) > 9;

    push @{ $self->{data}{categories} }, $name;

    return $self;
}

=head3 $self->clear_custom_args();

Clears out all custom arguments defined for this message.

=cut

sub clear_custom_args {
    my ($self) = @_;

    delete $self->{data}{custom_args};

    return $self;
}

=head3 $self->set_custom_args(%args);

Sets all custom arguments defined for this message.
These can be overridden at the message personalization level.
The total size of custom arguments cannot exceed 10,000 bytes.

=cut

sub set_custom_args {
    my ($self, %args) = @_;

    delete $self->{data}{custom_args};

    $self->{data}{custom_args} = \%args if %args;

    return $self;
}

=head3 $self->send_at($timestamp);

A unix timestamp (seconds since 1970) specifying when to deliver this message.
Cannot be more than 72 hours in the future.

This can be overridden at the message personalization level.

=cut

sub send_at {
    my ($self, $timestamp) = @_;

    delete $self->{data}{send_at};
    $self->{data}{send_at} = $timestamp if $timestamp;

    return $self;
}

=head3 $self->batch_id($batch_id);

Identifies a batch to include this message in.  This batch ID can later be used
to pause or cancel the delivery of a batch (if a future delivery time was set)

=cut

sub batch_id {
    my ($self, $batch_id) = @_;

    delete $self->{data}{batch_id};
    $self->{data}{batch_id} = $batch_id if $batch_id;

    return $self;
}

=head3 $self->unsubscribe_group($group_id, @display_groups);

If you've set up multiple unsubscribe groups in the SendGrid web application, this method
allows you to specify which group this message belongs to.  If this is set and the user
unsubscribes from this message, they will only be added to the suppression list for that
single group.  If not set, they will be added to the global unsubscribe list.

@display_groups is optional. If specified, when the user clicks "unsubscribe" they will be
shown a list of these groups and allowed to choose which ones he/she would like to unsubscribe
from.

=cut

sub unsubscribe_group {
    my ($self, $group_id, @display_groups) = @_;

    croak "Unsubscribe group ID is required" unless $group_id;
    croak "Cannot display more than 25 groups" if scalar(@display_groups) > 25;

    $self->{data}{asm} = { group_id => $group_id };
    $self->{data}{asm}{groups_to_display} = \@display_groups if @display_groups;

    return $self;
}

=head3 $self->ip_pool_name($pool_name);

The IP Pool that you would like to send this email from.

=cut

sub ip_pool_name {
    my ($self, $pool_name) = @_;

    delete $self->{data}{ip_pool_name};
    $self->{data}{ip_pool_name} = $pool_name if $pool_name;

    return $self;
}

=head3 $self->click_tracking($enable, %args);

Whether to enable click-tracking for this message.  If enabled, any URLs in the body of this
message will be rewritten to proxy through SendGrid for tracking purposes.  This setting will
overwrite the account-level setting if any.  One optional argument is accepted: 'enable_text'
which controls whether the link-rewriting is also performed for plaintext emails (the rewritten
URL will be visible to the recipient)

=cut

sub click_tracking {
    my ($self, $enable, %args) = @_;

    $enable = $enable ? JSON::true : JSON::false;

    $self->{data}{tracking_settings} ||= {};
    $self->{data}{tracking_settings}{click_tracking} = { enable => $enable };

    if (defined $args{enable_text}) {
        $self->{data}{tracking_settings}{click_tracking}{enable_text} =
            $args{enable_text} ? JSON::true : JSON::false;
    }

    return $self;
}

=head3 $self->open_tracking($enable, %args);

Whether to enable open-tracking for this message.  If enabled, a single transparent pixel image
is added to the HTML body of this message and used to determine if and when the recipient opens
the message.  This setting will overwrite the account-level setting if any.  One optional argument
is accepted: 'substitution_tag' which identifies a token in the message body that should be replaced
with the tracking pixel.

=cut

sub open_tracking {
    my ($self, $enable, %args) = @_;

    $enable = $enable ? JSON::true : JSON::false;

    $self->{data}{tracking_settings} ||= {};
    $self->{data}{tracking_settings}{open_tracking} = { enable => $enable };
    $self->{data}{tracking_settings}{open_tracking}{substitution_tag} =
        $args{substitution_tag} if $args{substitution_tag};

    return $self;
}

=head3 $self->subscription_tracking($enable, %args);

Whether to enable a sendgrid-powered unsubscribe link in the footer of the email.  You may pass
optional arguments 'text' and 'html' to control the verbiage of the unsubscribe link used, OR
'substitution_tag' which is a token that will be replaced with the unsubscribe URL.
This setting will overwrite the account-level setting if any.

=cut

sub subscription_tracking {
    my ($self, $enable, %args) = @_;

    $enable = $enable ? JSON::true : JSON::false;

    my $new = { enable => $enable };
    $new->{text} = $args{text} if $args{text};
    $new->{html} = $args{html} if $args{html};
    $new->{substitution_tag} = $args{substitution_tag} if $args{substitution_tag};

    $self->{data}{tracking_settings} ||= {};
    $self->{data}{tracking_settings}{subscription_tracking} = $new;

    return $self;
}

=head3 $self->ganalytics($enable, %args);

Whether to enable google analytics tracking for this message.  Optional arguments
include 'utm_source', 'utm_medium', 'utm_term', 'utm_content', and 'utm_campaign'.
This setting will overwrite the account-level setting if any.

=cut

sub ganalytics {
    my ($self, $enable, %args) = @_;

    $enable = $enable ? JSON::true : JSON::false;

    my $new = { enable => $enable };
    $new->{utm_source}     = $args{utm_source} if $args{utm_source};
    $new->{utm_medium}     = $args{utm_medium} if $args{utm_medium};
    $new->{utm_term}       = $args{utm_term} if $args{utm_term};
    $new->{utm_content}    = $args{utm_content} if $args{utm_content};
    $new->{utm_campaign}   = $args{utm_campaign} if $args{utm_campaign};

    $self->{data}{tracking_settings} ||= {};
    $self->{data}{tracking_settings}{ganalytics} = $new;

    return $self;
}

=head3 $self->bcc($enable, %args);

Whether to BCC a monitoring account when sending this message.  Optional arguments
include 'email' for the address that will receive the BCC if one is not configured
at the account level.  This setting will overwrite the account-level setting if any.

=cut

sub bcc {
    my ($self, $enable, %args) = @_;

    $enable = $enable ? JSON::true : JSON::false;

    $self->{data}{mail_settings} ||= {};
    $self->{data}{mail_settings}{bcc} = { enable => $enable };
    $self->{data}{mail_settings}{bcc}{email} = $args{email} if $args{email};

    return $self;
}

=head3 $self->bypass_list_management($enable);

Whether to bypass the built-in suppression SendGrid provides, such as unsubscribed
recipients, those that have bounced, or marked the emails as spam.
This setting will overwrite the account-level setting if any.

=cut

sub bypass_list_management {
    my ($self, $enable, %args) = @_;

    $enable = $enable ? JSON::true : JSON::false;

    $self->{data}{mail_settings} ||= {};
    $self->{data}{mail_settings}{bypass_list_management} = { enable => $enable };

    return $self;
}

=head3 $self->footer($enable, %args);

Whether to add a footer to the outgoing message. Optional arguments include 'html' and
'text' to specify the footers that will be used for each message body type.
This setting will overwrite the account-level setting if any.

=cut

sub footer {
    my ($self, $enable, %args) = @_;

    $enable = $enable ? JSON::true : JSON::false;

    $self->{data}{mail_settings} ||= {};
    $self->{data}{mail_settings}{footer} = { enable => $enable };
    $self->{data}{mail_settings}{footer}{text} = $args{text} if $args{text};
    $self->{data}{mail_settings}{footer}{html} = $args{html} if $args{html};

    return $self;
}

=head3 $self->sandbox_mode($enable);

Whether to enable sandbox mode.  When enabled, SendGrid will validate the contents of this
API request for correctness, but will not actually send the message.

=cut

sub sandbox_mode {
    my ($self, $enable, %args) = @_;

    $enable = $enable ? JSON::true : JSON::false;

    $self->{data}{mail_settings} ||= {};
    $self->{data}{mail_settings}{sandbox_mode} = { enable => $enable };

    return $self;
}

=head3 $self->spam_check($enable, %args);

Whether to perform a spam check on this message prior to sending.  If the message fails the
spam check, it will be dropped and not sent.  Optional parameters include 'threshold' - an
integer score value from 1-10 (default 5) over which a message will be classified as spam,
and 'post_to_url' - a SendGrid inbound message parsing URL that will be used to post back
notifications of messages identified as spam and dropped.  These settings will overwrite
the account-level settings if any.

=cut

sub spam_check {
    my ($self, $enable, %args) = @_;

    $enable = $enable ? JSON::true : JSON::false;

    $self->{data}{mail_settings} ||= {};
    $self->{data}{mail_settings}{spam_check} = { enable => $enable };
    $self->{data}{mail_settings}{spam_check}{threshold} = $args{threshold} if $args{threshold};
    $self->{data}{mail_settings}{spam_check}{post_to_url} = $args{post_to_url} if $args{post_to_url};

    return $self;
}

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Grant Street Group.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
