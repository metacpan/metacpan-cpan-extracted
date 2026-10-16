use 5.022;
use Test2::V0 -no_srand => 1;
use File::ShareDir::Dist qw( dist_share );
use Dist::Zilla::MintingProfile::Author::Plicease;

# prove -l (Test::Harness 3.50+) puts an absolute lib in @INC, which defeats
# File::ShareDir::Dist's relative lib -> share fallback, so point it at the
# share directory when running from a checkout.
$ENV{PERL_FILE_SHAREDIR_DIST} = "Dist-Zilla-PluginBundle-Author-Plicease=share"
  if !defined dist_share("Dist-Zilla-PluginBundle-Author-Plicease") && -d "share";

my $profile = Dist::Zilla::MintingProfile::Author::Plicease->new;

isa_ok $profile, 'Dist::Zilla::MintingProfile::Author::Plicease';
ok $profile->DOES('Dist::Zilla::Role::MintingProfile'), 'does MintingProfile';

subtest 'default profile' => sub {
  my $dir = $profile->profile_dir('default');
  isa_ok $dir, 'Path::Tiny';
  ok -d $dir, "is a directory: $dir";
  is $dir->basename, 'default', 'basename';
  ok -f $dir->child('profile.ini'), 'has profile.ini';
  like $dir->child('profile.ini')->slurp_utf8, qr/^\[Author::Plicease::Init2/m, 'uses Init2';
};

subtest 'no profile name' => sub {
  my $dir = $profile->profile_dir(undef);
  ok -d $dir, "is a directory: $dir";
  is $dir->basename, 'profiles', 'basename';
  ok -d $dir->child('default'), 'contains default profile';
};

subtest 'bogus profile' => sub {
  like dies { $profile->profile_dir('bogus') }, qr/Can't find profile bogus/, 'dies';
};

done_testing;
