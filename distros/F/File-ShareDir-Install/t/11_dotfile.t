use strict;
use warnings;

use Config;
use File::Path qw( rmtree );
use Test::More;
use ExtUtils::MakeMaker;

plan skip_all => 'This test requires a Makefile in the built distribution' if not -f 'Makefile';

plan tests => 9;

my $FILE = "test-$$-Makefile";
rmtree( [ "tlib-$$", "troot-$$" ], 0, 0 );
END {
    $FILE and -f $FILE and unlink $FILE;
    rmtree( [ "tlib-$$", "troot-$$" ], 0, 0 );
}

use File::ShareDir::Install;

$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
install_share 't/share';
$File::ShareDir::Install::INCLUDE_DOTFILES = 0;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
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
ok( $content =~ m(t.share.\.something), "Shared a dotfile" );
ok( $content !~ m(t.share.\.dir), " ... but not a dotdir" );

ok( $content !~ m(t.module.dir), "Shared a dotdir " );
ok( $content !~ m(t.module.something), " ... but not a dotfile " );

#####
mysystem( $Config{make}, '-f', $FILE );
my $TOP = "tlib-$$/lib/auto/share";
ok( -f "$TOP/dist/File-ShareDir-Install/.something", "Copied a dotfile" );
ok( !-d "$TOP/dist/File-ShareDir-Install/.dir", " ... but not dotdir" );
ok( -d "$TOP/module/My-Test/.dir", "Copied a dotdir" );
ok( !-f "$TOP/module/My-Test/.something", " ... but not a dotfile" );


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

