use lib 't/lib';
use Test2::V0 -no_srand => 1;
use Test2::Plugin::FauxOS 'MSWin32';
use FFI::CheckLib;

$FFI::CheckLib::system_path =
$FFI::CheckLib::system_path = [ 
  'corpus/windows/bin',
];

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

done_testing;
