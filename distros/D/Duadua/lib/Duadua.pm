package Duadua;
use strict;
use warnings;
use Duadua::Parser;

our $VERSION = '0.13';

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
    Duadua::Parser::Bot::YandexBot
    Duadua::Parser::Bot::GooglebotMisc
    Duadua::Parser::Bot::DuckDuckBot
    Duadua::Parser::Bot::Applebot
    Duadua::Parser::Bot::Msnbot
    Duadua::Parser::Bot::BotMisc

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
    Duadua::Parser::Bot::Feedbin
    Duadua::Parser::Bot::Inoreader
    Duadua::Parser::Bot::Fastladder
    Duadua::Parser::Bot::Feedeen
    Duadua::Parser::Browser::Xiaomi
    Duadua::Parser::FeaturePhone::FeaturePhone
    Duadua::Parser::Bot::Netcraft
    Duadua::Parser::Bot::Barkrowler
    Duadua::Parser::Bot::SMTBot
/;

for my $parser (@PARSER_PROC_LIST) {
    eval "require $parser;"; ## no critic
    die "Could not load $parser, $@" if $@;
}

sub new {
    my $class = shift;
    my $ua    = shift;
    my $opt   = shift || {};

    if (!defined $ua) {
        $ua = '';
        if (exists $ENV{HTTP_USER_AGENT} && defined $ENV{HTTP_USER_AGENT}) {
            $ua = $ENV{HTTP_USER_AGENT};
        }
    }

    bless {
        _ua          => $ua,
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

    if (!defined $ua) {
        $ua = '';
        if (exists $ENV{HTTP_USER_AGENT} && defined $ENV{HTTP_USER_AGENT}) {
            $ua = $ENV{HTTP_USER_AGENT};
        }
    }

    $self->{_ua}     = $ua;
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

Duadua - Detect User-Agent


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

If you would like to parse many times, then you can use C<reparse> method. It's fast.

    my $d = Duadua->new;
    for my $ua (@ua_list) {
        my $result = $d->reparse($ua);
        $result->is_bot
            and say $result->name;
    }


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

Parse User-Agent string

=head2 reparse($ua)

Parse User-Agent string by same instance without new

=head2 GETTERS

=over

=item ua

Return raw User-Agent string

=item name

Get User-Agent name

=item is_bot

Return true value if the User-Agent is bot.

=item is_ios

Return true value if the User-Agent is iOS.

=item is_android

Return true value if the User-Agent is Android.

=item is_linux

Return true value if the User-Agent is Linux.

=item is_windows

Return true value if the User-Agent is Windows.

=item is_chromeos

Return true value if the User-Agent is ChromeOS.

=item opt_version

Return version option value. If it's true value, then parse to get User Agent version also.

=item parsers

The list of User Agent Parser

=back

=head1 REPOSITORY

=begin html

<a href="https://github.com/bayashi/Duadua/blob/master/lib/Duadua.pm"><img src="https://img.shields.io/badge/Version-0.13-green?style=flat"></a> <a href="https://github.com/bayashi/Duadua/blob/master/LICENSE"><img src="https://img.shields.io/badge/LICENSE-Artistic%202.0-GREEN.png?style=flat"></a> <a href="https://github.com/bayashi/Duadua/actions"><img src="https://github.com/bayashi/Duadua/workflows/master/badge.svg?_t=1583851185"/></a> <a href="https://coveralls.io/r/bayashi/Duadua"><img src="https://coveralls.io/repos/bayashi/Duadua/badge.png?_t=1583851185&branch=master"/></a>

=end html

Duadua is hosted on github: L<http://github.com/bayashi/Duadua>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

C<Duadua> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
