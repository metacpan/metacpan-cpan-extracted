use strict;
use warnings;

use Config;
use File::Path qw( rmtree );
use Test::More;
use ExtUtils::MakeMaker;

plan skip_all => 'This test requires a Makefile in the built distribution' if not -f 'Makefile';

plan tests => 7;

my $FILE = "test-$$-Makefile";
rmtree( [ "tlib-$$", "troot-$$" ], 0, 0 );
END {
    $FILE and -f $FILE and unlink $FILE;
    rmtree( [ "tlib-$$", "troot-$$" ], 0, 0 );
}

use File::ShareDir::Install;

install_share 't/share';
install_share module => 'My::Test' => 't/module';
delete_share 'module' => 'My::Test' => [ qw( again deeper ) ];
delete_share 'dist' => 'honk';

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

ok( $content =~ /RM_RF.+module.My-Test.again/, "Remove a file" );
ok( $content =~ /RM_RF.+module.My-Test.deeper/, "Remove a dir" );
ok( $content =~ /RM_RF.+dist...DISTNAME..honk/, "Remove from per-dist" )
    or die $content;


#####
mysystem( $Config{make}, '-f', $FILE );
my $TOP = "tlib-$$/lib/auto/share";
ok( -f "$TOP/module/My-Test/bonk", "Installed this file" );
ok( !-f "$TOP/module/My-Test/again", "Removed this file" );
ok( !-d "$TOP/dist/File-ShareDir-Install/deeper", "Removed a directory" );

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

