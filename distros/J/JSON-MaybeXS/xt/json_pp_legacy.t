use strict;
use warnings;

$ENV{PERL_JSON_BACKEND} = 'JSON::PP';

require './xt/json_pm_legacy.t';
