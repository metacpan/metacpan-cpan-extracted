use Test2::V0 -no_srand => 1;
use Alien::Build::Wizard::Detect;

is(
  Alien::Build::Wizard::Detect->new(
    uri => "file://localhost/foo/bar/baz",
  ),
  object {
    call [ isa => 'Alien::Build::Wizard::Detect' ] => T();
    call uri => object {
      call [ isa => 'URI' ] => T();
      call scheme => 'file';
      call host => 'localhost';
      call path => '/foo/bar/baz';
    };
    call ua => object {
      call [ isa => 'LWP::UserAgent' ] => T();
    };
    call name => 'baz';
  },
);

is(
  Alien::Build::Wizard::Detect->new(
    uri => 'corpus/alien_build_wizard_detect/auto-1.2.3.tar',
  ),
  object {
    call build_type => ['autoconf'];
    call name       => 'auto';
    call pkg_config => ['bar','foo'];
  },
);

done_testing;
