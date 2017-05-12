use strict;
use Test::More;
use Test::DZil;
use JSON;

my $ini = simple_ini('GatherDir', 'ShareDir', 'MetaJSON', 'MakeMaker::IncShareDir');

my $tzil = Builder->from_config(
    { dist_root => "t/dist" },
    { add_files => { 'source/dist.ini' => $ini } },
);

$tzil->build;

my $makefile = $tzil->slurp_file("build/Makefile.PL");
like $makefile, qr/use lib 'inc'/;

ok $tzil->slurp_file("build/inc/File/ShareDir/Install.pm");
my $meta = JSON::decode_json( $tzil->slurp_file("build/META.json") );
ok !exists $meta->{prereqs}{configure}{requires}{'File::ShareDir::Install'};

done_testing;
