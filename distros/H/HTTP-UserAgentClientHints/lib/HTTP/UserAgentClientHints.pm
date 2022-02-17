package HTTP::UserAgentClientHints;
use strict;
use warnings;
use HTTP::UserAgentClientHints::BrandVersion;
use HTTP::UserAgentClientHints::Util;

our $VERSION = '0.04';

my $HTTP_HEADER_PREFIX = 'Sec-CH-UA';

my @FIELDS = qw/
    UA
    Mobile
    Platform
    Arch
    Bitness
    Model
    Full-Version-List
    Full-Version
/;

# Build getters
for my $field (@FIELDS) {
    my $method = __PACKAGE__->_as_method($field);
    no strict 'refs'; ## no critic
    *{__PACKAGE__ . '::' . $method} = sub {
        my $self = shift;
        if (exists $self->{_value}{$method}) {
            return $self->{_value}{$method};
        }
        my $raw_value = $self->{_headers}->header($self->_as_http_header_key($field));
        return $self->{_value}{$method} = $self->_normalize($raw_value, $field);
    };
    *{__PACKAGE__ . '::' . $method . '_raw'} = sub {
        my $self = shift;
        if (exists $self->{_value_raw}{$method}) {
            return $self->{_value_raw}{$method};
        }
        return $self->{_value_raw}{$method} = $self->{_headers}->header($self->_as_http_header_key($field));
    };
}

my $FULL_ACCEPT_CH = __PACKAGE__->_accept_ch;

sub _as_method {
    my ($self, $field) = @_;

    $field =~ s/-/_/g;
    $field = lc $field;

    return $field;
}

sub _as_http_header_key {
    my ($self, $field) = @_;

    return $HTTP_HEADER_PREFIX . (!$field || $field eq 'UA' ? '' : "-$field");
}

sub _normalize {
    my ($self, $value, $field) = @_;

    return $value unless defined $value;

    if ($field eq 'UA' || $field eq 'Full-Version-List') {
        $value = HTTP::UserAgentClientHints::BrandVersion->new($value);
    }
    elsif ($field =~ m!^(?:Platform|Arch|Bitness|Model|Full-Version)$!) {
        $value = HTTP::UserAgentClientHints::Util->strip_quote($value);
    }
    elsif ($field eq 'Mobile') {
        $value =~ s/^\?//;
    }

    return $value;
}

sub new {
    my ($class, $http_headers_obj) = @_;

    unless ($http_headers_obj->can('header')) {
        die q|Argument object:| . ref($http_headers_obj) . q| doesn't have "header" method to get HTTP header value.|;
    }

    bless {
        _headers   => $http_headers_obj,
        _value_raw => {},
        _value     => {},
    }, $class;
}

sub accept_ch {
    return $FULL_ACCEPT_CH unless $_[1];

    return _accept_ch(@_);
}

sub _accept_ch {
    my ($self, $excepts) = @_;

    $excepts ||= [];

    unshift @{$excepts}, 'Sec-CH-UA', 'Sec-CH-UA-Mobile', 'Sec-CH-UA-Platform'; # Default fields

    my @accept_ch;
    for my $field (@FIELDS) {
        my $f = $self->_as_http_header_key($field);
        next if grep { lc($f) eq lc($_) } @{$excepts};
        push @accept_ch, $f;
    }

    return join(', ', @accept_ch);
}

1;

__END__

=encoding UTF-8

=head1 NAME

HTTP::UserAgentClientHints - To Handle User Agent Client Hints


=head1 SYNOPSIS

    use HTTP::UserAgentClientHints;

    my $uach = HTTP::UserAgentClientHints->new($headers);
    print $uach->platform;

    $headers->header('Accept-CH' => $uach->accept_ch);


=head1 DESCRIPTION

HTTP::UserAgentClientHints is the module which gives you a utility to handle User Agent Client Hints (UA-CH)

=head1 METHODS

=head2 new($http_headers_object)

The constructor. The $http_headers_object is required. It should be an object like L<HTTP::Headers> which needs to have C<header> method to get HTTP Header.

=head2 Getters for Sec-CH-UA*

These methods below are normalized to remove double-quotes around value and strip `?` on Sec-UA-CH-Mobile.

=head3 ua

To get the value of Sec-CH-UA as an object of L<HTTP::UserAgentClientHints::BrandVersion>

=head3 mobile

To get the value of Sec-CH-UA-Mobile

=head3 platform

To get the value of Sec-CH-UA-Platform

=head3 arch

To get the value of Sec-CH-UA-Arch

=head3 bitness

To get the value of Sec-CH-UA-Bitness

=head3 model

To get the value of Sec-CH-UA-Model

=head3 full_version_list

To get the value of Sec-CH-UA-Full-Version-List as an object of L<HTTP::UserAgentClientHints::BrandVersion>

=head3 full_version

To get the value of Sec-CH-UA-Full-Version

=head2 Getters for Sec-CH-UA* raw values

=head3 ua_raw

=head3 mobile_raw

=head3 platform_raw

=head3 arch_raw

=head3 bitness_raw

=head3 model_raw

=head3 full_version_list_raw

=head3 full_version_raw

=head2 accept_ch(\@excepts)

To get a string for C<Accept-CH> header in order to request UA-CH. By default, there are the full fields of UA-CH which are including C<Sec-CH-UA-Full-Version> even it's deprecated. If you want to filter fields, then you should set the argument as array ref like below.

    # filtered Sec-CH-UA-Full-Version and Sec-CH-UA-Bitness
    $uach->accept_ch(qw/Sec-CH-UA-Full-Version Sec-CH-UA-Bitness/);

=head1 REPOSITORY

=begin html

<a href="https://github.com/bayashi/HTTP-UserAgentClientHints/blob/main/README.pod"><img src="https://img.shields.io/badge/Version-0.04-green?style=flat"></a> <a href="https://github.com/bayashi/HTTP-UserAgentClientHints/blob/main/LICENSE"><img src="https://img.shields.io/badge/LICENSE-Artistic%202.0-GREEN.png"></a> <a href="https://github.com/bayashi/HTTP-UserAgentClientHints/actions"><img src="https://github.com/bayashi/HTTP-UserAgentClientHints/workflows/main/badge.svg?_t=1645096718"/></a> <a href="https://coveralls.io/r/bayashi/HTTP-UserAgentClientHints"><img src="https://coveralls.io/repos/bayashi/HTTP-UserAgentClientHints/badge.png?_t=1645096718&branch=main"/></a>

=end html

HTTP::UserAgentClientHints is hosted on github: L<http://github.com/bayashi/HTTP-UserAgentClientHints>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<https://github.com/WICG/ua-client-hints/blob/main/README.md>

L<https://wicg.github.io/ua-client-hints/>

=head1 LICENSE

C<HTTP::UserAgentClientHints> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
