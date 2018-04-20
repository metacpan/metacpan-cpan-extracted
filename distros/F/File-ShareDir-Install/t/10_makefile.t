use strict;
use warnings;

use Config;
use File::Path qw( rmtree );
use Test::More;
use ExtUtils::MakeMaker;

plan skip_all => 'This test requires a Makefile in the built distribution' if not -f 'Makefile';

plan tests => 22;

my $FILE = "test-$$-Makefile";
rmtree( [ "tlib-$$", "troot-$$" ], 0, 0 );
END {
    $FILE and -f $FILE and unlink $FILE;
    rmtree( [ "tlib-$$", "troot-$$" ], 0, 0 );
}

use File::ShareDir::Install;

install_share 't/share';
install_share module => 'My::Test' => 't/module';


delete $ENV{PERL_MM_OPT};   # local::lib + PREFIX below will FAIL
# XXX maybe we should just remove INSTALL_BASE=[^ ]+ from PERL_MM_OPT?

WriteMakefile(
    NAME              => 'File::ShareDir::Install',
    VERSION_FROM      => 'lib/File/ShareDir/Install.pm',
    INST_LIB          => "tlib-$$/lib",
    PREFIX            => "troot-$$",
    MAKEFILE          => $FILE,
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (AUTHOR         => 'Philip Gwyn <fil@localdomain>') : ()),
);

sub slurp
{
    local @ARGV = @_;
    local $/;
    local $.;
    <>;
};


#####
ok( -f $FILE, "Created $FILE" );
my $content = slurp $FILE;
ok( $content =~ m(t.share.honk.+share.dist...DISTNAME..honk), "Shared by dist - regular file" );
ok( $content =~ m(t.share.hello world.+share.dist...DISTNAME..hello world), "Shared by dist - file with spaces" );
ok( $content =~ m(t.share.#hello.+share.dist...DISTNAME..#hello), "Shared by dist - file with special char" );
ok( $content =~ m(t.module.bonk.+share.module.My-Test.bonk), "Shared by module" );
ok( $content =~ m(t.module.again.+share.module.My-Test.again), "Shared by module again" );
ok( $content =~ m(t.module.deeper.bonk.+share.module.My-Test.deeper.bonk), "Shared by module in subdirectory" );

ok( $content !~ m(t.share.\.something), "Don't share dot files" );

#####
mysystem( $Config{make}, '-f', $FILE );
my $TOP = "tlib-$$/lib/auto/share";
ok( -f "$TOP/dist/File-ShareDir-Install/honk", "Copied to blib for dist - regular file" );
ok( -f "$TOP/dist/File-ShareDir-Install/hello world", "Copied to blib for dist - file with spaces" );
ok( -f "$TOP/dist/File-ShareDir-Install/#hello", "Copied to blib for dist - file with special char" );
ok( -f "$TOP/module/My-Test/bonk", "Copied to blib for module" );
ok( -f "$TOP/module/My-Test/again", "Copied to blib for module again" );
ok( -f "$TOP/module/My-Test/deeper/bonk", "Copied to blib for module, in subdir" );

my $c = slurp "$TOP/module/My-Test/bonk";
is( $c, "bonk\n", "Same names" );
$c = slurp "$TOP/module/My-Test/deeper/bonk";
is( $c, "deeper\n", " ... not mixed up" );

#####
mysystem( $Config{make}, '-f', $FILE, 'install' );
unless( $content =~ m(INSTALLSITELIB = (.+)) ) {
    SKIP: {
        skip "Can't find INSTALLSITELIB in test-Makefile", 4;
    }
}
else {
    $TOP = "$1/auto/share";
    $TOP =~ s/\$\(SITEPREFIX\)/troot-$$/;
    ok( -f "$TOP/dist/File-ShareDir-Install/honk", "Copied to blib for dist - regular file" );
    ok( -f "$TOP/dist/File-ShareDir-Install/hello world", "Copied to blib for dist - file with spaces" );
    ok( -f "$TOP/dist/File-ShareDir-Install/#hello", "Copied to blib for dist - file with special char" );
    ok( -f "$TOP/module/My-Test/bonk", "Copied to blib for module" );
    ok( -f "$TOP/module/My-Test/again", "Copied to blib for module again" );
    ok( -f "$TOP/module/My-Test/deeper/bonk", "Copied to blib for module, in subdir" );
}

#####################################
sub mysystem
{
    my $cmd = join ' ', @_;
    my $ret = qx($cmd 2>&1);
    return unless $?;
    die "Error running $cmd: ?=$? ret=$ret";
}

###########################################################################
package MY;

use File::ShareDir::Install qw(postamble);

