use strict;
use warnings;

use Test::More tests => 2;
use Test::DZil qw( simple_ini Builder );

use Module::Metadata;
use Test::Fatal;

my $files = {};
$files->{'source/dist.ini'} = simple_ini(
  [ 'Prereqs' => { 'Test::More' => 0 } ],
  [ 'Prereqs::Recommend::MatchInstalled', { module => ['Test::More'] } ],
  ['MetaConfig'],
);
my $test = Builder->from_config( { dist_root => 'invalid' }, { add_files => $files } );
$test->chrome->logger->set_debug(1);
$test->build;
pass("Builds ok");

my $v = Module::Metadata->new_from_module('Test::More');
is_deeply( $test->distmeta->{prereqs}->{runtime}->{recommends}, { 'Test::More' => $v->version('Test::More')->stringify }, );
note explain $test->log_messages;
