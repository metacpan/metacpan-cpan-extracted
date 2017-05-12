use strict;
use warnings;

use Test::More tests => 6;

# Handle the case of both RFC-2231 and non-RFC-2231 parameter values.
# In this case, we ignore the non-RFC-2231 parameters

use MIME::Field::ParamVal;
use MIME::WordDecoder;

my $params;

my $wd = supported MIME::WordDecoder 'UTF-8';
$params = MIME::Field::ParamVal->parse_params('inline; filename="foo"; filename*1="ar"; filename*0="b"');

is($params->{'_'}, 'inline', 'Got the "inline" right');
is($wd->decode($params->{'filename'}), 'bar', 'Ignored non-RFC-2231 value if RFC-2231 parameters are present');

$params = MIME::Field::ParamVal->parse_params('inline; filename="foo"');
is($wd->decode($params->{'filename'}), 'foo', 'Got filename if RFC-2231 parameters are absent');

$params = MIME::Field::ParamVal->parse_params('inline; filename*1="ar"; filename*0="b"');
is($wd->decode($params->{'filename'}), 'bar', 'Got RFC-2231 value');

$params = MIME::Field::ParamVal->parse_params('inline; filename*1="ar"; filename="foo"; filename*0="b"');
is($wd->decode($params->{'filename'}), 'bar', 'Ignored non-RFC-2231 value if RFC-2231 parameters are present');

$params = MIME::Field::ParamVal->parse_params('inline; filename*1="ar"; filename*0="b"; filename="foo"');
is($wd->decode($params->{'filename'}), 'bar', 'Ignored non-RFC-2231 value if RFC-2231 parameters are present');
