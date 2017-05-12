#!/usr/bin/env perl
use strict; use warnings;
use FindBin qw( $Bin );
BEGIN {
    require "$Bin/device-oui-test-lib.pl";
    require "$Bin/fake-lwp.pl";
}
use constant {
    OUI     => 'Device::OUI',
    file    => "$Bin/minimal-oui.txt",
    url     => "file://$Bin/minimal-oui.txt",
    file2   => "$Bin/device-oui-test-lib.pl",
    url2    => "file://$Bin/device-oui-test-lib.pl",
    file3   => "$Bin/functions.t",
    url3    => "file://$Bin/functions.t",
    one     => "$Bin/test-one.txt",
    two     => "$Bin/test-two.txt",
    three   => "$Bin/test-three.txt",
    four    => "$Bin/test-four.txt",
    five    => "$Bin/test-five.txt",
};

plan tests => 39;

ok( OUI->file_url( url ), "set file_url" );
is( OUI->file_url, url, "file_url set correctly" );

rm( one );
ok( OUI->cache_file( one ), "set cache file one" );
is( OUI->cache_file, one, "cache file one set ok" );
is( OUI->mirror_file, 1, "mirror succeeded for one" );
files_match( file, one, "file matches one" );

rm( two );
is( OUI->mirror_file( url2, two ), 1, "mirror succeeded for two" );
files_match( file2, two, "file2 matches two" );
files_dont_match( file2, one, "file2 doesn't match one" );
files_dont_match( file2, file, "file2 doesn't match file" );

ok( OUI->cache_file( four ), "set cache_file" );
is( OUI->cache_file, four, "cache_file set ok" );
rm( four );
is( OUI->mirror_file( url3, three ), 1, "mirror succeeded for three" );
ok( ! -f four, "... didn't create cache_file" );
files_match( file3, three, "file3 matches three" );
files_dont_match( file3, one, "file3 doesn't match one" );
files_dont_match( file3, two, "file3 doesn't match two" );
is( OUI->mirror_file( url3, three), 0, "... no update for three" );
is( OUI->mirror_file( url3, three), 0, "... no update for three" );
is( OUI->mirror_file( url3, three), 0, "... no update for three" );
rm( five );
is( OUI->mirror_file( url3, five), 1, "mirror succeeded for five" );
is( OUI->mirror_file( url3, five), 0, "... no update for five" );

# # # # # # # # # # # # # # # # # # # # # # # #
rm( one, two, three, four, five );
# # # # # # # # # # # # # # # # # # # # # # # #
is( OUI->cache_file( undef ), undef, "cleared cache_file" );
is( OUI->cache_file, undef, "cache_file stayed undef" );
is( OUI->file_url( undef), undef, "cleared file_url" );
is( OUI->file_url, undef, "file_url stayed undef" );

is( OUI->mirror_file(), undef, "no defaults, no args, undef" );
is( OUI->mirror_file( undef, one ), undef, "... undef with just file" );
is( OUI->mirror_file( url, undef ), undef, "... undef with just url" );
ok( ! -f one, "... no files created with incorrect arguments" );

# test get_url
{
    my $src = slurp( file );
    my $dst = OUI->get_url( url );
    is( $src, $dst, "get_url returned the right page" );

    is( OUI->get_url(), undef, "get_url returns undef with no url" );
}

# test update_from_web
{
    OUI->cache_file( undef );
    OUI->cache_db( undef );

    my $oui = OUI->new( 'FF-FF-FF' );
    ok( $oui->update_from_web, "update_from_web confirms fake downloads" );
    is( $oui->organization, "Device::OUI Fake Test Entry", "... org ok" );

    for my $sample ( samples() ) {
        my $oui = OUI->new( $sample->{ 'oui' } );
        ok( $oui->update_from_web, "update_from_web succeeded" );
    }
}
