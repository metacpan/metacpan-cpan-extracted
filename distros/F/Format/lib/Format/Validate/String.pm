package Format::Validate::String 0.2;

use 5.008;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw/
    looks_like_ipv4
/;

our %EXPORT_TAGS = (
    'ip' => [qw/
        looks_like_ipv4
    /]
);

use aliased 'Format::Error::ValueProvideException';

sub looks_like_ipv4 {

    my $value = shift || die ValueProvidedException->new->stacktrace;
    $value =~ /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
}
1;