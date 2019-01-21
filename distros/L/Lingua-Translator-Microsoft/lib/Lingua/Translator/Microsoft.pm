package Lingua::Translator::Microsoft;
use 5.10.0;

use Moose;
use MooseX::HasDefaults::RO;
use MooseX::StrictConstructor;
use namespace::autoclean;

use Carp;
use JSON;
use LWP::UserAgent;
use Params::Validate qw(:all);
use URI;
use XML::Simple;
use version;

our $VERSION = qv('1.1.2');

has api_key => (
    isa      => 'Str',
    required => 1,
);

has app_id => (
    isa      => 'Str',
    required => 1,
);

has auth_url => (
    isa => 'Str',
    default => 'https://datamarket.accesscontrol.windows.net/v2/OAuth2-13',
);

has api_url => (
    isa => 'Str',
    default => 'http://api.microsofttranslator.com/v2/Http.svc',
);

# so that the token doesn't expire after checking it but before the request
# is processed on the other side.
has token_expiry_shift => (
    isa      => 'Str',
    required => 0,
    default  => 10,
);

has clock => (
    isa     => 'CodeRef',
    default => sub {sub {time}}
);

has ua_string => (
    isa     => 'Str',
    default => "Lingua-Translator-Microsoft/$VERSION",
);

has _token => (
    is       => 'rw',
    isa      => 'Maybe[Str]',
    default  => undef,
    init_arg => undef,
);

has _token_expiry => (
    is       => 'rw',
    isa      => 'Int',
    default  => 0,
    init_arg => undef,
);

has _ua_token => (
    isa      => 'LWP::UserAgent',
    builder  => '_build_ua_token',
    lazy     => 1,
    init_arg => undef,
);

has _ua_bing => (
    isa      => 'LWP::UserAgent',
    builder  => '_build_ua_bing',
    lazy     => 1,
    init_arg => undef,
);

sub _build_ua_token {
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        agent => $self->ua_string,
    );
    $ua->default_header(
        'Content-Type' => 'application/x-www-form-urlencoded'
    );
    return $ua;
}

sub _build_ua_bing {
    my $self = shift;
    return LWP::UserAgent->new(
        agent          => $self->ua_string,
        #default_headers => {
        #    "Content-Type" => "text/xml",
        #},
    );
}

sub translate {
    my $self = shift;
    my ($from, $to, $text) = validate_pos(
        @_,
        {type => SCALAR, regex => '.+'},
        {type => SCALAR, regex => '.+'},
        {type => SCALAR},
    );

    return $self->_make_api_call(
        {
            call   => 'Translate',
            method => 'GET',
            args   => {
                text => $text,
                from => $from,
                to   => $to,
            },
            process_response => sub {
                my $r   = shift;
                my $xml = XML::Simple::XMLin($r);
                return $xml->{content};
            }
        }
    );
}

sub get_translations {
    my $self = shift;
    my ($from, $to, $text, $opts) = validate_pos(
        @_,
        {type => SCALAR, regex => '.+'},
        {type => SCALAR, regex => '.+'},
        {type => SCALAR},
        {type => HASHREF, regex => '.+', optional => 1},
    );
    $opts //= {};
    my $max_translations = $opts->{max_translations} // 5;

    return $self->_make_api_call(
        {
            call   => 'GetTranslations',
            method => 'POST',
            args   => {
                text            => $text,
                from            => $from,
                to              => $to,
                maxTranslations => $max_translations,
            },
            process_response => sub {
                my $r            = shift;
                my $xml          = XML::Simple::XMLin($r, ForceArray => 'TranslationMatch');
                my @translations = map { $_->{TranslatedText}->[0] } @{$xml->{Translations}->[0]->{TranslationMatch}};
                return wantarray ? @translations : \@translations;
            },
        }
    );
}

sub detect {
    my $self = shift;
    my ($text) = validate_pos(@_, {type => SCALAR});

    return $self->_make_api_call(
        {
            call   => 'Detect',
            method => 'GET',
            args   => {
                text            => $text,
            },
            process_response => sub {
                my $r            = shift;
                my $xml          = XML::Simple::XMLin($r);
                return $xml->{content};
            },
        }
    );
}

sub speak {
    my $self = shift;
    my ($language, $text, $opts) = validate_pos(
        @_,
        {type => SCALAR, regex => '.+'},
        {type => SCALAR},
        {type => HASHREF, regex => '.+', optional => 1},
    );

    return $self->_make_api_call(
        {
            call   => 'speak',
            method => 'GET',
            args   => {
                language        => $language,
                text            => $text,
                $opts ? %$opts : (),
            },
            process_response => sub {
                my $r           = shift;
                return $r;
            },
        }
    );
}

sub _get_token {
    my $self = shift;
    return $self->_token if($self->_token && $self->clock->() < $self->_token_expiry);
    my $ua = $self->_ua_token;
    my $r = $ua->post($self->auth_url, {
        grant_type     => 'client_credentials',
        client_id      => $self->app_id,
        client_secret  => $self->api_key,
        scope          => "http://api.microsofttranslator.com",
    });
    my $resp_data       = JSON::decode_json $r->decoded_content;
    $self->_token($resp_data->{access_token});
    $self->_token_expiry($self->clock->() + $resp_data->{expires_in} - $self->token_expiry_shift);
    return $self->_token;
}

sub _make_api_call {
    my ($self, $args) = @_;

    my $method = lc $args->{method};
    $self->_ua_bing->default_header(
        'Authorization' => 'Bearer ' . $self->_get_token,
    );
    my $uri = URI->new($self->api_url . "/" . $args->{call});
    $uri->query_form(%{$args->{args}});
    my $response = $self->_ua_bing->$method( $uri->as_string );
    if($response->is_success) {
        return $args->{process_response}->($response->decoded_content);
    } else {
        my @err = ($response->code, $response->message, $response->decoded_content);
        croak "@err";
    }
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf8

=head1 NAME

Lingua::Translator::Microsoft - A client library for the Microsoft Translator API

=head1 SYNOPSIS

    my $api_key = read_file('/home/myapp/priv/translator.priv');
    my $translator = Lingua::Translator::Microsoft->new(
        api_key  => $api_key,
        app_id   => $app_id,
    );

    say $translator->translate('nl', 'en', 'voorbeeld'); # outputs 'example'

    my $mp3 = $translator->speak('de', 'Worüber man nicht sprechen kann, darüber muss man schweigen');
    open(my $fh, ">", "tractatus.mp3", {format => "mp3"});
    print $fh $mp3;
    system("mplayer tractatus.mp3");

    say $translator->detect("Ci vuole un fiore."); # outputs 'it'

=head1 DESCRIPTION

This is a client library for Microsoft's translate service. Currently you can use the following calls from the API:

=over 4

=item Translate

=item GetTranslations

=item Detect

=item Speak

=back

All API-calling methods croak() unless they get a successful reply from the service.

=head1 FUNCTIONS

=head2 Lingua::Translator::Microsoft->new(api_key => $api_key, app_id => $app_id);

Instantiate a new Lingua::Translator::Microsoft object.

Arguments:

=over 4

=item

api_key [required]

The API key (client secret).

=item

app_id [required]

Your application ID (client id). You need to register your application to be able to use the service.

=item

auth_url [optional]

The URL to get the OAuth token from. Defaults to https://datamarket.accesscontrol.windows.net/v2/OAuth2-13. You probably don't need to change this.

=item

api_url [optional]

The URL for the Microsoft Translator API (v2). Defaults to http://api.microsofttranslator.com/v2/Http.svc. You probably don't need to change this.

=back

Returns:

=over 4

=item

A new Lingua::Translator::Microsoft instance.

=back

=head2 $translator->translate($source_language_code, $target_language_code, $text)

Translate some text

Arguments:

=over 4

=item

source_language_code [required] (String)

=item

target_language_code [required] (String)

=item

text [required] (String)

The text to translate.

=back

Returns:

=over 4

=item

The translated text as a string.

=back

=head2 $translator->get_translations($source_language_code, $target_language_code, $text, { max_translations => 3})

Translate some text (with multiple results).

This function is sensitive to context. It returns an arrayref of translation in scalar context but a list of translations in list context.

Arguments:

=over 4

=item

source_language_code [required] (String)

=item

target_language_code [required] (String)

=item

text [required] (String)

The text to translate.

=item

options [optional] (Hashref)

A struct containing options to the call. For now the only option that you can put here is max_translations
which limits the number of results to a given number. max_translations defaults to 5.

=back

Returns:

=over 4

=item

In list context the results as a list of strings (translations).

=item

In scalar context an arrayref of strings (translations).

=back

=head2 $translator->speak($language_code, $text)

Pronounce some text

Arguments:

=over 4

=item

language_code [required] (String)

=item

text [required] (String)

The text to synthetize.

=back

Returns:

=over 4

=item

A wav stream containing the text spoken in the chosen language.

=back

=head2 $translator->detect($text)

Detect the language of a text.

Arguments:

=over 4

=item

text [required] (String)

The text to do language detection on.

=back

Returns:

=over 4

=item

The code of the detected language.

=back

=head1 AUTHOR

This module is written by Larion Garaczi <larion@cpan.org> (2016)

=head1 SOURCE CODE

The source code for this module is hosted on GitHub L<https://github.com/larion/lingua-translator-microsoft>.

Feel free to contribute :)

=head1 LICENSE AND COPYRIGHT

This module is free software and is published under the same
terms as Perl itself.

=cut
