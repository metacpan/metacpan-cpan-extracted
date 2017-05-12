use strict;
use warnings;

use Test::More tests => 2;
use FindBin;
use Test::File::ShareDir::Module {
  '-root'                          => "$FindBin::Bin/../",
  'Gentoo::MetaEbuild::Spec::Base' => 't/fake_spec',
};

use Test::Fatal;

use Gentoo::MetaEbuild::Spec::Base;

ok( Gentoo::MetaEbuild::Spec::Base->check( {}, { version => '0.1.0' } ), ' {} is 0.1.0 spec' );
ok( exception { Gentoo::MetaEbuild::Spec::Base->check( {}, { version => '0.1.2' } ); 0 }, '0.1.2 spec dies' );
