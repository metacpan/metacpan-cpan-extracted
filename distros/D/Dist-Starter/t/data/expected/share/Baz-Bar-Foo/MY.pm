use strict;
use warnings;

package MY;

use File::Basename        qw( basename );
use File::Spec::Functions qw( catdir rel2abs );
use Module::Loaded        qw( is_loaded );

my $append_script_path = sub {
  my ( $self, $inherited ) = @_;

  my $path = '';
  $path = "\$($_):$path" foreach grep { -d basename $self->{ $_ } } map { "INST_$_" } qw( SCRIPT BIN );
  if ( $path ne '' ) {
    $inherited =~ s/\A[ \t]+//;
    $inherited = "\tPATH=\"$path:\$\$PATH\" " . $inherited
  }

  $inherited
};

# https://metacpan.org/pod/ExtUtils::MM_Any#postamble-(o)
sub postamble {
  my ( $self ) = @_;

  my $make_fragment = '';

  $make_fragment .= join "\n", '', File::ShareDir::Install::postamble( $self )
    if is_loaded 'File::ShareDir::Install';

  $make_fragment
}

# https://metacpan.org/pod/ExtUtils::MM_Any#test_via_harness
sub test_via_harness {
  my ( $self, $perl, $tests ) = @_;

  my $tlib = rel2abs( catdir( qw( t lib ) ) );
  $perl .= " -I$tlib" if -d $tlib;

  my $inherited = $self->SUPER::test_via_harness( $perl, $tests );

  $append_script_path->( $self, $inherited )
}

# https://metacpan.org/pod/ExtUtils::MM_Any#test_via_script
# testdb_* PHONY targets
sub test_via_script {
  my ( $self, $perl, $test ) = @_;

  my $tlib = rel2abs( catdir( qw( t lib ) ) );
  $perl .= " -I$tlib" if -d $tlib;

  my $inherited = $self->SUPER::test_via_script( $perl, $test );

  $append_script_path->( $self, $inherited )
}

1
