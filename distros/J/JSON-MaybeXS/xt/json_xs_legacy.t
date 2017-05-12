use strict;
use warnings;

$ENV{PERL_JSON_BACKEND} = 'JSON::XS';

require 'xt/json_pm_legacy.t';
