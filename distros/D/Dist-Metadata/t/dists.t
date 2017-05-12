use strict;
use warnings;
use Test::More 0.96;
use Path::Class 0.24 qw(file);

my $mod = 'Dist::Metadata';
eval "require $mod" or die $@;
$Dist::Metadata::VERSION ||= 0; # quiet warnings

# we may need to prepend $FindBin::Bin
my $root = './corpus';
my $structs = do "$root/structs.pl";

# NOTE: Portability tests report issues with file names being long
# and containing periods, so there could be issues...

foreach my $test  (
  [
    [
      metafile =>
      'Dist-Metadata-Test-MetaFile-2.2',
    ],
    {
      name     => 'Dist-Metadata-Test-MetaFile',
      version  => '2.2',
      provides => {
        'Dist::Metadata::Test::MetaFile' => {
          file    => 'lib/Dist/Metadata/Test/MetaFile.pm',
          version => '2.1',
        },
        'Dist::Metadata::Test::MetaFile::PM' => {
          file    => 'lib/Dist/Metadata/Test/MetaFile/PM.pm',
          version => '2.0',
        },
      },
    },
  ],
  [
    [
      metafile_incomplete =>
      'Dist-Metadata-Test-MetaFile-Incomplete-2.1',
    ],
    {
      name     => 'Dist-Metadata-Test-MetaFile-Incomplete',
      version  => '2.1',
      provides => {
        'Dist::Metadata::Test::MetaFile::Incomplete' => {
          file    => 'lib/Dist/Metadata/Test/MetaFile/Incomplete.pm',
          version => '2.1',
        },
      },
    },
  ],
  [
    [
      nometafile =>
      'Dist-Metadata-Test-NoMetaFile-0.1',
    ],
    {
      name     => 'Dist-Metadata-Test-NoMetaFile',
      version  => '0.1',
      provides => {
        'Dist::Metadata::Test::NoMetaFile' => {
          file    => 'lib/Dist/Metadata/Test/NoMetaFile.pm',
          version => '0.1',
        },
        'Dist::Metadata::Test::NoMetaFile::PM' => {
          file    => 'lib/Dist/Metadata/Test/NoMetaFile/PM.pm',
          version => '0.1',
        },
      },
    },
  ],

 [
    [
      index_like_pause  => 'Dist-Metadata-Test-LikePause-0.1',
    ],
    {
      name     => 'Dist-Metadata-Test-LikePause',
      version  => '0.1',
      provides => {
        'Dist::Metadata::Test::LikePause' => {
          file    => 'lib/Dist/Metadata/Test/LikePause.pm',
          version => '0.1',
        },
      },
    },
  ],

 [
    [
      index_like_pause  => 'Dist-Metadata-Test-LikePause-0.1',
    ],
    {
      name     => 'Dist-Metadata-Test-LikePause',
      version  => '0.1',
      provides => {
        'Dist::Metadata::Test::LikePause' => {
          file    => 'lib/Dist/Metadata/Test/LikePause.pm',
          version => '0.1',
        },
        'ExtraPackage' => {
          file    => 'lib/Dist/Metadata/Test/LikePause.pm',
          version => '0.2',
        },
      },
    },
    {
      # this we should find the Extra (inner) package
      include_inner_packages => 1,
    },
  ],

  [
    [
      nometafile_dev_release =>
      'Dist-Metadata-Test-NoMetaFile-DevRelease-0.1_1',
    ],
    {
      name     => 'Dist-Metadata-Test-NoMetaFile-DevRelease',
      version  => '0.1_1',
      provides => {
        'Dist::Metadata::Test::NoMetaFile::DevRelease' => {
          file    => 'lib/Dist/Metadata/Test/NoMetaFile/DevRelease.pm',
          version => '0.1_1',
        },
      },
    },
  ],
  [
    [
      subdir =>
      'Dist-Metadata-Test-SubDir-1.5',
      'subdir',
    ],
    {
      name     => 'Dist-Metadata-Test-SubDir',
      version  => '1.5',
      provides => {
        'Dist::Metadata::Test::SubDir' => {
          file    => 'lib/Dist/Metadata/Test/SubDir.pm',
          version => '1.1',
        },
        'Dist::Metadata::Test::SubDir::PM' => {
          file    => 'lib/Dist/Metadata/Test/SubDir/PM.pm',
          version => '1.0',
        },
      },
    },
  ],
  [
    'noroot',
    {
      # can't guess name/version without formatted file name or root dir
      name     => 'noroot', # modified in loop
      version  => '0',
      provides => {
        'Dist::Metadata::Test::NoRoot' => {
          file    => 'lib/Dist/Metadata/Test/NoRoot.pm',
          version => '3.3',
        },
        'Dist::Metadata::Test::NoRoot::PM' => {
          file    => 'lib/Dist/Metadata/Test/NoRoot/PM.pm',
          version => '3.25',
        },
      },
    },
  ],
){
  my ( $dists, $exp, $opts ) = @$test;
  $exp->{package_versions} = do {
    my $p = $exp->{provides};
    +{ map { ($_ => $p->{$_}{version}) } keys %$p };
  };

  $dists = [ ($dists) x 2 ]
    unless ref $dists;

  my ($key, $file, $dir) = @$dists;

  $dir ||= $file;
  $_ = "corpus/$_" for ($file, $dir);

  $_ = file($root, $_)->stringify
    for @$dists;



  foreach my $args (
    [file => "$file.tar.gz"],
    [file => "$file.zip"],
    [dir  => $dir],
    [struct => { files => $structs->{$key} }],
  ){

    push @{ $args }, %{ $opts || {} };

    my $dm = new_ok( $mod, $args );
    # minimal name can be determined from file or dir but not struct
    $exp->{name} = Dist::Metadata::UNKNOWN() if $key eq 'noroot' && $args->[0] eq 'struct';

    # FIXME: perl 5.6.2 weirdness: http://www.cpantesters.org/cpan/report/4297a762-a314-11e0-b62c-be5be1de4735
    # #   Failed test 'verify corpus/noroot/lib/Dist/Metadata/Test/NoRoot/PM.pm for dir corpus/noroot'
    # #   at t/dists.t line 124.
    # #     Structures begin differing at:
    # #          $got = HASH(0x11c22d0)
    # #     $expected = undef
    is_deeply( $dm->$_, $exp->{$_}, "verify $_ for @$args" ) || dump_if_automated([$dm, $_, $exp])
      for keys %$exp;
  }
}

done_testing;

sub dump_if_automated {
  diag(explain(@_))
    if $ENV{AUTOMATED_TESTING};
}
