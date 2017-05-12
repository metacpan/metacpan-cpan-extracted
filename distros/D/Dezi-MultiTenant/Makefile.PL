use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'Dezi-MultiTenant';
all_from 'lib/Dezi/MultiTenant.pm';
requires 'Test::More'                  => 0;
requires 'Plack::Middleware::Deflater' => 0;
requires 'Plack::Middleware::JSONP'    => 0;
requires 'Dezi'                        => 0.002006;

perl_version '5.8.3';
license 'http://dev.perl.org/licenses/';
homepage 'https://github.com/karpet/dezi-multitenant';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-MultiTenant';
repository 'http://github.com/karpet/dezi-multitenant';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dezi-MultiTenant* dezi.index' },
);
