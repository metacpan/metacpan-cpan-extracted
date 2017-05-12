use strict;
use warnings;
use Test::More 0.96;
use Path::Class qw( foreign_file );

my $mod = 'Dist::Metadata';
eval "require $mod" or die $@;
$Dist::Metadata::VERSION ||= 0; # quiet warnings

# specifically test that expected paths are not indexed on various platforms
foreach my $spec ( qw(Unix Win32 Mac) ){
  my $dm = new_ok($mod, [struct => {
    file_spec => $spec,
    files => {
      README => 'nevermind',
      foreign_file($spec => qw(lib Mod Name.pm)) => "package Mod::Name;\nour \$VERSION = 0.11;",
      foreign_file($spec => qw(inc No.pm))       => "package No;\nour \$VERSION = 0.11;",
      foreign_file($spec => qw(t lib YU.pm))     => "package YU;\nour \$VERSION = 0.11;",
    }
  }]);

  is $dm->dist->file_spec, $spec, "dist faking file spec: $spec";

  is_deeply
    [sort $dm->dist->perl_files],
    [sort grep { !/README/ } keys %{ $dm->dist->{files} }],
    'perl files listed';

  is_deeply
    $dm->package_versions,
    {'Mod::Name' => '0.11'},
    't and inc not indexed';

  is_deeply
    $dm->determine_packages,
    {'Mod::Name' => {file => 'lib/Mod/Name.pm', version => '0.11'}},
    'determined package with translated path';
}

sub indexed_ok {
  my ($files, $exp, $desc) = @_;

  my $dm = new_ok($mod, [struct => {
    file_spec => 'Unix',
    files     => $files,
  }]);

  is_deeply $dm->package_versions, $exp, $desc;
}

sub _pkg {
  my ($name, $version) = @_;
  return "package $name;\nour \$VERSION = 0.$version;\n";
}


indexed_ok
  {
    'META.json' => <<JSON,
{
  "name": "X",
  "version": "1.1",
  "no_index": {
    "directory": [ "notthis" ]
  }
}
JSON
    'lib/A/B.pm'       => _pkg('A::B'   => 2),
    't/T.pm'           => _pkg('T'      => 3),
    'xt/XT.pm'         => _pkg('XT'     => 4),
    'inc/Inc.pm'       => _pkg('Inc'    => 5),
    'local/Local.pm'   => _pkg('Local'  => 6),
    'perl5/Perl5.pm'   => _pkg('Perl5'  => 7),
    'fatlib/FatLib.pm' => _pkg('FatLib' => 8),
    'Root.pm'          => _pkg('Some::Root' => 9),
    'notthis/More.pm'  => _pkg('Some::More' => 10),
    'butthis/Moar.pm'  => _pkg('Moar'   => 11),
  },
  {
    'A::B'       => '0.2',
    'Some::Root' => '0.9',
    'Moar'       => '0.11',
  },
  q[Merge 'always' no_index dirs with specified no_index dirs];

done_testing;
