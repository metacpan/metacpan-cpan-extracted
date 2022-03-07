# [TAU]: Adopted from @Starter::Git/t/minter.t
use strict;
use warnings;
use Git::Wrapper;
use Path::Tiny;
use Test::More;
use Test::DZil;

eval { Git::Wrapper->new(Path::Tiny->cwd)->version; 1 } or plan skip_all => 'git is not available for testing';

use Test::File::ShareDir::Module { 'Dist::Zilla::MintingProfile::Author::TABULO' => 'profiles' };

my $tzil = Minter->_new_from_profile(
  [ 'Author::TABULO' => 'default' ],
  { name => 'DZT-Minty' },
  { global_config_root => 't/minter/global' },
);

# prevent Git::Init from trying to make a commit
my $init_plugin = $tzil->plugin_named('Git::Init') // die 'Did not find Git::Init plugin';
$init_plugin->meta->get_attribute('commit')->set_value($init_plugin, 0);

$tzil->mint_dist;

my @expected_files = sort qw(
  .gitignore
  .perltidyrc
  Changes
  dist.ini
  lib/DZT/Minty.pm
  perlcritic.rc
  stopwords
  tidyall.ini
);

my $mint_dir = path($tzil->tempdir)->child('mint');
my @found_files;
my $iter = $mint_dir->iterator({ recurse => 1 });
while (my $path = $iter->()) {
  next if $path =~ m!\.git/!;
  push @found_files, $path->relative($mint_dir)->stringify if -f $path;
}

is_deeply [sort @found_files], \@expected_files, 'minted the correct files';

my $pm = $tzil->slurp_file('mint/lib/DZT/Minty.pm');
my $distini = $tzil->slurp_file('mint/dist.ini');
my $gitignore = $tzil->slurp_file('mint/.gitignore');

like $pm, qr/^package DZT::Minty;$/m, 'right package declaration';
like $pm, qr/^use strict;$/m, 'module uses strict';
like $pm, qr/^use warnings;$/m, 'module uses warnings';
like $pm, qr/^our \$VERSION = '0\.001(000)?';$/m, 'module version is set';
like $pm, qr/^=head1 NAME\n\nDZT::Minty - /m, 'right name section in pod';

like $distini, qr/^name\s*=\s*DZT-Minty$/m, 'right dist name';
# like $distini, qr/^version\s*=\s*0\.001$/m, 'dist version is set';    # [TAU]: We now take the version from the main module; not from 'dist.ini'
like $distini, qr/^\[\@Author::TABULO\]$/m, 'author bundle included';
# like $distini, qr/^revision\s*=\s*5$/m, 'revision set to 5';          # [TAU]: revisions seem to be too much to maintain for an author bundle

like $gitignore, qr/^\/DZT-Minty-\*$/m, 'builds ignored in git';

done_testing;

#COPYRIGHT
#CREDITS: # [TAU]: Adopted from @Starter::Git/t/minter.t
