use inc::Module::Install;
use warnings;
use strict;

name                q(Declare-Constraints-Simple);
abstract_from       q(lib/Declare/Constraints/Simple.pm);
version_from        q(lib/Declare/Constraints/Simple.pm);
author              q(Robert 'phaylon' Sedlacek <phaylon@dunkelheit.at>);
license             q(perl);

requires            @$_ for ( ['Class::Inspector' => 0],
                              ['Carp::Clan'       => 0],
                              ['Scalar::Util'     => 0],
                              ['aliased'          => 0] );

build_requires      'Test::More' => 0;

WriteAll;

1;
