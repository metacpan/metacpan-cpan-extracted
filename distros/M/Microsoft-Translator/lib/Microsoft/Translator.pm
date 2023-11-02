package Microsoft::Translator 0.001;

# ABSTRACT: Client wrapper for Microsoft Translator's REST API

use strict;
use warnings;

no warnings qw{experimental};
use feature qw{signatures state};

use Clone;
use Ref::Util qw{is_arrayref is_hashref};
use UUID::Tiny;
use HTTP::Tiny;
use Cpanel::JSON::XS;
use List::Util;

use Data::Dumper;


sub new( $class, $secret_key, $region, $debug ) {
    return bless({ key => $secret_key, region => $region, debug => $debug }, $class);
}

sub _request ( $self, $path, $method, $params={}, $input=undef ) {

    state $endpoint = 'https://api.cognitive.microsofttranslator.com/';
    state $client = HTTP::Tiny->new();

    # Version this module is developed against
    $params->{'api-version'} = '3.0',

    my $uuid = UUID::Tiny::create_uuid_as_string( UUID::Tiny::UUID_V1, UUID::Tiny::UUID_NS_DNS );
    my $querystring = join('&', (map {
        my $key = $_;
        is_arrayref($params->{$_}) ? join("&", (map { "$key=$_" } @{$params->{$key}})) : "$key=$params->{$key}"
    } keys(%$params)));

    my $uri = "$endpoint$path?$querystring";
    my $body = $input ? Cpanel::JSON::XS::encode_json( $input ) : undef;

    my $response = $client->_request($method, $uri, {
        headers => {
            'Ocp-Apim-Subscription-Key'    => $self->{key},
            'Ocp-Apim-Subscription-Region' => $self->{region},
            'Content-Type'                 => 'application/json',
            'X-ClientTraceId'              => $uuid,
        },
        content => $body,
    });

    print "$method $uri\n" if $self->{debug};
    die "Request Failed: ".Dumper($response) unless $response->{success};
    print "Raw Response:\n$response->{content}\n" if $self->{debug};

    my $decoded = Cpanel::JSON::XS::decode_json( $response->{content} );
    return $decoded;
}


sub translate ( $self, $strings=[], $source_lang="en", @target_langs ) {

    return () unless @$strings;
    die "Must pass at least one target language" unless @target_langs;

    $self->_valid_langs('translation', $source_lang, @target_langs);

    my %params = (
        from => $source_lang,
        to   => [@target_langs]
    );

    my @input = map { { text => $_ } } @$strings;

    my $response = $self->_request( 'translate', "POST", \%params, \@input );
    die "Expected arrayref from /translate!" unless is_arrayref($response);

    # Don't be mean to callers
    my $cloned = Clone::clone($strings);

    # Munge output for easy access
    my %translations;
    foreach my $translation (@$response) {
        my $orig = shift(@$cloned);
        foreach my $subtrans (@{$translation->{translations}}) {
            $translations{$orig} //= {};
            $translations{$orig}{$subtrans->{to}} =  $subtrans->{text};
        }
    }

    return %translations;
}


sub transliterate( $self, $strings, $from_language, $from_script, $target_script ) {
    die "strings to transliterate must be arrayref" unless is_arrayref($strings);
    return () unless @$strings;

    #$self->_valid_langs('transliteration', $source_lang, @target_langs);

    my %params = (
        fromScript => $from_script,
        toScript   => $target_script,
        language   => $from_language,
    );

    my @input = map { { text => $_ } } @$strings;

    my $response = $self->_request( 'transliterate', "POST", \%params, \@input );
    die "Expected arrayref from /translate!" unless is_arrayref($response);

    # Don't be mean to callers
    my $cloned = Clone::clone($strings);

    # Munge output for easy access
    my %translations;
    foreach my $translation (@$response) {
        my $orig = shift(@$cloned);
        $translations{$orig} = $translation->{text};
    }

    return %translations;
}


sub languages ($self, $type) {
    state $list //= {};
    return @{$list->{$type}} if keys(%$list);
    my $response = $self->_request('languages', 'GET' );
    die "Expected hashref from /languages!" unless is_hashref($response);

    foreach my $type (keys(%$response)) {
        $list->{$type} //= [];
        foreach my $lang (keys(%{$response->{$type}})) {
            push(@{$list->{$type}}, $lang);
        }
    }
    return @{$list->{$type}};
}

sub _valid_langs($self, $type, @langs) {
    my @all = $self->languages($type);
    my @supported = grep { my $to_test = $_; List::Util::any { $_ eq $to_test } @all  } @langs;
    die "One of the languages you passed was not supported.  The supported ones passed are:".join(',', @langs) unless @supported == @langs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Microsoft::Translator - Client wrapper for Microsoft Translator's REST API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $secret_key = 'Replace me with the key value in your instance details';
    my $region = 'southcentralus';

    my $tr    = Microsoft::Translator->new( $secret_key, $region);
    my @trans = $tr->translate([qq{Why hello there beautiful lady}], "en", qw{es});
    foreach my $t (@trans) {
        print "$t\n";
    }

=head1 DESCRIPTION

Client module for the microsoft translator service, as described here:
L<https://www.microsoft.com/en-us/translator/business/trial/>
Follow the directions in the "Develop your own app" section in the page linked to get started.

In essence, you have to create an instance of Microsoft Translator on an Azure subscription in some region relevant to your application.
You then will extract the "secret key" from said instance's "Resource" page under the "Keys and Endpoint" heading.
Pass this and the region to the constructor.

Available regions for Azure are here:
L<Azure Regions|https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/?cdn=disable#geographies>

Available languages for Microsoft Translator are here:
L<Translator Languages|https://learn.microsoft.com/en-us/azure/ai-services/translator/language-support>

The various endpoints wrapped by this module are here:
L<Translator REST API Endpoints|https://learn.microsoft.com/en-us/azure/ai-services/translator/reference/rest-api-guide>

This module was developed against the 3.0 version of the API.

=head1 NAME

Microsoft::Translator

=head1 CONSTRUCTOR

=head2 new( STRING secret_key, STRING region, BOOL debug )

Returns an instance of Microsoft::Translator.
Will print additional messages when the debug flag is high.

=head1 METHODS

=head2 translate( STRING[] $strings, STRING $source_language, ARRAY @target_languages)

Translate the provided ARRAYREF of I<strings> which are of I<source_language> to the provided ARRAY of I<target_languages>.

Returns a HASHREF keyed by string and translated language.  Example:

    my $tr    = Microsoft::Translator->new( $secret_key, $region);
    my %trans = $tr->translate([qq{Hello beautiful lady}, qq{What time is it}], "en", qw{es fr});

    print Data::Dumper::dumper(\%trans);

Would print:

    $VAR1 = {
          'Hello beautiful lady' => {
                                      'fr' => 'Bonjour belle dame',
                                      'es' => 'Hola hermosa dama'
                                    },
          'What time is it' => {
                                 'es' => "Qu\x{e9} horas son",
                                 'fr' => 'Quelle heure est-il'
                               }
    };

Dies in the event that the HTTP request fails, or the source/target langs are not supported.

=head2 transliterate( STRING[] $strings, STRING $from_langugage, STRING $from_script, STRING $target_script )

Transliterate provided ARRAYREF of I<strings> written in I<from_script> to I<target_script>.
I<from_language> is also needed, as a number of languages share scripts.

Example:

    my $to_tl = [
        "こんにちは",
        "さようなら"
    ];

    my $tr    = Microsoft::Translator->new( $secret_key, $region);
    my %tld = $tr->transliterate($to_tl, 'ja', 'Jpan', 'Latn');
    print Dumper(\%tld);

Would print:

    $VAR1 = {
          'さようなら' => "\x{e3} \x{e3} \x{e3} \x{e3} \x{aa} \x{e3}",
          'こんにちは' => "\x{e3} \x{e3} \x{e3} \x{ab} \x{e3} 0 \x{e3} \x{304}"
    };

This obviously should be I<konnichiwa> and I<sayonara>, but I get:

    ã ã ã « ã 0 ã ̄"
    ã ã ã ã ª ã"

For whatever reason as of 10/2023.  YMMV.

=head2 languages(STRING type)

Return ARRAY of supported language codes for the given type.
Internally used to validate inputs, so you shouldn't need to call this during normal operations.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Microsoft-Translator-Perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
