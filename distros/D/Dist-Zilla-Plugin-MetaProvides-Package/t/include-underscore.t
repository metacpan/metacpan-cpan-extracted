use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini Builder );

my $test_config = [
  ['GatherDir'],    #
  [
    'MetaProvides::Package' => {
      inherit_version     => 0,    #
      inherit_missing     => 1,    #
      include_underscores => 1,
    },
  ]
];

my $test_document = <<'EOF';
use strict;
use warnings;
package DZ2;

sub main {
  return 1;
}

package    # Hide me from indexing
  A::Hidden::Package;

sub hidden {
  return 2;
}

package A::_Local::Package;

sub private {
  return 3;
}

1;
__END__

=head1 NAME

DZ2

=cut
EOF

my $tzil = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      path('source/lib/DZ2.pm') => $test_document,
      path('source/dist.ini')   => simple_ini( @{$test_config} ),
    },
  },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $plugin;

is(
  exception {
    $plugin = $tzil->plugin_named('MetaProvides::Package');
  },
  undef,
  'Found MetaProvides::Package'
);

# This crap is needed because 'ok' is mysteriously not working.
( exists $plugin->metadata->{provides}->{'A::_Local::Package'} )
  ? pass('Packages leading with _ are not hidden')
  : do { fail('Packages leading with _ are not hidden'); diag explain $plugin->metadata; };

( not exists $plugin->metadata->{provides}->{'A::Hidden::Package'} )
  ? pass('Packages with \n are hidden')
  : fail('Packages with \n are hidden');

done_testing;
