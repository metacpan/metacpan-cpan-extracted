use lib 't/lib';
use Test2::V0 -no_srand => 1;
use Test2::Plugin::FauxOS 'MSWin32';
use FFI::CheckLib;
use Env qw( @PATH );

@$FFI::CheckLib::system_path = (
  'corpus/windows/bin',
);

subtest 'find_lib (good)' => sub {
  my($path) = find_lib( lib => 'dinosaur' );
  ok -r $path, "path = $path is readable";

  my $path2 = find_lib( lib => 'dinosaur' );
  is $path, $path2, 'scalar context';
};

subtest 'find_lib (fail)' => sub {
  my @path = find_lib( lib => 'foobar' );

  ok @path == 0, 'libfoobar not found';
};

subtest 'find_lib (good) with lib and version' => sub {
  my($path) = find_lib( lib => 'apatosaurus' );
  ok -r $path, "path = $path is readable";

  my $path2 = find_lib( lib => 'apatosaurus' );
  is $path, $path2, 'scalar context';
};

subtest 'in sync with $ENV{PATH}' => sub {

  local $ENV{PATH} = $ENV{PATH};
  @PATH = qw( foo bar baz );

  is(
    $FFI::CheckLib::system_path,
    [qw( foo bar baz )],
  );

};

subtest 'lib with name like libname-1-2-3.dll' => sub {
  my($path) = find_lib( lib => 'maiasaura' );
  ok -r $path, "path = $path is readable";

  my $path2 = find_lib( lib => 'maiasaura' );
  is $path, $path2, 'scalar context';

};

subtest 'lib with name like name-1-2-3.dll' => sub {
  my($path) = find_lib( lib => 'dromornis_planei' );
  ok -r $path, "path = $path is readable";

  my $path2 = find_lib( lib => 'dromornis_planei' );
  is $path, $path2, 'scalar context';

};

subtest 'lib with name like libname-1-2___.dll' => sub {
  my($path) = find_lib( lib => 'thylacaleo_carnifex' );
  ok -r $path, "path = $path is readable";

  my $path2 = find_lib( lib => 'thylacaleo_carnifex' );
  is $path, $path2, 'scalar context';

};

subtest 'lib with name like libname_1_2.dll' => sub {
  my($path) = find_lib( lib => 'brevipalatus_mcculloughi' );
  ok -r $path, "path = $path is readable";

  my $path2 = find_lib( lib => 'brevipalatus_mcculloughi' );
  is $path, $path2, 'scalar context';

};

subtest 'lib with name like libname_ext.dll' => sub {
  my($path) = find_lib( lib => 'apatosaurus_ajax' );
  ok -r $path, "path = $path is readable";

  my $path2 = find_lib( lib => 'apatosaurus_ajax' );
  is $path, $path2, 'scalar context';

};

sub p
{
  my($path) = @_;
  $path =~ s{/}{\\}g if $^O eq 'MSWin32';
  $path;
}

subtest '_cmp' => sub {

  my $process = sub {
    [
      sort { FFI::CheckLib::_cmp($a,$b) }
      map  { FFI::CheckLib::_matches($_, 'C:/bin') }
      @_
    ];
  };

  is(
    $process->(qw( foo-1.dll bar-2.dll baz-0.dll )),
    [
      [ 'bar', p('C:/bin/bar-2.dll'), 2 ],
      [ 'baz', p('C:/bin/baz-0.dll'), 0 ],
      [ 'foo', p('C:/bin/foo-1.dll'), 1 ],
    ],
    'name first 1',
  );

  is(
    $process->(qw( baz-0.dll foo-1.dll bar-2.dll )),
    [
      [ 'bar', p('C:/bin/bar-2.dll'), 2 ],
      [ 'baz', p('C:/bin/baz-0.dll'), 0 ],
      [ 'foo', p('C:/bin/foo-1.dll'), 1 ],
    ],
    'name first 1',
  );

  is(
    $process->(qw( bar-2.dll foo-1.dll baz-0.dll )),
    [
      [ 'bar', p('C:/bin/bar-2.dll'), 2 ],
      [ 'baz', p('C:/bin/baz-0.dll'), 0 ],
      [ 'foo', p('C:/bin/foo-1.dll'), 1 ],
    ],
    'name first 1',
  );

  is(
    $process->(qw( foo-2.dll foo-0.dll foo-1.dll )),
    [
      [ 'foo', p('C:/bin/foo-2.dll'), 2, ],
      [ 'foo', p('C:/bin/foo-1.dll'), 1, ],
      [ 'foo', p('C:/bin/foo-0.dll'), 0, ],
    ],
    'newer version first',
  );

};

subtest 'case insensitive' => sub {

  local $FFI::CheckLib::system_path = [ 'corpus/windows/bincase' ];

  subtest 'no prefix' => sub {
    my($path) = find_lib( lib => 'foo' );
    ok $path;
    note "path = @{[ defined $path ? $path : 'undef' ]}";
  };

  subtest 'with lib prefix' => sub {
    my($path) = find_lib( lib => 'bar' );
    ok $path;
    note "path = @{[ defined $path ? $path : 'undef' ]}";
  };

};

done_testing;
