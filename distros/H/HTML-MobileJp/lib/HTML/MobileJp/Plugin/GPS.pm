package HTML::MobileJp::Plugin::GPS;
use strict;
use warnings;
use URI::Escape 'uri_escape';
use Params::Validate;
use HTML::Entities;
use base qw/Exporter/;
use Carp();

our @EXPORT = qw/gps_a gps_a_attributes gps_form_attributes gps_form/;

my $codes = +{
    E => +{
        basic => {
            # http://www.au.kddi.com/ezfactory/tec/spec/eznavi.html
            a => sub {
                +{ href => 'device:location?url=' . uri_escape $_[0] };
            },
            form => sub {
                +{ action => 'device:location?url=' . uri_escape $_[0] };
            },
        },
        gps => {
            # http://www.siisise.net/gps.html#augps
            # datum:wgs84, unit:dms
            a => sub {
                +{
                    href => (
                            'device:gpsone?url='
                        . uri_escape( $_[0] )
                        . '&ver=1&datum=0&unit=0&acry=0&number=0'
                    )
                }
            },
            form => sub {
                +{
                    action => 'device:gpsone',
                    hidden => +{
                        url    => $_[0],
                        ver    => 1,
                        datum  => 0,
                        unit   => 0,
                        acry   => 0,
                        number => 0,
                    },
                },
            },
          }
    },
    I => +{
        gps => {
            # http://www.nttdocomo.co.jp/service/imode/make/content/gps/
            'a'    => sub { +{ href   => $_[0], lcs => 'lcs' } },
            'form' => sub { +{ action => $_[0], lcs => 'lcs' } },
        },
        basic => {
            # http://www.nttdocomo.co.jp/service/imode/make/content/iarea/
            a => sub {
                +{
                    href => (
                            'http://w1m.docomo.ne.jp/cp/iarea'
                        . '?ecode=OPENAREACODE&msn=OPENAREAKEY&posinfo=1&nl='
                        . uri_escape $_[0]
                    )
                };
            },
            form => sub {
                +{
                    action => "http://w1m.docomo.ne.jp/cp/iarea",
                    hidden => {
                        ecode   => 'OPENAREACODE',
                        msn     => 'OPENAREAKEY',
                        posinfo => 1,
                        nl      => $_[0],
                    },
                },
            },
        },
    },
    H => +{
        basic => {
            # http://www.willcom-inc.com/ja/service/contents_service/club_air_edge/for_phone/homepage/index.html
            # DO NOT uri_escape. WILLCOM PHONES REQUIRE RAW URI.
            a => sub {
                +{      href => 'http://location.request/dummy.cgi?my='
                    . $_[0]
                    . '&pos=$location' };
            },
            form => sub {
                Carp::croak("form type is not supported on willcom(maybe)");
            },
        },
    },
    V => +{
        gps => +{
            # see HTML編 in http://creation.mb.softbank.jp/web/web_doc.html
            # DO NOT uri_escape. SOFTBANK PHONES REQUIRE RAW URI.
            a => sub {
                +{ href => 'location:auto?url=' . $_[0] }
            },
            form => sub {
                +{ action => 'location:auto?url=' . $_[0] }
            },
        },
        basic => {
            # see HTML編 in http://creation.mb.softbank.jp/web/web_doc.html
            a => sub {
                +{ href => $_[0], z => 'z' };
            },
            form => sub {
                +{ action => $_[0], z => 'z' };
            },
        }
    },
};

sub gps_a_attributes {
    my %args = validate(
        @_,
        +{
            callback_url => +{ regex => qr{^https?://} },
            carrier      => +{ regex => qr{^[IEVH]$} },
            is_gps       => 1,
        }
    );

    $codes->{$args{carrier}}->{$args{is_gps} ? 'gps' : 'basic'}->{a}->($args{callback_url});
}

sub gps_form_attributes {
    my %args = validate(
        @_,
        +{
            callback_url => { regex => qr{^https?://} },
            carrier      => { regex => qr{^[IEVH]$} },
            is_gps       => 1,
        }
    );

    $codes->{$args{carrier}}->{$args{is_gps} ? 'gps' : 'basic'}->{'form'}->($args{callback_url});
}

sub gps_a {
    my %args = validate(
        @_,
        +{
            callback_url => { regex => qr{^https?://} },
            carrier      => { regex => qr{^[IEVH]$} },
            is_gps       => 1,
        }
    );

    my $attributes = gps_a_attributes(%args);

    my $ret = "";
    for my $name (sort { $a cmp $b } keys %$attributes) {
        $ret .= qq{ $name="} . encode_entities($attributes->{$name}) . q{"};
    }
    "<a$ret>";
}

sub gps_form {
    my %args = validate(
        @_,
        +{
            callback_url => { regex => qr{^https?://} },
            carrier      => { regex => qr{^[IEVH]$} },
            is_gps       => 1,
        }
    );

    my $attributes = gps_form_attributes(%args);

    my $hidden = delete $attributes->{hidden};

    my $ret = "";
    for my $name (sort { $a cmp $b } keys %$attributes) {
        $ret .= qq{ $name="} . encode_entities($attributes->{$name}) . q{"};
    }
    $ret = "<form$ret>";
    for my $name (sort { $a cmp $b } keys %$hidden) {
        $ret .= qq!\n<input type="hidden" name="$name" value="$hidden->{$name}" />!;
    }
    $ret;
}

1;
__END__

=for stopwords mobile-jp html TODO CGI ezweb GPS

=encoding utf8

=head1 NAME

HTML::MobileJp::Plugin::GPS - generate GPS tags

=head1 SYNOPSIS

    use HTML::MobileJp;
    gps_a(
        carrier => 'I',
        is_gps => 0,
        callback_url => 'http://example.com/gps/jLKJFJDSL',
    );
    # => <a href="http://w1m.docomo.ne.jp/cp/iarea?ecode=OPENAREACODE&amp;msn=OPENAREAKEY&amp;posinfo=1&amp;nl=http%3A%2F%2Fexample.com%2Fgps%2FjLKJFJDSL">

=head1 DESCRIPTION

This module generates 'A' tag and 'form' tag for sending the location information.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom aaaatttt gmail dotottto commmmmE<gt>

=head1 SEE ALSO

L<HTML::MobileJp>, L<http://www.au.kddi.com/ezfactory/tec/spec/wap_tag5.html>, L<HTTP::MobileAgent::Plugin::Locator>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
