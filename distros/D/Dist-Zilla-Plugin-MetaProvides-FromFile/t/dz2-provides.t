use strict;
use warnings;
use Test::More;
use Test::DZil qw( simple_ini Builder );

my $distmeta = <<'EOF';
[Imaginary::Package]
file = lib/Imaginary/Package.pm

[Imaginary::Package::With::Insane::Version]
file = lib/Imaginary/Package/Insane/Version.pm
version = 3.14159763
EOF

my $zilla = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        ['GatherDir'],
        [
          'MetaProvides::FromFile' => {
            file            => 'dist_meta_provides.ini',
            inherit_version => 0,
            inherit_missing => 1,
          }
        ]
      ),
      'source/dist_meta_provides.ini' => $distmeta,
      'source/lib/DZ2.pm'             => q[],
    },
  },
);
$zilla->chrome->logger->set_debug(1);
$zilla->build;

is_deeply(
  $zilla->distmeta->{provides},
  {
    'Imaginary::Package' => {
      'file'    => 'lib/Imaginary/Package.pm',
      'version' => '0.001'
    },
    'Imaginary::Package::With::Insane::Version' => {
      'file'    => 'lib/Imaginary/Package/Insane/Version.pm',
      'version' => '3.14159763'
    }
  },
  'Provides popuplation works'
);
note explain $zilla->log_messages;

done_testing;
