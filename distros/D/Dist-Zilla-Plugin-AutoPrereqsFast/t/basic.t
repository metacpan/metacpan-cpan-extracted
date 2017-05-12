#!perl
use strict;
use warnings;

use Test::More tests => 3;


use Test::DZil;
use JSON::PP qw(decode_json);
use File::Slurper qw(read_text);

sub build_meta {
  my $tzil = shift;

  $tzil->build;

  return decode_json(read_text($tzil->tempdir->path('build/META.json')));
}

my $tzil = Builder->from_config(
  { dist_root => 'corpus' },
  { },
);

# check found prereqs
my $meta = build_meta($tzil);

my %wanted = (
  # DZPA::Main should not be extracted
  'DZPA::Base::Moose1'    => 0,
# 'DZPA::Base::Moose2'    => 0,
  'DZPA::Base::base1'     => 0,
  'DZPA::Base::base2'     => 0,
  'DZPA::Base::base3'     => 0,
  'DZPA::Base::parent1'   => 0,
  'DZPA::Base::parent2'   => 0,
  'DZPA::Base::parent3'   => 0,
  'DZPA::IgnoreAPI'       => 0,
  'DZPA::IndentedRequire' => 0,
  'DZPA::IndentedUse'     => '0.13',
  'DZPA::MinVerComment'   => '0.50',
  'DZPA::ModRequire'      => 0,
  'DZPA::NotInDist'       => 0,
  'DZPA::Role'            => 0,
  'DZPA::ScriptUse'       => 0,
  'base'                  => 0,
  'lib'                   => 0,
  'parent'                => 0,
  'perl'                  => 5.008,
  'strict'                => 0,
  'warnings'              => 0,
);

is_deeply(
  $meta->{prereqs}{runtime}{requires},
  \%wanted,
  'all requires found, but no more',
);

# Try again with configure_finder:
$tzil = Builder->from_config(
  { dist_root => 'corpus' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        qw(GatherDir ExecDir),
        [ AutoPrereqsFast => { skip             => '^DZPA::Skip',
                               configure_finder => ':IncModules' } ],
        [ MetaJSON => { version => 2 } ],
      ),
      'source/inc/DZPA.pm' => "use DZPA::NotInDist;\n use DZPA::Configure;\n",
    },
  },
);

# check found prereqs
$meta = build_meta($tzil);

is_deeply(
  $meta->{prereqs}{runtime}{requires},
  \%wanted,
  'configure_finder did not change requires',
) or diag explain $meta->{prereqs}{runtime}{requires};

my %want_configure = (
  'DZPA::Configure'       => 0,
  'DZPA::NotInDist'       => 0,
);

is_deeply(
  $meta->{prereqs}{configure}{requires},
  \%want_configure,
  'configure_requires is correct',
);

done_testing;
