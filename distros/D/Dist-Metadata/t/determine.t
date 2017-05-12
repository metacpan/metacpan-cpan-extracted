use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Dist::Metadata';
my $smod = "${mod}::Struct";
eval "require $_" || die $@
  for $mod, $smod;

$Dist::Metadata::VERSION ||= 0; # avoid undef warnings

{
  foreach my $test (
    [
      '/tmp/No-Existy-1.01',
      [],
      ['No-Existy', '1.01'],
      undef # same
    ],
    [
      # main module: No::Existy::3 (like perl5i::2)
      'No-Existy-3-v2.1.3',
      [],
      ['No-Existy-3', 'v2.1.3'],
      undef # same
    ],
    [
      # constructor args override
      'No-Existy-3-v2.1.3',
      [
        name => 'Who-Cares'
      ],
      ['No-Existy-3', 'v2.1.3'],
      ['Who-Cares',   'v2.1.3'],
    ],
    [
      # constructor args override
      'No-Existy-3-v2.1.3',
      [
        name => 'Who-Cares',
        version => 5,
      ],
      ['No-Existy-3', 'v2.1.3'],
      ['Who-Cares',   '5'],
    ],
  ){
    my ($base, $args, $parsed, $att) = @$test;
    $att ||= $parsed;
    # test dir name and tar file name
    foreach my $path ( $base, "$base.tar.gz", "$base.tgz" ){
      my $dm = new_ok($smod, [files => {}, @$args]);

      my @nv = $dm->parse_name_and_version($path);
      is_deeply(\@nv, $parsed, 'parsed name and version');

      $dm->set_name_and_version(@nv);
      is_deeply([$dm->name, $dm->version], $att, "set dist name and version");
    }
  }
}

{
  my $struct = {
    files => {
      'README' => 'we need a file to establish the root dir',
      'lib/Bunnies.pm' => <<'BUNNIES',
package Bunnies;
our $VERSION = 2.3;

package # comment
  HiddenBunnies;
our $VERSION = 2.4;

package TooManyBunnies;
our $VERSION = 2.5;
BUNNIES
      'lib/Rabbit/Hole.pm' => <<'HOLE',
package Rabbit::Hole;
our $VERSION = '1.1';

package Rabbit::Hole::Cover;
our $VERSION = '1.1';
HOLE
      # Test something that doesn't match the "simile" regexp in DM:determine_packages.
      # Module::Metadata 1.000009 will find this but for obvious reasons PAUSE would not index it.
      # If MM stops finding this we'll have to determine if there are
      # any other possible file names that wouldn't match the regexp.
      'lib/.pm' => <<'GOOFY',
package Goofy;
our $VERSION = '0.1';
GOOFY
    },
  };

  is_deeply
    new_ok($mod, [struct => $struct, include_inner_packages => 1])->determine_packages,
    {
      Bunnies        => { file => 'lib/Bunnies.pm', version => '2.3', },
      TooManyBunnies => { file => 'lib/Bunnies.pm', version => '2.5', },
      Goofy          => { file => 'lib/.pm',        version => '0.1', },
      'Rabbit::Hole' => { file => 'lib/Rabbit/Hole.pm', version => '1.1' },
      'Rabbit::Hole::Cover' => { file => 'lib/Rabbit/Hole.pm', version => '1.1' },
    },
    'determine all (not hidden) packages';

  is_deeply
    new_ok($mod, [struct => $struct])->determine_packages,
    {
      Bunnies        => { file => 'lib/Bunnies.pm', version => '2.3', },
      'Rabbit::Hole' => { file => 'lib/Rabbit/Hole.pm', version => '1.1' },
    },
    'determine only "simile" packages';

  {
    my $dm = new_ok($mod, [struct => $struct]);
    my $cpan_meta = $dm->default_metadata;
    push @{ $cpan_meta->{no_index}{namespace} ||= [] }, 'Rabbit'; # this is only about bunnies

    is_deeply
      $dm->determine_packages($dm->meta_from_struct($cpan_meta)),
      {
        Bunnies        => { file => 'lib/Bunnies.pm', version => '2.3', },
      },
      'determine only loadable modules, minus no_index/namespace';
  }

}

done_testing;
