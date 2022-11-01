use Test2::V0 -no_srand => 1;
use Capture::Tiny qw( capture_merged );
use Path::Tiny qw( path );
use File::chdir;

plan skip_all => 'developer test set FFI_PLATYPUS_LANG_GO_TEST_EXAMPLES=1 to run' unless $ENV{FFI_PLATYPUS_LANG_GO_TEST_EXAMPLES} || $ENV{CIPSOMETHING};

my @lib;

if(-d 'blib')
{
  push @lib, '-Mblib';
}
else
{
  $ENV{PERL_FILE_SHAREDIR_DIST} = join '=', 'FFI-Platypus-Lang-Go', "$CWD/share";
  push @lib, '-I../lib';
}

foreach my $dir (qw( examples ))
{
  subtest 'Compile/Link Go' => sub {

    foreach my $src (path('examples')->children)
    {
      next unless $src->basename =~ /\.go$/;
      my $so = $src->parent->child(do {
        my $basename = $src->basename;
        $basename =~ s/\.go$/.so/;
        $basename;
      });

      my @cmd = ('go', 'build', -o => "$so", '-buildmode=c-shared', "$src");

      my($out, $ret) = capture_merged {
        system @cmd;
      };

      if(is $ret, 0, "@cmd")
      {
        note $out if $out ne '';
      }
      else
      {
        diag $out if $out ne '';
      }
    }
  };

  subtest 'Run Perl' => sub {
    local $CWD = 'examples';
    foreach my $src (path('.')->children)
    {
      next unless $src->basename =~ /\.pl$/;

      my @cmd = ($^X, @lib, "$src");
      my($out, $ret) = capture_merged {
        system @cmd;
      };

      if(is $ret, 0, "@cmd")
      {
        note $out if $out ne '';
      }
      else
      {
        diag $out if $out ne '';
      }
    }
  };
}

unlink for grep { $_->basename =~ /\.(h|so)$/ } path('examples')->children;

done_testing;
