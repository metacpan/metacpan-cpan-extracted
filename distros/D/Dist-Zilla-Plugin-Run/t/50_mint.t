use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;
use Path::Tiny;

use Test::File::ShareDir -share => {
  -module => { 'Dist::Zilla::MintingProfile::Default' => 'test_data/profiles' },
};

{
  my $tzil = Minter->_new_from_profile(
    [ Default => 'default' ],
    { name    => 'DZT-Minty' ,},
    { global_config_root =>
        eval 'require Dist::Zilla::Dist::Minter; Dist::Zilla::Dist::Minter->VERSION("5.038"); 1'
            ? 'test_data/global'
            # older DZ requires this to quack like a Path::Class
            : do { require Path::Class; Path::Class::dir('test_data/global')->absolute },
    },
  );

  $tzil->chrome->logger->set_debug(1);
  $tzil->mint_dist();

  my $dir = path($tzil->tempdir)->child(qw(mint empty_dir));

  ok -d $dir, 'created directory in mint dir';

  # extra protection for spaces - see perldoc -f glob
  my $children = $dir->child('*');
  is_deeply [glob(qq{"$children"})], [], 'dir is empty but exists';

  like path($tzil->tempdir)->child(qw(mint lib DZT Minty.pm))->slurp_utf8,
    qr/package DZT::Minty;/,
    'minted regular file';

  like path($tzil->tempdir)->child('mint/minted_at.txt')->slurp_utf8,
    qr/DZT-Minty minted at \d+/,
    'created file the hard way';

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

done_testing;
