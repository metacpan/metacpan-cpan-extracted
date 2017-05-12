use strict;
use warnings;

use Test::More tests => 4;
use FindBin;
use Test::File::ShareDir::Module {
  '-root'                          => "$FindBin::Bin/../",
  'Gentoo::MetaEbuild::Spec::Base' => 't/fake_spec',
};

use Gentoo::MetaEbuild::Spec::Base;

ok( Gentoo::MetaEbuild::Spec::Base->check( {}, { version => '0.1.0' } ), ' {} is 0.1.0 spec' );
ok( !Gentoo::MetaEbuild::Spec::Base->check( [], { version => '0.1.0' } ), '[] is not 0.1.0 spec' );
ok( !Gentoo::MetaEbuild::Spec::Base->check( {}, { version => '0.1.1' } ), '{} is not 0.1.1 spec' );
ok( Gentoo::MetaEbuild::Spec::Base->check( [], { version => '0.1.1' } ), '[] is 0.1.1 spec' );
