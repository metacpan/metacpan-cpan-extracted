#/usr/bin/env perl
use Cwd;
use File::Spec;
use Test::Most;
use Test::Output;
use File::Collector;
use lib 't/TestMods';
diag( "Running my tests" );

my $t0;
BEGIN  {
use Benchmark ':hireswallclock';
$t0 = Benchmark->new;
};



my $tests = 19; # keep on line 17 for ,i (increment and ,ii (decrement)
plan tests => $tests;

# 1 - 8
{
  my $da;

 throws_ok { $da = File::Collector->new('t/test_data/many_files', ['Test::Classifier'], {recurse => 1}, {recurse => 0}); } qr/Only one/,
   'does not allow two hashes to be passed in constructor';

 throws_ok { $da = File::Collector->new('t/test_data/many_files', ['Test::Classifier'], []); } qr/Only one class array/,
   'does not allow two array refs to be passed in constructor';

 throws_ok { $da = File::Collector->new('t/test_data/many_files', \$da); } qr/Unrecognized argument/,
   'dies with unrecognized reference type passed to constructor';

 lives_ok { $da = File::Collector->new('t/test_data/many_files', 't/test_data/single_file/a_file.txt', ['Test::Classifier']); }
   'creates Test Classifier object';

 stdout_like { $da->some_files->do->print_blah_names } qr/^many_files[\/\\]dir\d[\/\\]file\d/ms,
   'prints first file';

 stdout_like { $da->some_files->do->print_short_name } qr/^many_files[\/\\]dir\d[\/\\]file\d\n[^\n]/ms,
   'prints first file with no double line break';

 stdout_like { while ($da->next_some_file) { $da->print_short_name; } } qr/^many_files[\/\\]dir\d[\/\\]file\d$/ms,
   'next_ method works';

 my $file = $da->get_file(File::Spec->catdir(cwd(), '/t/test_data/many_files/file1'));
 is ref ($file), 'HASH',
   'gets hash of file data';

 stdout_like { $da->list_files_long; } qr/file\d\n[\/A-Z][\w:]/,
   'prints out long file paths';

  stdout_like {
    while ($da->next_some_file) {
      $da->print_short_name;
    }
  } qr/file\d\nmany_files[\/\\]file\d/, 'prints out short file names';

  my $blah = $da->next_some_file;
  is ($da->isa_some_file, 1,
    'isa_ method returns correct value');

  throws_ok { $da->get_obj_prop('test') } qr/Missing arguments/,
    'throws error when missing arguments to get_obj_prop';

  throws_ok { $da->has_obj() } qr/Missing argument/,
    'throws error when missing arguments to has_obj';

  is (!$da->isa_other_file, 1,
    'isa_ method returns correct value');

  throws_ok { $da->blah_file } qr/No such/,
    'error when bad autoload method called';

  lives_ok { $da->get_some_files }
    'can get files';

  throws_ok { $da->snigget } qr/No such/,
    'error when bad autoload method called';

  throws_ok { $da->get_file } qr/No file argument/,
    'error when no argument passed to get_file';

  stdout_like {
    my $it1 = $da->get_some_files;
    while ( $it1->next ) {
      # run C<Processor> methods and do other stuff to "good" files
      $it1->print_blah_names;
      my $it2 = $da->get_some_files;
      while ( $it2->next ) {
        $it2->print_blah_names;
      }
    }
  } qr/file\d\n\nmany_files/, 'prints double spaced file listing';

}

my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
print "\nThe code took:",timestr($td),"\n";
