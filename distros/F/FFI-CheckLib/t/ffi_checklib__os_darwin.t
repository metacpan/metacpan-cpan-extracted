use lib 't/lib';
use Test2::V0 -no_srand => 1;
use Test2::Plugin::FauxOS 'darwin';
use Test2::Plugin::FauxDynaLoader;
use Test2::Tools::NoteStderr qw( note_stderr );
use FFI::CheckLib;

$FFI::CheckLib::system_path =
$FFI::CheckLib::system_path = [ 
  'corpus/darwin/usr/lib',
  'corpus/darwin/lib',
];

subtest 'find_lib (good)' => sub {
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
  my @path = find_lib( lib => [ 'foo', 'bar' ] );

  ok -r $path[0], "path[0] = $path[0] is readable";
  ok -r $path[1], "path[1] = $path[1] is readable";

  subtest foo => sub {
    my($foo) = grep { $_->name eq 'foo' } map { TestDLL->new($_) } @path;
    is $foo->name, 'foo', 'dll.name = foo';
    is $foo->version, '1.2.3', 'dll.version = 1.2.3';
  };

  subtest bar => sub {
    my($bar) = grep { $_->name eq 'bar' } map { TestDLL->new($_) } @path;
    is $bar->name, 'bar', 'dll.name = bar';
    is $bar->version, '1.2.3', 'dll.version = 1.2.3';
  };
  
};

subtest 'find_lib libpath' => sub {
  my($path) = find_lib( lib => 'foo', libpath => 'corpus/darwin/custom' );
  ok -r $path, "path = $path is readable";
  my $dll = TestDLL->new($path);  
  is $dll->name,    'foo',    'dll.name = foo';
  is $dll->version, '1.2.3a', 'dll.version = 1.2.3a';
};

subtest 'find_lib libpath (list)' => sub {
  my($path) = find_lib( lib => 'foo', libpath => ['corpus/darwin/custom']);
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
  
  subtest 'found' => sub {
    eval { assert_lib( lib => 'foo' ) };
    is $@, '', 'no exception';
  };
  
  subtest 'not found' => sub {
    eval { assert_lib( lib => 'foobar') };
    isnt $@, '', 'exception'; 
  };
};

subtest 'check_lib' => sub {
  
  is check_lib( lib => 'foo' ), 1, 'found';
  is check_lib( lib => 'foobar'), 0, 'not found';
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

done_testing;
