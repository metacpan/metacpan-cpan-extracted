#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 16;

BEGIN {
    use_ok 'Debian::AptContents';
};

use FindBin qw($Bin);
use File::Touch qw(touch);

unlink("$Bin/Contents.cache");

sub instance
{
    Debian::AptContents->new({
        homedir => $Bin,
        verbose => 0,
        @_,
    });
}

$ENV{PATH} = "$Bin/bin:$ENV{PATH}";

eval { Debian::AptContents->new() };
ok( $@, 'AptContents->new with no homedir dies' );
like( $@, qr/No homedir given/, 'should say why it died' );

my $apt_contents = instance();

isnt( $apt_contents, undef, 'should create' );

$apt_contents = instance();

is_deeply(
    $apt_contents->contents_files,
    [ sort grep { !/Contents.cache/} glob "t/contents/*Contents*" ],
    'contents in a dir'
);

ok( -f "$Bin/Contents.cache", 'Contents.cache created' );

is( $apt_contents->source, 'cache', 'cache was used' );

sleep(1);   # allow the clock to tick so the timestamp actually differs
touch( glob "$Bin/contents/*Contents*" );

$apt_contents = instance();

is( $apt_contents->source, 'parsed files', 'cache updated' );

is_deeply(
    [ $apt_contents->find_file_packages('Moose.pm')],
    [ 'libmoose-perl' ],
    'Moose found by find_file_packages'
);

is( $apt_contents->find_perl_module_package('Moose') . '',
    'libmoose-perl', 'Moose found by module name' );

is_deeply(
    $apt_contents->get_contents_files,
    [   "t/contents/test_debian_dists_sid_main_Contents",
        "t/contents/test_debian_dists_testing_main_Contents"
    ],
    'get_contents_files'
);

is_deeply(
    [ $apt_contents->find_file_packages('GD.pm') ],
    [ 'libgd-gd2-noxpm-perl', 'libgd-gd2-perl' ],
    "GD.pm is in libdg-gd2[-noxpm]-perl"
);

is( $apt_contents->find_perl_module_package('GD') . '',
    'libgd-gd2-noxpm-perl | libgd-gd2-perl',
    'Alternative dependency for module found in multiple packages'
);

is_deeply(
    [ $apt_contents->find_file_packages('Image/Magick.pm') ],
    [ 'perlmagick', 'graphicsmagick-libmagick-dev-compat' ],
    "Image/Magick.pm in perlmagick and graphicsmagick-libmagick-dev-compat, but different paths"
);

is( $apt_contents->find_perl_module_package('Image::Magick') . '',
    'graphicsmagick-libmagick-dev-compat | perlmagick',
    'Alternative dependency for Image::Magick module found in multiple packages'
);

ok( unlink "$Bin/Contents.cache", 'Contents.cache unlnked' );
