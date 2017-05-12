package FormValidator::LazyWay::Rule::Net;

use strict;
use warnings;
use Data::Validate::URI;

sub uri {
    my $uri = shift;
    return Data::Validate::URI::is_uri( $uri ) ? 1 : 0;
}

sub url {
    my $url = shift;
    return Data::Validate::URI::is_web_uri($url) ? 1 : 0;
}

sub http {
    my $url = shift;
    return Data::Validate::URI::is_http_uri($url) ? 1 : 0;
}

sub https {
    my $url = shift;
    return Data::Validate::URI::is_https_uri($url) ? 1 : 0;
}

sub url_loose {
    my $url = shift;

    return $url =~ m{^https?://[-_.!~*'()a-zA-Z0-9;/?:\@&=+\$,%#]+$} ? 1 : 0;
}

sub http_loose {
    my $url = shift;
    return $url =~ m{^http://[-_.!~*'()a-zA-Z0-9;/?:\@&=+\$,%#]+$} ? 1 : 0;
}

sub https_loose {
    my $url = shift;
    return $url =~ m{^https://[-_.!~*'()a-zA-Z0-9;/?:\@&=+\$,%#]+$} ? 1 : 0;
}

1;
