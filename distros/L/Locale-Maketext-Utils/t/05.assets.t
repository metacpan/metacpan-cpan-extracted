use Test::More tests => 19;

BEGIN {
    chdir 't';
    unshift @INC, qw(lib ../lib);
    use_ok('Locale::Maketext::Utils');
    use_ok('MyTestLocale');
}

my $lh = MyTestLocale->get_handle('fr');

my %arb_asset = (
    'pt'    => 'i am pt',
    'pt_br' => 'i am pt_br',
    'en'    => 'default',
    'fr'    => 'object',
    'es'    => 'es here',
);
my $coderef = sub { return $arb_asset{ $_[0] } if exists $arb_asset{ $_[0] }; return; };

is( $lh->get_asset($coderef), 'object', 'get_asset() object tag found' );
delete $arb_asset{'fr'};
is( $lh->get_asset($coderef), 'default', 'get_asset() object tag not found, default' );
delete $arb_asset{'en'};
is( $lh->get_asset($coderef), undef(), 'get_asset() object tag not found, no default' );
$arb_asset{'en'} = 'default';

is( $lh->get_asset( $coderef, 'es' ), 'es here', 'get_asset() arg tagfound' );
delete $arb_asset{'es'};
is( $lh->get_asset($coderef), 'default', 'get_asset() object tag not found, default' );
delete $arb_asset{'en'};
is( $lh->get_asset( $coderef, 'es' ), undef(), 'get_asset() arg tag not found, no default' );
$arb_asset{'en'} = 'default';

is( $lh->get_asset( $coderef, 'pt_br' ), 'i am pt_br', 'get_asset() arg tag with super found' );
is( $lh->get_asset( $coderef, 'pt' ),    'i am pt',    'get_asset() arg tag without super found' );
delete $arb_asset{'pt_br'};
is( $lh->get_asset( $coderef, 'pt_br' ), 'i am pt', 'get_asset() arg tag falls back to super' );

my $ih = MyTestLocale->get_handle('i_tag');
is( $ih->get_asset( $coderef, 'i_tag' ), 'default', 'get_asset() i_tag no asset' );
$arb_asset{'i_tag'} = 'i robot';
is( $ih->get_asset( $coderef, 'i_tag' ), 'i robot', 'get_asset() i_tag no asset' );

skip: {
    eval 'use File::Temp ();';
    skip "Could not load File::Temp", 6 if $@;

    eval 'use File::Spec ();';
    skip "Could not load File::Spec", 6 if $@;

    my $dir = File::Temp->newdir();
    my $fr_dir = File::Spec->catdir( $dir, 'fr.d' );
    mkdir $fr_dir || die "Could not create tmp dir “$fr_dir”: $!";

    $fr_file = File::Spec->catfile( $dir, 'fr.f' );
    open my $fh, '>', $fr_file || die "Could not create tmp file “$fr_file”: $!";
    print {$fh} 'fr';
    close $fh;

    my $file_name = File::Spec->catfile( $dir, '%s.f' );
    is( $lh->get_asset_file($file_name), $fr_file, 'get_asset_file()' );
    unlink($fr_file) || die "Could not remove “$fr_file”: $!";
    is( $lh->get_asset_file($file_name), $fr_file, 'get_asset_file() cached' );
    $lh->delete_cache('get_asset_file');
    is( $lh->get_asset_file($file_name), undef(), 'get_asset_file() cache deleted' );

    my $dir_name = File::Spec->catfile( $dir, '%s.d' );
    is( $lh->get_asset_dir($dir_name), $fr_dir, 'get_asset_dir()' );
    rmdir($fr_dir) || die "Could not remove “$fr_dir”: $!";
    is( $lh->get_asset_dir($dir_name), $fr_dir, 'get_asset_dir() cached' );
    $lh->delete_cache('get_asset_dir');
    is( $lh->get_asset_dir($dir_name), undef(), 'get_asset_dir() cache deleted' );
}
