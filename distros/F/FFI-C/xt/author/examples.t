use Test2::V0 -no_srand => 1;
use Test2::Require::Module 'Test::Script';
use Test::Script;
use Path::Tiny qw( path );
use File::Glob qw( bsd_glob );
use Capture::Tiny qw( capture_merged );

skip_all 'not tested with ciperl:static' if defined $ENV{CIPSTATIC} && $ENV{CIPSTATIC} eq 'true';

$ENV{PERL5LIB} = path('corpus/examples/lib')->absolute;

my @dirs = qw( examples examples/synopsis );

is(
  do {
    my $lib;
    my($out) = capture_merged {
      require FFI::Build;
      my $build = FFI::Build->new(
        'main',
        dir => 'corpus/examples/arch/auto/main',
        verbose => 2,
      );
      $build->source(map { bsd_glob "$_/*.c" } @dirs);
      $lib = eval { $build->build };
    };
    note $out if $out ne '';

    my $txt = path('corpus/examples/arch/auto/main/main.txt');
    $txt->parent->mkpath;
    $txt->spew("FFI::Build\@" . path($lib->path)->relative('corpus/examples/lib')->stringify);

    $lib;
  },
  object {
    call [ isa => 'FFI::Build::File::Library' ] => T();
  },
  'build c example files',
);

foreach my $example (map { bsd_glob "$_/*.pl" } @dirs)
{
  my $basename = path($example)->basename;
  subtest $basename => sub {
    skip_all 'test requires Perl 5.14 or better'
      unless $basename ne 'c.pl' || $] >= 5.014;
    my $out = '';
    my $err = '';
    script_compiles $example;
    script_runs $example, { stdout => \$out, stderr => \$err };
    note "[out]\n$out" if $out ne '';
    note "[err]\n$err" if $err ne '';
  };
}

done_testing;
