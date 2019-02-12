use strict;
use warnings;
use Test::More;
use FindBin ();
BEGIN {

  plan skip_all => "test requires Test::Version 2.00"
    unless eval q{
      use Test::Version 2.00 qw( version_all_ok ), { 
        has_version    => 1,
        filename_match => sub { $_[0] !~ m{/(ConfigData|Install/Files)\.pm$} },
      }; 
      1
    };

  plan skip_all => 'test requires YAML'
    unless eval q{ use YAML; 1; };
}

use YAML qw( LoadFile );
use FindBin;
use File::Spec;

my $config_filename = File::Spec->catfile(
  $FindBin::Bin, File::Spec->updir, File::Spec->updir, 'author.yml'
);

my $config;
$config = LoadFile($config_filename)
  if -r $config_filename;

if($config->{version}->{dir})
{
  note "using dir " . $config->{version}->{dir}
}

version_all_ok($config->{version}->{dir} ? ($config->{version}->{dir}) : ());
done_testing;

