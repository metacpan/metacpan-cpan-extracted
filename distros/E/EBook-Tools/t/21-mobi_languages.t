use strict; use warnings; use utf8;
use Cwd qw(chdir getcwd);
use File::Basename qw(basename);
use File::Path;    # Exports 'mkpath' and 'rmtree'
use Test::More tests => 138;
BEGIN { use_ok('EBook::Tools::Unpack') };

my $cwd;
my $unpacker;
my $language;
my @list;

########## TESTS BEGIN ##########

ok( (basename(getcwd()) eq 't') || chdir('t/'), "Working in 't/" ) or die;
$cwd = getcwd();

while(<mobi/langtest-*.prc>)
{
    $unpacker = EBook::Tools::Unpack->new(
        'file' => $_,
        'nosave' => 1);
    $unpacker->unpack;
    ($language) = /.*?-([a-z-]+).prc/;
    is($unpacker->detected->{language},$language,
       "$_ has language $language");
}

########## CLEANUP ##########

