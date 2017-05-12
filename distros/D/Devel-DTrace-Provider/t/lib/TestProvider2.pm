package TestProvider2;
use strict;
use warnings;
use Devel::DTrace::Provider::Builder;

provider 'provider1' => as {
    probe 'probe11', 'string';
    probe 'probe21', 'integer';
};

provider 'provider2' => as {
    probe 'probe12', 'string';
    probe 'probe22', 'integer';
};

1;
