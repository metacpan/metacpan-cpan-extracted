use strict;
use warnings;
use Test::More 'no_plan';
use File::Temp qw[tempdir];
use File::Spec;

use_ok('Dist::Zooky::DistIni');

{
  my $dir = tempdir( CLEANUP => 1, DIR => '.' );

  my $meta = {
    name => 'Foo-Bar',
    version => '0.02',
    author => [ 'Duck Dodgers', 'Ivor Module', ],
    license => [ 'Perl_5' ],
  };

  my $distini = Dist::Zooky::DistIni->new( type => 'MakeMaker', metadata => $meta );
  isa_ok( $distini, 'Dist::Zooky::DistIni' );

  my $file = File::Spec->catfile( $dir, 'dist.ini' );

  $distini->write( $file );

  ok( -e $file, 'The file exists' );

  {
    open my $fh, '<', $file or die "Could not open '$file': $!\n";
    my $content = do { local $/; <$fh> };

    like( $content, qr/\Q$_\E/s, "Content contains '$_'" ) for
    ( 'name = Foo-Bar',
      'version = 0.02',
      'author = Duck Dodgers',
      'author = Ivor Module',
      'license = Perl_5',
      'holder = Duck Dodgers',
      '[GatherDir]',
      '[PruneCruft]',
      '[ManifestSkip]',
      '[MetaYAML]',
      '[MetaJSON]',
      '[License]',
      '[Readme]',
      '[ExecDir]',
      '[ExtraTests]',
      '[ShareDir]',
      '[MakeMaker]',
      '[Manifest]',
      '[TestRelease]',
      '[ConfirmRelease]',
      '[UploadToCPAN]',
      ';[Prereqs / ConfigureRequires]',
      ';[Prereqs / BuildRequires]',
      ';[Prereqs]',);

    close $fh;
  }
}
