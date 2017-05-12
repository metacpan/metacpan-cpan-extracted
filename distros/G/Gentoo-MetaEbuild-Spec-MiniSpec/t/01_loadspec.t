
use strict;
use warnings;

use Test::More 0.96;
use FindBin;
use Test::File::ShareDir
  -root  => "$FindBin::Bin/../",
  -share => { -module => { "Gentoo::MetaEbuild::Spec::MiniSpec" => 'share' } };

use Gentoo::MetaEbuild::Spec::MiniSpec;

sub t { Gentoo::MetaEbuild::Spec::MiniSpec->check(@_) }

ok( !t( {} ), 'Empty data is NOT valid with the minispec' );
ok(
  t(
    {
      SCHEME => {
        minversion => '0.1.0',
        standard   => 'default',
      },
    },
  ),
  'Basic Schema Data passes'
);
ok(
  !t(
    {
      SCHEME => {
        minversion => '0.1.0',
        standard   => 'default',
        generator  => {},
      }
    }
  ),
  'empty generator is a fail',
);
ok(
  t(
    {
      SCHEME => {
        minversion => '0.1.0',
        standard   => 'default',
        generator  => { type => 'human', },
      }
    }
  ),
  'generator + type != fail',
);
ok(
  !t(
    {
      SCHEME => {
        minversion => '0.1.0',
        standard   => 'default',
        generator  => {
          type   => 'human',
          author => {},
        },
      }
    }
  ),
  'generator + empty author = fail',
);

ok(
  t(
    {
      SCHEME => {
        minversion => '0.1.0',
        standard   => 'default',
        generator  => {
          type   => 'human',
          author => {
            email => 'kentnl@cpan.org',
            name  => 'kent fredric',
          },
        },
      }
    }
  ),
  'generator + author != fail',
);

ok(
  !t(
    {
      SCHEME => {
        minversion => '0.1.0',
        standard   => 'default',
        generator  => {
          type   => 'perl-module',
          module => {},
        },
      }
    }
  ),
  'generator + empty module = fail',
);
ok(
  t(
    {
      SCHEME => {
        minversion => '0.1.0',
        standard   => 'default',
        generator  => {
          type   => 'perl-module',
          module => {
            name    => 'Example::Module',
            version => '0.1.0',
          },
        },
      }
    }
  ),
  'generator + module != fail',
);

done_testing;
