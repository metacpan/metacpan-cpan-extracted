use strict;
use warnings;

use Test::More;

use Test::DZil;

plan skip_all => 'Dist::Zilla::Plugin::ModuleBuild not found'
    unless eval "use Dist::Zilla::Plugin::ModuleBuild; 1";

plan tests => 1;

for my $corpus ( 'corpus-module-build' ) {

    subtest "with '$corpus'" => sub {
        plan tests => 6;

        my $tzil = Builder->from_config( { dist_root => "t/$corpus" },);

        $tzil->build;

        my @shared = grep { $_->name =~ m#share/# } @{ $tzil->files };

        is @shared => 1, "there is only one file";

        is $shared[0]->name => 'share/shared-files.tar.gz', "and it's the tarball";

        my $content = Compress::Zlib::memGunzip($shared[0]->content);
        open my $fh, '<', \$content;

        my $tar = Archive::Tar->new;
        $tar->read($fh);

        ok $tar->contains_file($_), "$_ present" for qw/ foo bar /;

        my ($makefile) = grep { $_->name =~ /Build.PL/ } @{$tzil->files};

        ok $makefile, "Build.PL present";

        like
            $makefile->content,
            qr/"share_dir"\s*=>\s*\{\s*"dist"\s*=>\s*"share"\s*\}/,
            "Build.PL has the sharedir directive" 
        ;
    }
}
