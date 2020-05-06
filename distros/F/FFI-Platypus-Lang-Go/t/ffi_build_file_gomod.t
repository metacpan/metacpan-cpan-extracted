use Test2::V0 -no_srand => 1;
use FFI::Build::File::GoMod;
use Capture::Tiny qw( capture_merged );
use File::Glob qw( bsd_glob );

subtest 'basic' => sub {

  foreach my $t (bsd_glob('examples/Awesome-FFI/t/*.t'))
  {
    my @command = ($^X, '-Iexamples/Awesome-FFI/lib', $t);
    my($out, $ret) = capture_merged {
      print "+@command";
      system @command;
    };
    note $out;
    is $ret, 0;
  }

};

done_testing;
