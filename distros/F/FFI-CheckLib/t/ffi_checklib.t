use lib 't/lib';
use Test2::V0 -no_srand => 1;
use Test2::Plugin::FauxOS 'linux';
use Test2::Tools::FauxDynaLoader;
use File::Spec;
use File::Basename qw( basename );
use FFI::CheckLib qw( find_lib which where has_symbols );

subtest 'recursive' => sub {

  $FFI::CheckLib::system_path = [];

  my @libs = find_lib(
    libpath   => File::Spec->catdir( 'corpus', 'unix', 'foo-1.00'  ),
    lib       => 'foo',
    recursive => 1,
  );

  is scalar(@libs), 1, "libs = @libs";
  like $libs[0], qr{libfoo.so}, "libs[0] = $libs[0]";
};

subtest 'star' => sub {

  $FFI::CheckLib::system_path = [];

  my @libs = find_lib(
    libpath   => File::Spec->catdir( 'corpus', 'unix', 'foo-1.00'  ),
    lib       => '*',
    recursive => 1,
  );

  is scalar(@libs), 3, "libs = @libs";

  my @fn = sort map { (File::Spec->splitpath($_))[2] } @libs;
  is \@fn, [qw( libbar.so libbaz.so libfoo.so )], "fn = @fn";

};

subtest 'which' => sub {

  my %find_lib_args;

  my $mock = mock 'FFI::CheckLib' => (
    override => [
      find_lib => sub {
        %find_lib_args = @_;
        my @ret = qw( /usr/lib/libfoo.so.1.2.3 /usr/lib/libbar.so.1.2.3 );
        wantarray ? @ret : $ret[0];
      },
    ],
  );

  is( which('foo'), '/usr/lib/libfoo.so.1.2.3' );
  is(
    \%find_lib_args,
    hash {
      field 'lib' => 'foo';
      end;
    }
  );

};

subtest 'which' => sub {

  my %find_lib_args;

  my $mock = mock 'FFI::CheckLib' => (
    override => [
      find_lib => sub {
        %find_lib_args = @_;
        my @ret = qw( /usr/lib/libfoo.so.1.2.3 /usr/lib/libbar.so.1.2.3 );
        wantarray ? @ret : $ret[0];
      },
    ],
  );

  subtest 'with name' => sub {

    is( [where('foo')], ['/usr/lib/libfoo.so.1.2.3','/usr/lib/libbar.so.1.2.3'] );
    is(
      \%find_lib_args,
      hash {
        field 'lib' => '*';
        field 'verify' => T();
        end;
      }
    );

  };

  subtest 'with wildcard' => sub {

    is( [where('*')], ['/usr/lib/libfoo.so.1.2.3','/usr/lib/libbar.so.1.2.3'] );
    is(
      \%find_lib_args,
      hash {
        field 'lib' => '*';
        end;
      }
    );

  };

};

subtest 'has_symbols' => sub {

  my $mock = mock_dynaloader;

  is(
    has_symbols('corpus/generic.dll'),
    T(),
  );

  is(
    has_symbols('corpus/generic.dll', qw( foo bar baz)),
    T(),
  );

  is(
    has_symbols('corpus/generic.dll', qw( foo bar )),
    T(),
  );

  is(
    has_symbols('corpus/generic.dll', qw( foo )),
    T(),
  );

  is(
    has_symbols('corpus/generic.dll', qw( foo bar baz bogus )),
    F(),
  );

  is(
    has_symbols('corpus/generic.dll', qw( bogus )),
    F(),
  );

};

subtest 'system_path' => sub {

  @{ $FFI::CheckLib::system_path } = (qw( /foo /bar /baz ));

  is(
    FFI::CheckLib::system_path(),
    [ qw( /foo /bar /baz ) ],
  );

};

subtest 'alien' => sub {

  @{ $FFI::CheckLib::system_path } = ();

  subtest 'preloaded' => sub {

   my $alien = mock 'Alien::libfoo' => (
      add => [
        dynamic_libs => sub {
          'corpus/unix/lib/libfoo.so.2.3.4',
        },
      ],
    );

    is(
      [FFI::CheckLib::find_lib( lib => 'foo', alien => ['Alien::libfoo'])],
      array {
        item 0 => match qr/foo/;
        end;
      },
    );

  };

  subtest 'autoload' => sub {

    local @INC = @INC;
    unshift @INC, 'corpus/lib';

    is(
      [FFI::CheckLib::find_lib( lib => 'bar', alien => ['Alien::libbar'])],
      array {
        item 0 => match qr/bar/;
        end;
      },
    );

  };

  subtest 'invalid name' => sub {

    is dies { FFI::CheckLib::find_lib( lib => 'bar', alien => ['x..y']) }, match qr/Doesn't appear to be a valid Alien name x\.\.y/;

  };

  subtest 'no dynamic_libs method' => sub {

    {
      package Alien::libbaz;
      $INC{'Alien/libbaz.pm'} = __PACKAGE__;
    }

    is dies { FFI::CheckLib::find_lib( lib => 'baz', alien => ['Alien::libbaz']) }, match qr/Alien Alien::libbaz doesn't provide a dynamic_libs method/;
  };

  subtest 'not installed' => sub {

    try_ok {
      FFI::CheckLib::find_lib( lib => 'baz', alien => ['Alien::libnotinstalled']);
    };

  };

};

subtest 'FFI_CHECKLIB_PATH' => sub {

  $FFI::CheckLib::system_path = [File::Spec->rel2abs('corpus/unix/path/path1')];
  $ENV{FFI_CHECKLIB_PATH} = File::Spec->rel2abs('corpus/unix/path/path2');
  note "system_path       = @{[ @$FFI::CheckLib::system_path ]}";
  note "FFI_CHECKLIB_PATH = $ENV{FFI_CHECKLIB_PATH}";

  my $lib = FFI::CheckLib::find_lib( lib => 'foo' );

  note "lib=$lib";

  is(basename($lib), "libfoo.so.2");

  $lib = FFI::CheckLib::find_lib( lib => 'foo', libpath => 'corpus/unix/path/path3' );

  note "lib=$lib";

  is(basename($lib), "libfoo.so.3");

};

done_testing;
