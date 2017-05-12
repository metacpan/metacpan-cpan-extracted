use strict;
use warnings;

use Test::More;
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini Builder );

# ABSTRACT: basic test

my $ini = simple_ini( ['Author::KENTNL::RecommendFixes'] );
my $tzil = Builder->from_config(
  { dist_root => 'invalid' },
  {
    'add_files' => {
      path('source/dist.ini')  => $ini,
      path('source/lib/.keep') => q[],
    },
  }
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my @messages = (
  [ qr/\.git does not exist/,           'Uninitialized git' ],
  [ qr/dist\.ini\.meta does not exist/, 'Unbaked dist' ],
  [ qr/weaver\.ini does not exist/,     'Ancient Pod::Weaver' ],
  [ qr/perltidyrc does not exist/,      'No perltidy' ],
  [ qr/Changes does not exist/,         'No Changes' ],
  [ qr/LICENSE does not exist/,         'No LICENSE' ],
  [ qr/Changes\.deps does not exist/,   'Diff changes' ],
);

for my $message (@messages) {
  ok(
    do {
      scalar grep { $_ =~ $message->[0] } @{ $tzil->log_messages };
    },
    "Has message for $message->[0]"
  );
}

note explain $tzil->log_messages;

done_testing;
