use strict;
use warnings;

use Test::More;

# FILENAME: basic.t
# CREATED: 09/11/14 15:02:38 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Basic do-someting test.

use Test::DZil qw( simple_ini Builder);

my $zilla = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        [ 'Prereqs', 'TestRequires',    { 'Foo' => '6.0' } ],    #
        [ 'Prereqs', 'RuntimeRequires', { 'Foo' => '5.0' } ],    #
        ['Prereqs::SyncVersions'],
      )
    }
  }
);
$zilla->chrome->logger->set_debug(1);
$zilla->build;
is_deeply(
  $zilla->distmeta->{prereqs},
  {
    'runtime' => {
      'requires' => {
        'Foo' => '6.0'
      }
    },
    'test' => {
      'requires' => {
        'Foo' => '6.0'
      }
    }
  },
  "Prereqs match expected"
);
note explain $zilla->distmeta;
note explain $zilla->log_messages;

done_testing;
