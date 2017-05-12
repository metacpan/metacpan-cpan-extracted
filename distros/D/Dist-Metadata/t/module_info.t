use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;
use Path::Class;

my $mod = 'Dist::Metadata';
eval "require $mod" or die $@;

test_module_info(
  [file => file(qw(corpus Dist-Metadata-Test-NoMetaFile-0.1.tar.gz))->stringify],
  {
    'Dist::Metadata::Test::NoMetaFile' => {
      file    => 'lib/Dist/Metadata/Test/NoMetaFile.pm',
      version => '0.1',
      md5     => 'd4a5a07d20dd1fdad6191d5950287609',
      sha1    => '99d1aa7e3dbaa54dc16f178a8a4d2a9ba4d33da2',
      sha256  => '7d888a6c321041adbc1225b3ca12ae22ebfccdf221e5e3f0ccb2dec1a9c0a71a',
    },
    'Dist::Metadata::Test::NoMetaFile::PM' => {
      file    => 'lib/Dist/Metadata/Test/NoMetaFile/PM.pm',
      version => '0.1',
      md5     => '6e8845e06e7297bc913ebf3f1447c89a',
      sha1    => '843ce5cd5443c7ae2792f7b58e069fcab64963c8',
      sha256  => 'bc61da45e576a43155fcf296d03f74532bfe3a410f88aeaa75ade9155f67d049',
    },
  },
);

test_module_info(
  [file => file(qw(corpus Dist-Metadata-Test-MetaFile-2.2.zip))->stringify],
  {
    'Dist::Metadata::Test::MetaFile' => {
      file    => 'lib/Dist/Metadata/Test/MetaFile.pm',
      version => '2.1',
      md5     => '95fe72abee727b584941eda6da89f049',
      sha1    => '2c4341d7778a78702e364f2c38c6c97b8410387d',
      sha256  => '17dbde0b5b534d2a9ff9d188133da11670e3909ce853ac333aaa6973b348701e',
    },
    'Dist::Metadata::Test::MetaFile::PM' => {
      file    => 'lib/Dist/Metadata/Test/MetaFile/PM.pm',
      version => '2.0',
      md5     => '873b2db91af4418020350d3337f6c173',
      sha1    => '29553e76693b13b1e3d9f4493ee9d05c4cd4f6fb',
      sha256  => '53c79b083cb731e2f642ae409459756a483b6912b99ed61c34edbbfb483ea7d1',
    },
  }
);

{
  my $args = [
    struct => {
      files => {
        'fb/lib/Foo/Bar.pm' => "package Foo::Bar;\nour \$VERSION = 13;\n",
        'fb/README.txt'     => "anything\n",
      }
    }
  ];
  my $exp = {
    'Foo::Bar' => {
      file    => 'lib/Foo/Bar.pm',
      version => '13',
      md5     => '8642ef750b6ca0d9c9afe5db4174e009',
      sha1    => '2a4899cefacd1defd114731fec0e58c747eb9471',
      sha256  => '368e2f18d80a866537153885807ddf6e0733168b683b0a7ecac6d257943ac894',
    },
  };

  test_module_info($args, $exp);

  my $dm = new_ok($mod => $args);
  my $provides = {
    'Who::Cares' => {
      file      => 'README.txt',
      version   => 0,
    },
  };

  # specify our own 'provides'
  my $mi = $dm->module_info({digest => ['MD5', 'SHA-256'], provides => $provides});

  # use official names
  my $checksums = {
    'MD5'     => 'f5b1321af715fbd4866590170ddbe8f6',
    'SHA-256' => 'ce32b18ae7f79e70f7cde4cf6077ae8b4195044307a78a4ea8761ddfedf9badc',
  };

  @{ $provides->{'Who::Cares'} }{ keys %$checksums } = values %$checksums;

  is_deeply $provides, $mi, 'module info with official checksum names';
}

done_testing;

sub test_module_info {
  my ($args, $info) = @_;
  my $dm = new_ok($mod => $args);

  my $p = $dm->provides;
  {
    my $m = $dm->module_info;
    is_deeply $p, $m, 'provides and module_info have the same';
    is_deeply limit_keys($info), $m, 'sanity check - no checksums';
  }

  foreach my $checksums (
    'md5',
    ['sha1'],
    [qw(md5 sha256)],
  ){
    is_deeply limit_keys($info, $checksums), $dm->module_info({checksum => $checksums});
  }
}

sub limit_keys {
  my $hash = { %{ shift() } };
  my @keys = map { ref($_) eq 'ARRAY' ? @$_ : $_ } (qw(file version), @_);

  foreach my $mod ( keys %$hash ){
    my $info = delete $hash->{ $mod };
    my $new  = $hash->{ $mod } = {};
    @$new{ @keys } = @$info{ @keys };
  }

  return $hash;
}
