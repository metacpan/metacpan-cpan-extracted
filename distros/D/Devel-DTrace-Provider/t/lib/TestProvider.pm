package TestProvider;
use strict;
use warnings;
use Devel::DTrace::Provider::Builder;

provider 'provider1' => as {
    probe 'probe1-start', 'string';
    probe 'probe2', 'integer';
};

1;
