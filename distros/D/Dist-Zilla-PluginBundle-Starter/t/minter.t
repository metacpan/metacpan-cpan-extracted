use strict;
use warnings;
use Path::Tiny;
use Test::More;
use Test::DZil;

use Test::File::ShareDir::Module { 'Dist::Zilla::MintingProfile::Starter' => 'profiles' };

my $tzil = Minter->_new_from_profile(
  [ Starter => 'default' ],
  { name => 'DZT-Minty' },
  { global_config_root => 't/minter/global' },
);

$tzil->mint_dist;

my @expected_files = sort qw(
  dist.ini
  lib/DZT/Minty.pm
);

my $mint_dir = path($tzil->tempdir)->child('mint');
my @found_files;
my $iter = $mint_dir->iterator({ recurse => 1 });
while (my $path = $iter->()) {
  push @found_files, $path->relative($mint_dir)->stringify if -f $path;
}

is_deeply [sort @found_files], \@expected_files, 'minted the correct files';

my $pm = $tzil->slurp_file('mint/lib/DZT/Minty.pm');
my $distini = $tzil->slurp_file('mint/dist.ini');

like $pm, qr/^package DZT::Minty;$/m, 'right package declaration';
like $pm, qr/^use strict;$/m, 'module uses strict';
like $pm, qr/^use warnings;$/m, 'module uses warnings';
like $pm, qr/^our \$VERSION = '0\.001';$/m, 'module version is set';
like $pm, qr/^=head1 NAME\n\nDZT::Minty - /m, 'right name section in pod';

like $distini, qr/^name\s*=\s*DZT-Minty$/m, 'right dist name';
like $distini, qr/^version\s*=\s*0\.001$/m, 'dist version is set';
like $distini, qr/^\[\@Starter\]$/m, 'starter bundle included';
like $distini, qr/^revision\s*=\s*2$/m, 'revision set to 2';

done_testing;
