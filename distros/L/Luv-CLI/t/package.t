use v5.38;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Archive::Zip;

use Luv::CLI::Manifest;
use Luv::CLI::Package;

my $dir = tempdir( CLEANUP => 1 );
chdir $dir or die $!;

my $manifest = Luv::CLI::Manifest->new(
    path         => 'luv.json',
    project_name => 'zipgame'
);
make_path(
    $manifest->source_dir, $manifest->library_dir,
    $manifest->assets_dir, $manifest->build_dir
);

open my $fh, '>', 'main.lua' or die $!;
print {$fh} "function love.load() end\n";
close $fh;

open my $afh, '>', $manifest->assets_dir . '/sprite.png' or die $!;
print {$afh} 'fakepngdata';
close $afh;

subtest 'build produces a zip' => sub {
    my $pkg    = Luv::CLI::Package->new( manifest => $manifest );
    my $output = $pkg->build;

    ok -e $output, 'output file created';

    my $zip = Archive::Zip->new;
    $zip->read($output);
    my @names = $zip->memberNames;

    ok( ( grep { $_ eq 'main.lua' } @names ),
        'main.lua present at zip root' );
    ok( ( grep { $_ eq 'assets/sprite.png' } @names ),
        'assets file present under assets/'
    );
};

done_testing;
