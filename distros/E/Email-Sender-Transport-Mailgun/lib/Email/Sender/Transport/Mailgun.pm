package Email::Sender::Transport::Mailgun;
our $VERSION = "0.02";

use Moo;
with 'Email::Sender::Transport';

use HTTP::Tiny                      qw( );
use HTTP::Tiny::Multipart           qw( );
use JSON::MaybeXS                   qw( );
use MooX::Types::MooseLike::Base    qw( ArrayRef Enum Str);

{
  package
    Email::Sender::Success::MailgunSuccess;
  use Moo;
  extends 'Email::Sender::Success';
  has id => (
    is  => 'ro',
    required => 1,
  );
  no Moo;
}

has [qw( api_key domain )] => (
    is => 'ro',
    required => 1,
    isa => Str,
);

has [qw( campaign tag )] => (
    is => 'ro',
    predicate => 1,
    isa => ArrayRef[Str],
    coerce => sub { ref $_[0] ? $_[0] : [ split(/,\s*/, $_[0]) ] },
);

has deliverytime => (
    is => 'ro',
    predicate => 1,
    isa => Str,
    coerce => sub {
        ref $_[0] eq 'DateTime'
            ? $_[0]->strftime('%a, %d %b %Y %H:%M:%S %z') : $_[0]
    },
);

has [qw( dkim testmode tracking tracking_opens )] => (
    is => 'ro',
    predicate => 1,
    isa => Enum[qw( yes no )],
);

has tracking_clicks => (
    is => 'ro',
    predicate => 1,
    isa => Enum[qw( yes no htmlonly )],
);

has region => (
    is => 'ro',
    predicate => 1,
    isa => Enum[qw( us eu )],
);

has base_uri => (
    is => 'lazy',
    builder => sub { 'https://api.mailgun.net/v3' },
);

has uri => (
    is => 'lazy',
);

has ua => (
    is => 'lazy',
    builder => sub { HTTP::Tiny->new(verify_SSL => 1) },
);

has json => (
    is => 'lazy',
    builder => sub { JSON::MaybeXS->new },
);

# https://documentation.mailgun.com/api-sending.html#sending
sub send_email {
    my ($self, $email, $env) = @_;

    my $content = {
        to => ref $env->{to} ? join(',', @{ $env->{to} }) : $env->{to},
        message => {
            filename => 'message.mime',
            content => $email->as_string,
        },
    };

    my @options = qw(
        campaign deliverytime dkim tag testmode
        tracking tracking_clicks tracking_opens
    );

    for my $option (@options) {
        my $has_option = "has_$option";
        if ($self->$has_option) {
            my $key = "o:$option";
            $key =~ tr/_/-/;
            $content->{$key} = $self->$option;
        }
    }

    my $uri = $self->uri . '/messages.mime';
    my $response = $self->ua->post_multipart($uri, $content);

    $self->failure($response, $env->{to})
        unless $response->{success};

    return $self->success($response);
}

sub success {
    my ($self, $response) = @_;

    my $content = $self->json->decode($response->{content});
    return Email::Sender::Success::MailgunSuccess->new(id => $content->{id});
}

sub failure {
    my ($self, $response, $recipients) = @_;

    # Most errors have { message => $message } in the content, some, such as
    # an auth error, have just a plain string.
    my $content = eval { $self->json->decode($response->{content}) };
    my $message = $content && $content->{message}
                ? $content->{message} : $response->{content};

    Email::Sender::Failure->throw({
        message    => $message,
        recipients => $recipients,
    });
}

sub _build_uri {
    my $self = shift;

    my ($proto, $rest) = split('://', $self->base_uri);
    my $api_key = $self->api_key;
    my $domain = $self->domain;

    # adapt endpoint based on region setting.
    $rest =~ s/(\.mailgun)/sprintf('.%s%s', $self->region, $1)/e
        if defined $self->region && $self->region ne 'us';

    return "$proto://api:$api_key\@$rest/$domain";
}

no Moo;
1;
__END__

=encoding utf-8

=for stopwords deliverytime dkim hardcode mailouts prepend templated testmode

=head1 NAME

Email::Sender::Transport::Mailgun - Mailgun transport for Email::Sender

=head1 SYNOPSIS

    use Email::Sender::Simple qw( sendmail );
    use Email::Sender::Transport::Mailgun qw( );

    my $transport = Email::Sender::Transport::Mailgun->new(
        api_key => '...',
        domain  => '...',
    );

    my $message = ...;

    sendmail($message, { transport => $transport });

=head1 DESCRIPTION

This transport delivers mail via Mailgun's messages.mime API.

=head2 Why use this module?

The SMTP transport can also be used to send messages through Mailgun. In this
case, Mailgun options must be specified with Mailgun-specific MIME headers.

This module exposes those options as attributes, which can be set in code, or
via C<EMAIL_SENDER_TRANSPORT_> environment variables.

=head2 Why not use this module?

This module uses Mailgun's messages.mime API, not the full-blown messages API.

If you want to use advanced Mailgun features such as templated batch mailouts
or mailing lists, you're better off using something like L<WebService::Mailgun>
or L<WWW::Mailgun>.

=head1 REQUIRED ATTRIBUTES

The attributes all correspond directly to Mailgun parameters.

=head2 api_key

Mailgun API key. See L<https://documentation.mailgun.com/api-intro.html#authentication>

=head2 domain

Mailgun domain. See L<https://documentation.mailgun.com/api-intro.html#base-url>

=head1 OPTIONAL ATTRIBUTES

These (except region) correspond to the C<o:> options in the C<messages.mime>
section of L<https://documentation.mailgun.com/api-sending.html#sending>

=head2 campaign

Id of the campaign. Comma-separated string list or arrayref of strings.

=head2 deliverytime

Desired time of delivery. String or DateTime object.

=head2 dkim

Enables/disables DKIM signatures. C<'yes'> or C<'no'>.

=head2 region

Defines used Mailgun region. C<'us'> (default) or C<'eu'>.

See L<https://documentation.mailgun.com/en/latest/api-intro.html#mailgun-regions>.

=head2 tag

Tag string. Comma-separated string list or arrayref of strings.

=head2 testmode

Enables sending in test mode. C<'yes'> or C<'no'>.

=head2 tracking

Toggles tracking. C<'yes'> or C<'no'>.

=head2 tracking_clicks

Toggles clicks tracking. C<'yes'>, C<'no'> or C<'html_only'>.

=head2 tracking_opens

Toggles open tracking. C<'yes'> or C<'no'>.

=head1 MIME HEADERS

The C<o:> options above can also be specified using the C<X-Mailgun-> headers
listed here L<https://documentation.mailgun.com/user_manual.html#sending-via-smtp>

If a single-valued option is specified in both the options and the headers,
experimentation shows the header takes precedence. This doesn't seem to be
documented, so don't rely on this behaviour.

Multi-valued options use both the options and the headers.

=head1 ENVIRONMENT

The great strength of Email::Sender is that you don't need to hardcode your
transport, nor any of the options relating to that transport. They can all be
specified via environment variables.

To select the Mailgun transport, use C<EMAIL_SENDER_TRANSPORT=Mailgun>.

To specify any of the attributes above, prepend the attribute name with
C<EMAIL_SENDER_TRANSPORT_>.

=over

=item EMAIL_SENDER_TRANSPORT_api_key

=item EMAIL_SENDER_TRANSPORT_domain

=item EMAIL_SENDER_TRANSPORT_campaign

=item EMAIL_SENDER_TRANSPORT_deliverytime

=item EMAIL_SENDER_TRANSPORT_dkim

=item EMAIL_SENDER_TRANSPORT_region

=item EMAIL_SENDER_TRANSPORT_tag

=item EMAIL_SENDER_TRANSPORT_testmode

=item EMAIL_SENDER_TRANSPORT_tracking

=item EMAIL_SENDER_TRANSPORT_tracking_clicks

=item EMAIL_SENDER_TRANSPORT_tracking_opens

=back

=head1 LICENSE

Copyright (C) Stephen Thirlwall.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Stephen Thirlwall E<lt>sdt@cpan.orgE<gt>

=cut
