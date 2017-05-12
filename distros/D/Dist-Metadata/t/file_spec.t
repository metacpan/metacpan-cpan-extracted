use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Dist::Metadata::Struct';
eval "require $mod" or die $@;

# all these translate into "Native"
foreach my $test (
  [ '' => 'Native' ],
  [ qw( File::Spec         Native ) ],
  [ qw( File::Spec::Native Native ) ],
  [ qw(             Native Native ) ],
  [ qw(             Win32  Win32  ) ],
  [ qw( File::Spec::Win32  Win32  ) ],
) {
  my ( $spec, $exp ) = @$test;
  my $dist = new_ok( $mod, [ file_spec => $spec, files => {} ] );
  is( $dist->file_spec, $exp, "spec '$spec' => '$exp'" );
}

# test using default File::Spec
{
  my $dist = new_ok( $mod, [ file_spec => '', files => {
    README => 'read me',
    'Module.pm' => \"package Some::Module;\nour \$VERSION = 2;",
  } ] );
  is_deeply( $dist->determine_packages, {'Some::Module' => { file => 'Module.pm', version => 2 }},
    'found package in root' );
}

done_testing;
