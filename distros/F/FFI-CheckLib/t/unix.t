use strict;
use warnings;
use FindBin ();
use File::Spec;
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 15;
BEGIN { $ENV{FFI_CHECKLIB_TEST_OS} = 'linux' }
use FFI::CheckLib;

BEGIN {
  eval q{
    use Capture::Tiny qw( capture_stderr );
  };
  if($@)
  {
    eval q{
      sub capture_stderr (&) { $_[0]->() };
    };
  }
}

do {
  no warnings 'once';
  $FFI::CheckLib::system_path = [ 
    File::Spec->catdir($FindBin::Bin, qw( fs unix usr lib )),
    File::Spec->catdir($FindBin::Bin, qw( fs unix lib )),
  ];
  
  $FFI::CheckLib::dyna_loader = 'MyDynaLoader';
};

subtest 'find_lib (good)' => sub {
  plan tests => 4;

  my($path) = find_lib( lib => 'foo' );
  ok -r $path, "path = $path is readable";
  
  my $path2 = find_lib( lib => 'foo' );
  is $path, $path2, 'scalar context';
  
  my $dll = TestDLL->new($path);  
  is $dll->name,    'foo',   'dll.name = foo';
  is $dll->version, '1.2.3', 'dll.version = 1.2.3';
};

subtest 'find_lib (fail)' => sub {
  my @path = find_lib( lib => 'foobar' );
  
  ok @path == 0, 'libfoobar not found';
};

subtest 'find_lib list' => sub {
  plan tests => 4;

  my @path = find_lib( lib => [ 'foo', 'bar' ] );

  ok -r $path[0], "path[0] = $path[0] is readable";
  ok -r $path[1], "path[1] = $path[1] is readable";

  subtest foo => sub {
    plan tests => 2;
    my($foo) = grep { $_->name eq 'foo' } map { TestDLL->new($_) } @path;
    is $foo->name, 'foo', 'dll.name = foo';
    is $foo->version, '1.2.3', 'dll.version = 1.2.3';
  };

  subtest bar => sub {
    plan tests => 2;
    my($bar) = grep { $_->name eq 'bar' } map { TestDLL->new($_) } @path;
    is $bar->name, 'bar', 'dll.name = bar';
    is $bar->version, '1.2.3', 'dll.version = 1.2.3';
  };
  
};

subtest 'find_lib libpath' => sub {
  my($path) = find_lib( lib => 'foo', libpath => File::Spec->catdir($FindBin::Bin, qw( fs unix custom )));
  ok -r $path, "path = $path is readable";
  my $dll = TestDLL->new($path);  
  is $dll->name,    'foo',    'dll.name = foo';
  is $dll->version, '1.2.3a', 'dll.version = 1.2.3a';
};

subtest 'find_lib libpath (list)' => sub {
  my($path) = find_lib( lib => 'foo', libpath => [File::Spec->catdir($FindBin::Bin, qw( fs unix custom ))]);
  ok -r $path, "path = $path is readable";
  my $dll = TestDLL->new($path);  
  is $dll->name,    'foo',    'dll.name = foo';
  is $dll->version, '1.2.3a', 'dll.version = 1.2.3a';
};

subtest 'find_lib symbol' => sub {
  my($path) = find_lib( lib => 'foo', symbol => 'foo_init' );
  ok -r $path, "path = $path is readable";
  my $dll = TestDLL->new($path);  
  is $dll->name,    'foo',   'dll.name = foo';
  is $dll->version, '1.2.3', 'dll.version = 1.2.3';  
};

subtest 'find_lib symbol (bad)' => sub {
  my @path = find_lib( lib => 'foo', symbol => 'foo_initx' );
  ok @path == 0, 'no path found';
};

subtest 'find_lib symbol (list)' => sub {
  my($path) = find_lib( lib => 'foo', symbol => ['foo_init', 'foo_new', 'foo_delete'] );
  ok -r $path, "path = $path is readable";
  my $dll = TestDLL->new($path);  
  is $dll->name,    'foo',   'dll.name = foo';
  is $dll->version, '1.2.3', 'dll.version = 1.2.3';  
};

subtest 'find_lib symbol (list) (bad)' => sub {
  my @path = find_lib( lib => 'foo', symbol => ['foo_init', 'foo_new', 'foo_delete', 'bogus'] );
  ok @path == 0, 'no path found';
};

subtest 'assert_lib' => sub {
  plan tests => 2;
  
  subtest 'found' => sub {
    plan tests => 1;
    eval { assert_lib( lib => 'foo' ) };
    is $@, '', 'no exception';
  };
  
  subtest 'not found' => sub {
    plan tests => 1;
    eval { assert_lib( lib => 'foobar') };
    isnt $@, '', 'exception'; 
  };
};

subtest 'check_lib' => sub {
  plan tests => 2;
  
  is check_lib( lib => 'foo' ), 1, 'found';
  is check_lib( lib => 'foobar'), 0, 'not found';
};

subtest 'check_lib_or_exit' => sub {

  plan tests => 2;
  
  subtest 'found' => sub {
    plan tests => 1;
    eval { check_lib_or_exit( lib => 'foo' ) };
    is $@, '', 'no exit';
  };
  
  subtest 'not found' => sub {
    plan tests => 1;
    eval { capture_stderr { check_lib_or_exit( lib => 'foobar') } };
    like $@, qr{::exit::}, 'called exit'; 
  };

};

subtest 'find_lib_or_exit' => sub {

  plan tests => 2;
  
  subtest 'found' => sub {
    plan tests => 3;
    my($path) = eval { find_lib_or_exit( lib => 'foo' ) };
    is $@, '', 'no exit';
    ok $path, "path = $path";
    my $path2 = eval { find_lib_or_exit( lib => 'foo' ) };
    is $path, $path2, 'scalar context';
  };
  
  subtest 'not found' => sub {
    plan tests => 1;
    eval { capture_stderr { find_lib_or_exit( lib => 'foobar') } };
    like $@, qr{::exit::}, 'called exit'; 
  };

};

subtest 'verify bad' => sub {

  my @lib = find_lib(
    lib => 'foo',
    verify => sub { 0 },
  );
  
  ok @lib == 0, 'returned empty list';

  @lib = find_lib(
    lib => 'foo',
    verify => [ sub { 0 } ],
  );
  
  ok @lib == 0, 'returned empty list';

};

subtest 'verify' => sub {

  my($lib) = find_lib(
    lib => 'foo',
    verify => sub {
      my($name, $path) = @_;
      my $lib = TestDLL->new($path);
      $lib->version ne '1.2.3'
    },
  );
  
  ok -r $lib, "path = $lib is readable";
  my $dll = TestDLL->new($lib);
  is $dll->name, 'foo', 'dll.name = foo';
  is $dll->version, '2.3.4', 'dll.version = 2.3.4';

};

