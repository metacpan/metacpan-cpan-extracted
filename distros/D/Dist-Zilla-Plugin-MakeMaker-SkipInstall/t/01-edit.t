#!perl

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Dist::Zilla::Tester;
use Dist::Zilla::Plugin::MakeMaker::SkipInstall;
use File::Spec;
use File::Temp qw( tempdir );
use File::Copy qw( copy );

my $dir = tempdir(CLEANUP => 1);
my $makefile = setup_project($dir);

my $plugin = Dist::Zilla::Plugin::MakeMaker::SkipInstall->new(
  plugin_name => 'MakeMaker::SkipInstall',
  zilla       => Dist::Zilla::Tester->from_config({dist_root => $dir}),
);
ok($plugin);
is(exception { $plugin->after_build({build_root => $dir}) }, undef);

my $content = Dist::Zilla::Plugin::MakeMaker::SkipInstall::_slurp($makefile);
like($content, qr/exit 0 if \$ENV\{AUTOMATED_TESTING\}/);
like($content, qr/sub MY::install \{ "install ::\\n" \}/);

done_testing();

sub setup_project {
  my $dir = shift;

  for my $f ('Makefile.PL', 'dist.ini') {
    my $dest = File::Spec->catfile($dir, $f);
    copy($f, $dest)
      or die "Could not copy file '$f' to '$dest': $!";
  }

  return File::Spec->catfile($dir, 'Makefile.PL');
}
