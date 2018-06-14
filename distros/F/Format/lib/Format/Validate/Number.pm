package Format::Validate::Number 0.2;

use 5.008;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw/
    looks_like_money
/;

our %EXPORT_TAGS = (
    'money' => [qw/
        looks_like_money
    /]
);

use aliased 'Format::Error::ValueProvideException';
use aliased 'Format::Error::ValueNumericException';

sub looks_like_money {

    my $value = shift || die ValueProvideException->new->stacktrace;
    $value =~ /^\d{1,3}(\.\d{3})*\,\d+$/;
}
1;