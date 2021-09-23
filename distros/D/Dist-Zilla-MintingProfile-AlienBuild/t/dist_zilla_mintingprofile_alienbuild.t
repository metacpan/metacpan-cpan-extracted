use Test2::V0 -no_srand => 1;
use Test::DZil;
use lib 't/lib';
use Helper;
use Path::Tiny qw( path );
use Test::File::ShareDir::Module { 'Dist::Zilla::MintingProfile::AlienBuild' => 'profiles' };

require Alien::Build::Wizard;
require Alien::Build::Wizard::Detect;

subtest 'basic' => sub {

  local $Alien::Build::Wizard::Chrome::ask{'Enter the full URL to the latest tarball (or zip, etc.) of the project you want to alienize.'} = [path('corpus/alien_build_wizard/auto-1.2.3.tar')->absolute->stringify];
  local $Alien::Build::Wizard::Chrome::use_default = 1;

  my $tzil = Minter->_new_from_profile(
    [ AlienBuild => 'default' ],
    { name => 'Alien-libfoo' },
    { global_config_root => 'corpus/dist_zilla_mintingprofile_alienbuild' },
  );

  $tzil->mint_dist;

  my $mint_dir = path($tzil->tempdir)->child('mint');
  my $iter = $mint_dir->iterator({ recurse => 1 });
  my @found_files;
  while (my $path = $iter->()) {
    if(-f $path)
    {
      push @found_files, $path->relative($mint_dir)->stringify if -f $path;
      note " << $found_files[-1] >>";
      note $path->slurp_utf8;
    }
  }

  is [sort @found_files], [qw(
    Changes
    alienfile
    dist.ini
    lib/Alien/libfoo.pm
    t/basic.t
  )], 'minted the correct files';

};

done_testing;
