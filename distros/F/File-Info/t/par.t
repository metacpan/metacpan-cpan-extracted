# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for File::Info

This package tests the par-related methods of File::Info; type, md5_16k,
par_set_md5.

=cut

use Cwd                   2.04 qw( cwd );
use File::Basename         2.6 qw( basename );
use File::Copy            2.03 qw( cp );
use File::Spec::Functions  1.1 qw( catfile );
use FindBin               1.42 qw( $Bin );
use Test                  1.13 qw( ok plan );

use lib $Bin;
use test qw( DATA_DIR
             evcheck );

use constant DATA_FN   => 'bar.par';
use constant DATA_SET  => '9ef3c7975776ef9e9ddf9c5704b1fbc1';
use constant DATA_SET_BIN =>
  pack 'C16', map hex, grep length, split /(..)/, DATA_SET;

use constant DATA1     => 'cack.par';

BEGIN {
  # 1 for compilation test,
  eval "use Archive::Par 1.52 qw( )";
  if ($@) {
    print STDERR $@
      if $ENV{TEST_DEBUG};
    print "1..0 # Skipped: Archive::Par 1.52 not found";
    exit 0;
  }

  plan tests  => 8,
       todo   => [],
}

# ----------------------------------------------------------------------------

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.  It also checks that the data files were successfully copied to
the temp area.

=cut

use File::Info qw( :types );

for ( glob(catfile DATA_DIR, '*.par') ) {
  cp($_, basename $_)
    or die "File copy for $_: $!\n";
}

ok 1, 1, 'compilation';

# -------------------------------------

=head2 Tests 2--8: par tests

=cut

my $i;
ok(evcheck(sub { $i=File::Info->new(cwd); }, 'par tests ( 1)'), 1,
                                                             'par tests ( 1)');
ok $i->type(DATA_FN), TYPE_PAR,                              'par tests ( 2)';
ok $i->type(DATA1) ne TYPE_PAR;
ok $i->par_set_hash(DATA_FN), DATA_SET_BIN,                  'par tests ( 4)';
ok $i->par_set_hash_hex(DATA_FN), DATA_SET,                  'par tests ( 5)';
ok(evcheck(sub { $i->par_set_hash(DATA1) }, 'par tests ( 5)'),
   0,                                                        'par tests ( 6)');
ok(evcheck(sub { $i->par_set_hash_hex(DATA1) }, 'par tests ( 6)'),
   0,                                                        'par tests ( 7)');

# ----------------------------------------------------------------------------

