use 5.022;
use Test2::V0 -no_srand => 1;
use File::ShareDir::Dist qw( dist_share );
use Dist::Zilla::Plugin::Author::Plicease;

# prove -l (Test::Harness 3.50+) puts an absolute lib in @INC, which defeats
# File::ShareDir::Dist's relative lib -> share fallback, so point it at the
# share directory when running from a checkout.
$ENV{PERL_FILE_SHAREDIR_DIST} = "Dist-Zilla-PluginBundle-Author-Plicease=share"
  if !defined dist_share("Dist-Zilla-PluginBundle-Author-Plicease") && -d "share";

subtest 'dist_dir' => sub {
  my $dir = Dist::Zilla::Plugin::Author::Plicease->dist_dir;
  isa_ok $dir, 'Path::Tiny';
  ok -d $dir, "is a directory: $dir";
  ok -f $dir->child('profiles/default/profile.ini'), 'has default profile';
  ok -f $dir->child('perltidyrc'), 'has perltidyrc';
};

subtest 'git' => sub {
  my $git = Dist::Zilla::Plugin::Author::Plicease->git;
  like $git, qr/^[01]$/, 'returns 0 or 1';

  my $expected = File::Which::which('git') && eval { require Dist::Zilla::Plugin::Git; 1 } ? 1 : 0;
  is $git, $expected, "git = $expected";

  {
    no warnings 'redefine';
    local *File::Which::which = sub { undef };
    is(Dist::Zilla::Plugin::Author::Plicease->git, 0, 'no git executable => 0');
  }
};

done_testing;
