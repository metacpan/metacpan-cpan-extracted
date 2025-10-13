use Test2::V0 -no_srand => 1;
use Test::Script qw( script_compiles script_runs );
use File::chdir;
use Path::Tiny qw( path );
use File::Glob qw( bsd_glob );
use Capture::Tiny qw( capture_merged );

sub cleanup {
  path('examples/zig-cache')->remove_tree;
  foreach my $path (path('examples')->children) {
    unlink "$path" if $path->basename =~ /\.dll$/i;
    unlink "$path" if $path->basename =~ /^lib/;
  }
}

cleanup();

$ENV{PERL_FILE_SHAREDIR_DIST}="FFI-Platypus-Lang-Zig=$CWD/share";
note "PERL_FILE_SHAREDIR_DIST=$ENV{PERL_FILE_SHAREDIR_DIST}";

foreach my $dir (qw( examples )) {

  subtest $dir => sub {

    local $CWD = $dir;

    subtest 'compile zig' => sub {

      my @zig_source_files = bsd_glob '*.zig';

      plan tests => 0+@zig_source_files;

      foreach my $zig_source_file (@zig_source_files) {
        my @cmd = ('zig', 'build-lib', '-dynamic', $zig_source_file);
        my($out, $ret) = capture_merged {
          print "+@cmd\n";
          system @cmd;
          $?;
        };

        ok($ret == 0, "@cmd")
          ? note $out
          : diag $out;
      }


    };

    subtest 'Perl FFI scripts' => sub {

      my @scripts = bsd_glob '*.pl';
      plan tests => 0+@scripts;

      foreach my $script (@scripts) {
        subtest $script => sub {
          script_compiles $script;

          my($out,$err) = ('','');
          my $ok = script_runs $script, { stdout => \$out, stderr => \$err };

          if($ok) {
            note "[out]\n$out" if $out;
            note "[err]\n$out" if $err;
          } else {
            diag "[out]\n$out" if $out;
            diag "[err]\n$out" if $err;
          }
        };
      }

    };

  };

}

cleanup();

done_testing;
