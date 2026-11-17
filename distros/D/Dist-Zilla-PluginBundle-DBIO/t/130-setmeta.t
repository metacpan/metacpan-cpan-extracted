use strict;
use warnings;

use Test::More;
use File::Temp ();
use Dist::Zilla::Tester;

# Pins what DBIO::SetMeta does to the Dist::Zilla object: author, copyright
# holder and license are what the bundle hands the plugin, whatever dist.ini
# says at the top level.

my $class = 'Dist::Zilla::Plugin::DBIO::SetMeta';

my $tzil = Dist::Zilla::Tester->from_config(
  { dist_root => '/tmp/dbio-dzil-corpus-does-not-exist' },
  { tempdir_root => File::Temp::tempdir(CLEANUP => 1), add_files => {
      'source/dist.ini' => join("\n",
        'name = DBIO-Test',
        'author = Someone Else <else@example.com>',
        'license = Artistic_2_0',
        'copyright_holder = Someone Else',
        'copyright_year = 2026',
        'version = 0.001',
        '',
        '[DBIO::SetMeta]',
        'author = DBIO Authors',
        'holder = DBIO Holder',
        '',
      ),
      'source/lib/DBIO/Test.pm' =>
        "package DBIO::Test;\n# ABSTRACT: test\nour \$VERSION = '0.001';\n1;\n",
    } },
);

my ($plugin) = grep { ref $_ eq $class } @{ $tzil->plugins };
ok $plugin, 'SetMeta present';

$plugin->before_build;

is_deeply $tzil->authors, ['DBIO Authors'], 'author is the one the plugin was given';
is $tzil->copyright_holder, 'DBIO Holder', 'copyright holder is the one the plugin was given';
isa_ok $tzil->license, 'Software::License::Perl_5', 'license';
is $tzil->license->holder, 'DBIO Holder', 'the license carries the new holder';

done_testing;
