use Test2::V0 -no_srand => 1;
use Test::DZil;
use Path::Tiny qw( path );
use Dist::Zilla::MintingProfile::FFI;
use Test::File::ShareDir::Module { 'Dist::Zilla::MintingProfile::FFI' => 'profiles' };

subtest 'basic' => sub {

  my $tzil = Minter->_new_from_profile(
    [ FFI => 'default' ],
    { name => 'Foo-FFI' },
    { global_config_root => 'corpus/dist_zilla_mintingprofile_ffi' },
  );

  $tzil->chrome->set_response_for("Library name (for libfoo.so or foo.dll enter 'foo')", 'frooble');
  $tzil->chrome->set_response_for('Fallback Alien name', 'Alien::libfrooble');

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
    dist.ini
    lib/Foo/FFI.pm
    lib/Foo/FFI/Lib.pm
    t/foo_ffi.t
  )], 'minted the correct files';

};

done_testing;


