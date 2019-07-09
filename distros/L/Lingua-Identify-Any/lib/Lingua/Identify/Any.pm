package Lingua::Identify::Any;

our $DATE = '2019-07-08'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010_001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = qw(detect_text_language);

our %SPEC;

our @BACKENDS = (
    'Lingua::Identify::CLD',
    'Lingua::Identify',
    'WebService::DetectLanguage',
);

$SPEC{detect_text_language} = {
    v => 1.1,
    summary => 'Detect language of text using one of '.
        'several available backends',
    description => <<'_',

Backends will be tried in order. When a backend is not available, or when it
fails to detect the language, the next backend will be tried. Currently
supported backends:

* Lingua::Identify::CLD
* Lingua::Identify
* WebService::DetectLanguage (only when `try_remote_backends` is set to true)

_
    args => {
        text => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        backends => {
            schema => ['array*', of=>['str*', in=>\@BACKENDS]],
        },
        try_remote_backends => {
            schema => 'bool*',
        },
        dlcom_api_key => {
            summary => 'API key for detectlanguage.com',
            description => <<'_',

Only required if you use WebService::DetectLanguage backend.

_
            schema => 'str*',
        },
    },
    result => {
        schema => 'hash',
        description => <<'_',

Status: will return 200 status if detection is successful. Otherwise, will
return 400 if a specified backend is unknown/unsupported, or 500 if detection
has failed.

Payload: a hash with the following keys: `backend` (the backend name used to
produce the result), `lang_code` (str, 2-letter ISO language code), `confidence`
(float), `is_reliable` (bool).

_
    },
};
sub detect_text_language {
    my %args = @_;

    my $backends = $args{backends} //
        ($ENV{PERL_LINGUA_IDENTIFY_ANY_BACKENDS} ?
         [split /\s*,\s*/, $ENV{PERL_LINGUA_IDENTIFY_ANY_BACKENDS}] : undef);
    my $try_remote_backends = $args{try_remote_backends} //
        $ENV{PERL_LINGUA_IDENTIFY_ANY_TRY_REMOTE_BACKENDS};
    my $dlcom_api_key = $args{dlcom_api_key} //
        $ENV{PERL_LINGUA_IDENTIFY_ANY_DLCOM_API_KEY};
    my @backends = (
        'Lingua::Identify::CLD',
        'Lingua::Identify',
        ($try_remote_backends ? ('WebService::LanguageDetect') : ()),
    );
    @backends = @$backends if $backends;

    my $res = [500, "No backend was tried", {}, {
        'func.attempted_backends' => [],
    }];

  BACKEND:
    for my $backend (@backends) {
        if ($backend eq 'Lingua::Identify::CLD') {
            eval { require Lingua::Identify::CLD; 1 };
            if ($@) {
                log_debug "Skipping backend 'Lingua::Identify::CLD' because module is not available: $@";
                next BACKEND;
            }
            my $cld = Lingua::Identify::CLD->new;
            my @lang = $cld->identify($args{text});
            push @{$res->[3]{'func.attempted_backends'}}, 'Lingua::Identify::CLD';
            if (!@lang) {
                log_debug "Backend 'Lingua::Identify::CLD' failed to detect language";
                next BACKEND;
            }
            $res->[0] = 200;
            $res->[1] = "OK";
            $res->[2] = {
                backend     => 'Lingua::Identify::CLD',
                lang_code   => $lang[1],
                confidence  => $lang[2] / 100,
                is_reliable => $lang[3],
            };
            goto RETURN_RES;
            # XXX put the other less probable language to func.*
        } elsif ($backend eq 'Lingua::Identify') {
            eval { require Lingua::Identify; 1 };
            if ($@) {
                log_debug "Skipping backend 'Lingua::Identify' because module is not available: $@";
                next BACKEND;
            }
            my @bres = Lingua::Identify::langof($args{text});
            push @{$res->[3]{'func.attempted_backends'}}, 'Lingua::Identify';
            if (!@bres) {
                log_debug "Backend 'Lingua::Identify' failed to detect language, trying the next backend";
                next BACKEND;
            }
            $res->[0] = 200;
            $res->[1] = "OK";
            $res->[2] = {
                backend    => 'Lingua::Identify',
                lang_code  => $bres[0],
                confidence => $bres[1],
                is_reliable => 1,
            };
            goto RETURN_RES;
            # XXX put the other less probable language to func.*
        } elsif ($backend eq 'WebService::DetectLanguage') {
            eval { require WebService::DetectLanguage; 1 };
            if ($@) {
                log_debug "Skipping backend 'WebService::DetectLanguage' because module is not available: $@";
                next BACKEND;
            }
            $dlcom_api_key or do {
                log_warn "Backend 'WebService::DetectLanguage' cannot be used, API key (dlcom_api_key) not provided, trying the next backend";
                next BACKEND;
            };
            my $api = WebService::DetectLanguage->new(key => $dlcom_api_key);
            my @possib = $api->detect($args{text});
            push @{$res->[3]{'func.attempted_backends'}}, 'WebService::DetectLanguage';
            if (!@possib) {
                log_debug "Backend 'WebService::DetectLanguage' failed to detect language, trying the next backend";
                next BACKEND;
            }
            $res->[0] = 200;
            $res->[1] = "OK";
            $res->[2] = {
                backend     => 'WebService::DetectLanguage',
                lang_code   => $possib[0]->language->code,
                confidence_raw => $possib[0]->confidence, # not a range/percentage, the more text is being fed, the higher the confidence
                confidence  => undef,
                is_reliable => $possib[0]->is_reliable,
            };
            goto RETURN_RES;
            # XXX put the other less probable language to func.*
        } else {
            $res->[0] = 400;
            $res->[1] = "Unknown/unsupported backend '$backend'";
            goto RETURN_RES;
        }
    }

    $res->[1] = 'No backends were able to detect the language'
        if @{ $res->[3]{'func.attempted_backends'} };
  RETURN_RES:
    $res;
}

1;
# ABSTRACT: Detect language of text using one of several available backends

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Identify::Any - Detect language of text using one of several available backends

=head1 VERSION

This document describes version 0.001 of Lingua::Identify::Any (from Perl distribution Lingua-Identify-Any), released on 2019-07-08.

=head1 SYNOPSIS

 use Lingua::Identify::Any qw(
     detect_text_language
 );

 my $res = detect_text_language(text => 'Blah blah blah');

Sample result:

 [200, "OK", {
     backend     => 'Lingua::Identify',
     lang_code   => "en",
     confidence  => 0.78, # 1 would mean certainty
     is_reliable => 1,
 }]

=head1 DESCRIPTION

This module offers a common interface to several language detection backends.

=head1 FUNCTIONS


=head2 detect_text_language

Usage:

 detect_text_language(%args) -> [status, msg, payload, meta]

Detect language of text using one of several available backends.

Backends will be tried in order. When a backend is not available, or when it
fails to detect the language, the next backend will be tried. Currently
supported backends:

=over

=item * Lingua::Identify::CLD

=item * Lingua::Identify

=item * WebService::DetectLanguage (only when C<try_remote_backends> is set to true)

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backends> => I<array[str]>

=item * B<dlcom_api_key> => I<str>

API key for detectlanguage.com.

Only required if you use WebService::DetectLanguage backend.

=item * B<text>* => I<str>

=item * B<try_remote_backends> => I<bool>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (hash)


Status: will return 200 status if detection is successful. Otherwise, will
return 400 if a specified backend is unknown/unsupported, or 500 if detection
has failed.

Payload: a hash with the following keys: C<backend> (the backend name used to
produce the result), C<lang_code> (str, 2-letter ISO language code), C<confidence>
(float), C<is_reliable> (bool).

=head1 ENVIRONMENT

=head2 PERL_LINGUA_IDENTIFY_ANY_BACKENDS

String. Comma-separated list of backends.

=head2 PERL_LINGUA_IDENTIFY_ANY_TRY_REMOTE_BACKENDS

Boolean. Set the default for L</detect_text_language>'s C<try_remote_backends>
argument.

If set to 1, will also include backends that query remotely, e.g.
L<WebService::DetectLanguage>.

=head2 PERL_LINGUA_IDENTIFY_ANY_DLCOM_API_KEY

String. Set the default for L</detect_text_language>'s C<dlcom_api_key>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Lingua-Identify-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Lingua-Identify-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-Identify-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
