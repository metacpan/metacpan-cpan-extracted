use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL qw( dztest );

# ABSTRACT: Make sure dztest's create_plugin works

my $test = dztest;
$test->add_file( 'dist.ini', simple_ini( ['GatherDir'] ) );

my $plugin_a = $test->create_plugin('MetaConfig');
my $plugin_b = $test->create_plugin( 'MetaConfig', 'Lizzard' );
my $plugin_c = $test->create_plugin( 'MetaConfig', {} );
my $plugin_d = $test->create_plugin( 'MetaConfig', 'Lizzard', {} );

is( ref $plugin_a->metadata, 'HASH', 'Constructed metaconfig returned a hash ;)' );

done_testing;
