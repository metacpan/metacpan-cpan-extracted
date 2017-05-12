use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Test::Moose;
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini Builder );

my $test_config = [
   ['GatherDir'],    #
    [
      'MetaProvides::Package' => {
        inherit_version => 0,    #
        inherit_missing => 1
      }
    ]
];
my $test_document = <<'EOF';
use strict;
use warnings;

sub main {
  return 1;
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

isa_ok( $plugin, 'Dist::Zilla::Plugin::MetaProvides::Package' );
meta_ok( $plugin, 'Plugin is mooseified' );
does_ok( $plugin, 'Dist::Zilla::Role::MetaProvider::Provider', 'does the Provider Role' );
does_ok( $plugin, 'Dist::Zilla::Role::Plugin', 'does the Plugin Role' );
has_attribute_ok( $plugin, 'inherit_version' );
has_attribute_ok( $plugin, 'inherit_missing' );
has_attribute_ok( $plugin, 'meta_noindex' );
is( $plugin->meta_noindex, '1', "meta_noindex default is 1" );

cmp_ok( scalar $plugin->provides, '==', 0, "nothing was provided" );

my $re = qr/No namespaces detected in file lib[\/]DZ2\.pm/;
if ( grep { $_ =~ $re } @{ $tzil->log_messages } ) {
  pass("Warned about missing packages");
} else {
  fail("Warned about messages");
  diag("Expected message matching $re");
  diag("Got messages:");
  diag(explain($tzil->log_messages));
}
done_testing;
