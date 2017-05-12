#! /usr/bin/perl
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More 0.88 tests => 4; # done_testing

use Test::DZil qw(Builder simple_ini);
use Parse::CPAN::Meta;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(qw(GatherDir RecommendedPrereqs),
                                      [ MetaYAML => { version => 2 }]),
    },
  },
);

$tzil->build;

my $meta = Parse::CPAN::Meta->load_file($tzil->tempdir->file('build/META.yml'));

is_deeply(
  $meta->{prereqs}{runtime}{recommends},
  { 'Foo::Bar' => '1.00',
    'Foo::Baz' => 0 },
  'runtime recommends'
);

is($meta->{prereqs}{runtime}{suggests}, undef, 'runtime suggests');

is($meta->{prereqs}{test}{recommends}, undef, 'test recommends');

is_deeply(
  $meta->{prereqs}{test}{suggests},
  { 'Test::Other' => 0 },
  'test suggests'
);

done_testing;
