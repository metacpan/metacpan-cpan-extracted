package Duadua;
use strict;
use warnings;
use Duadua::Parser;

our $VERSION = '0.30';

my @PARSER_PROC_LIST = qw/
    Duadua::Parser::Browser::MicrosoftEdge
    Duadua::Parser::Browser::GoogleChrome
    Duadua::Parser::Browser::MicrosoftInternetExplorer

    Duadua::Parser::Bot::Googlebot
    Duadua::Parser::Bot::GooglebotMobile
    Duadua::Parser::Bot::GooglebotAd
    Duadua::Parser::Bot::GoogleRead
    Duadua::Parser::Bot::Bingbot
    Duadua::Parser::Bot::AdIdxBot
    Duadua::Parser::Bot::BingPreview

    Duadua::Parser::Browser::Opera
    Duadua::Parser::Browser::MozillaFirefox

    Duadua::Parser::Browser::YahooJapanAppBrowser

    Duadua::Parser::Browser::AppleSafari
    Duadua::Parser::Browser::Vivaldi

    Duadua::Parser::Bot::Huawei
    Duadua::Parser::Bot::Sakura
    Duadua::Parser::HTTPClient::HTTPClient

    Duadua::Parser::Bot::Twitterbot
    Duadua::Parser::Bot::FacebookCrawler
    Duadua::Parser::Bot::Slackbot

    Duadua::Parser::Bot::YahooSlurp
    Duadua::Parser::Bot::Baiduspider
    Duadua::Parser::Bot::Bytespider
    Duadua::Parser::Bot::YandexBot
    Duadua::Parser::Bot::GooglebotMisc
    Duadua::Parser::Bot::DuckDuckBot
    Duadua::Parser::Bot::Applebot
    Duadua::Parser::Bot::Msnbot
    Duadua::Parser::Bot::BotMisc
    Duadua::Parser::Bot::Log4Shell

    Duadua::Parser::Browser::GoogleApp
    Duadua::Parser::Browser::SamsungInternetBrowser
    Duadua::Parser::Browser::Yandex
    Duadua::Parser::Browser::DuckDuckGo
    Duadua::Parser::Bot::OracleGrapeshotCrawler
    Duadua::Parser::Bot::MailRUBot
    Duadua::Parser::Browser::PaleMoon
    Duadua::Parser::Browser::UCBrowser
    Duadua::Parser::Browser::BrowserMisc

    Duadua::Parser::Bot::YahooJapanBot
    Duadua::Parser::Bot::HatenaBot
    Duadua::Parser::Bot::Feedly
    Duadua::Parser::Bot::Reeder
    Duadua::Parser::Bot::QuiteRSS
    Duadua::Parser::Bot::Feedbin
    Duadua::Parser::Bot::Inoreader
    Duadua::Parser::Bot::Fastladder
    Duadua::Parser::Bot::Feedeen
    Duadua::Parser::Bot::Feedspot
    Duadua::Parser::Bot::OldReader
    Duadua::Parser::Bot::Flipboard
    Duadua::Parser::Bot::Skype

    Duadua::Parser::Browser::Xiaomi
    Duadua::Parser::FeaturePhone::FeaturePhone
    Duadua::Parser::Bot::Netcraft
    Duadua::Parser::Bot::Barkrowler
    Duadua::Parser::Bot::SMTBot
    Duadua::Parser::Bot::AdstxtCom
    Duadua::Parser::Bot::CentroAdsCrawler
    Duadua::Parser::Bot::LetsEncrypt
/;

for my $parser (@PARSER_PROC_LIST) {
    eval "require $parser;"; ## no critic
    die "Could not load $parser, $@" if $@;
}

sub new {
    my $class = shift;
    my $ua    = shift;
    my $opt   = shift || {};

    bless {
        _ua          => $class->_get_ua_string($ua),
        _parsed      => 0,
        _result      => {},
        _parsers     => $class->_build_parsers($opt),
        _opt_version => $opt->{version},
    }, $class;
}

sub _build_parsers {
    my ($class, $opt) = @_;

    if (exists $opt->{skip}) {
        my @parsers;
        for my $p (@PARSER_PROC_LIST) {
            next if grep { $p eq $_ } @{$opt->{skip}};
            push @parsers, $p;
        }
        return \@parsers;
    }

    return \@PARSER_PROC_LIST;
}

sub opt_version { shift->{_opt_version} }

sub parsers { shift->{_parsers} }

sub ua { shift->{_ua} }

sub reparse {
    my ($self, $ua) = @_;

    $self->{_ua}     = $self->_get_ua_string($ua);
    $self->{_result} = {};

    return $self->_parse;
}

sub _result {
    my ($self, $value) = @_;

    if ($value) {
        $self->{_result} = $value;
        return $self;
    }
    else {
        $self->parse unless $self->{_parsed};
        return $self->{_result};
    }
}

sub parse {
    my $self = shift;

    if (ref $self eq __PACKAGE__) {
        $self->_parse;
    }
    elsif ($self eq __PACKAGE__) {
        # my $d_obj = Duadua->parse('User-Agent String', $opt);
        my $d = __PACKAGE__->new(@_);
        return $d->_parse;
    }
    else {
        # my $d_obj = Duadua::parse('User-Agent String', $opt);
        my $d = __PACKAGE__->new($self, @_);
        return $d->_parse;
    }
}

sub _parse {
    my $self = shift;

    $self->_result(Duadua::Parser->parse($self));
    $self->{_parsed} = 1;

    return $self;
}

sub _get_ua_string {
    my ($self, $ua_raw) = @_;

    if (!defined $ua_raw) {
        return exists $ENV{HTTP_USER_AGENT} && defined $ENV{HTTP_USER_AGENT} ? $ENV{HTTP_USER_AGENT} : '';
    }

    if (ref($ua_raw) =~ m!^HTTP::Headers!) {
        return $ua_raw->header('User-Agent');
    }

    return $ua_raw;
}

sub name {
    shift->_result->{name};
}

sub is_bot {
    shift->_result->{is_bot} ? 1 : 0;
}

sub is_ios {
    shift->_result->{is_ios} ? 1 : 0;
}

sub is_android {
    shift->_result->{is_android} ? 1 : 0;
}

sub is_linux {
    shift->_result->{is_linux} ? 1 : 0;
}

sub is_windows {
    shift->_result->{is_windows} ? 1 : 0;
}

sub is_chromeos {
    shift->_result->{is_chromeos} ? 1 : 0;
}

sub version {
    shift->_result->{version} || '';
}

1;

__END__

=encoding UTF-8

=head1 NAME

Duadua - Detect User-Agent, do up again!


=head1 SYNOPSIS

    use Duadua;

    my $ua = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)';

    my $d = Duadua->new($ua);
    $d->is_bot
        and say $d->name; # Googlebot

Or call as a function to parse immediately

    my $d = Duadua->parse($ua);
    $d->is_bot
        and say $d->name; # Googlebot

And it's able to accept an object like L<HTTP::Headers> instead of user-agent string.

    use HTTP::Headers;
    use Duadua;

    my $headers = HTTP::Headers->new(
        'User_Agent' => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
    );

    my $d = Duadua->new($headers);
    $d->is_bot
        and say $d->name; # Googlebot

B<NOTE> that an object class should be HTTP::Headers[::*], and it should have a method `header` to get specific HTTP-Header.

If you would like to parse many times, then you can use C<reparse> method. It's fast.

    my $d = Duadua->new;
    for my $ua (@ua_list) {
        my $result = $d->reparse($ua);
        $result->is_bot
            and say $result->name;
    }

If you need to get version info, then you should set true value to version option like below.

    use Duadua;

    my $ua = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)';
    my $d = Duadua->new($ua, { version => 1 });
    say $d->version; # 2.1


=head1 DESCRIPTION

Duadua is a User-Agent detector.


=head1 METHODS

=head2 new($user_agent_string, $options_hash)

constructor

=head3 Constructor options

=over

=item version => 1 or 0

If you set the true value to C<version>, then you can get version string. (By default, don't get version)

=item skip => ['ParserClass']

If you set the array to C<skip>, then you can skip detect logic by specific classes.

NOTE that ParserClass is case sensitive, and it might be going to change results.

=back

=head2 parse

Parses User-Agent string

=head2 reparse($ua)

Parses User-Agent string by same instance without new

=head2 GETTERS

=over

=item ua

Returns raw User-Agent string

=item name

Gets User-Agent name

=item is_bot

Returns true value if the User-Agent is bot.

=item is_ios

Returns true value if the User-Agent is iOS.

=item is_android

Returns true value if the User-Agent is Android.

=item is_linux

Returns true value if the User-Agent is Linux.

=item is_windows

Returns true value if the User-Agent is Windows.

=item is_chromeos

Returns true value if the User-Agent is ChromeOS.

=item opt_version

Returns version option value. If it's true value, then parse to get User Agent version also.

=item version

Returns version from user agent string

=item parsers

The list of User Agent Parser

=back

=head1 REPOSITORY

=begin html

<a href="https://github.com/bayashi/Duadua/blob/main/lib/Duadua.pm"><img src="https://img.shields.io/badge/Version-0.30-green?style=flat"></a> <a href="https://github.com/bayashi/Duadua/blob/main/LICENSE"><img src="https://img.shields.io/badge/LICENSE-Artistic%202.0-GREEN.png?style=flat"></a> <a href="https://github.com/bayashi/Duadua/actions"><img src="https://github.com/bayashi/Duadua/workflows/main/badge.svg?_t=1710107282"/></a> <a href="https://coveralls.io/r/bayashi/Duadua"><img src="https://coveralls.io/repos/bayashi/Duadua/badge.png?_t=1710107282&branch=main"/></a>

=end html

Duadua is hosted on github: L<http://github.com/bayashi/Duadua>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

C<Duadua> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
