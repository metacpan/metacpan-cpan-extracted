package HTML::Pictogram::MobileJp::Util;
use strict;
use warnings;
use utf8;
use parent qw/Exporter/;

our @EXPORT_OK = qw/is_iphone/;

sub is_iphone {
    my $user_agent = shift;
    $user_agent =~ /iPhone/ ? 1 : 0;
}

1;

