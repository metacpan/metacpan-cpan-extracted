# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for File::Info

This package tests the basic utility of File::Info

=cut

use Cwd                    2.04 qw( cwd );
use Fcntl                  1.03 qw( :seek );
use File::Basename          2.6 qw( basename );
use File::Copy             2.03 qw( cp );
use File::Glob            0.991 qw( :glob );
use File::Spec::Functions   1.1 qw( abs2rel catfile rel2abs rootdir );
use File::Temp             0.12 qw( tempdir );
use FindBin                1.42 qw( $Bin );
use Test                   1.13 qw( ok plan );

use lib $Bin;
use test qw( DATA_DIR
             evcheck );

use constant DATA1_FN    => 'data.01';
use constant DATA1_MD5   => 'f012bc80698fc6e6db5818793a59c5d9';
use constant DATA1_LAST4 => '3A!|';
use constant DATA1_MD5BIN =>
  pack 'C16', map hex, grep length, split /(..)/, DATA1_MD5;

use constant DATA2_FN    => 'data.02';
use constant DATA2_MD5   => 'c1bf808e12d6932f5bfcaff76f1b1dfb';
use constant DATA2_LAST4 => "\cPhUr";
use constant DATA2_MD5BIN =>
  pack 'C16', map hex, grep length, split /(..)/, DATA2_MD5;

use constant DATA3_FN    => 'evolutn.jpg';
use constant DATA3_MD5   => '74e81241fd827c9ce3a90d6a6fef31c3';
use constant DATA3_MD5BIN =>
  pack 'C16', map hex, grep length, split /(..)/, DATA3_MD5;
use constant DATA3_MD5_16K => '6ff1d320c8bbb61811d17c59f2d141db';
use constant DATA3_MD5_16KBIN =>
  pack 'C16', map hex, grep length, split /(..)/, DATA3_MD5_16K;

use constant CONSTANT    => 'wellington';

BEGIN {
  eval "use Digest::MD5 2.00 qw( );";
  if ( $@ ) {
    print STDERR $@
      if $ENV{TEST_DEBUG};
    print "1..0 # Skip Digest::MD5 2.00 not found\n";
    exit 0;
  }

  # 1 for compilation test,
  plan tests  => 37,
       todo   => [],
}

# ----------------------------------------------------------------------------

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

use File::Info;

ok 1, 1, 'compilation';

for ( bsd_glob(catfile DATA_DIR, 'data*'),
      bsd_glob(catfile DATA_DIR, '*.jpg' ),  ) {
  cp($_, basename $_)
    or die "File copy for $_: $!\n";
}

# -------------------------------------

=head2 Tests 2--3: md5file

=cut

my $i;
ok(evcheck(sub { $i=File::Info->new(cwd); }, 'md5file ( 1)'), 1,
                                                               'md5file ( 1)');
ok $i->md5hex(DATA1_FN), DATA1_MD5,                            'md5file ( 2)';

# -------------------------------------

=head2 Test 4: md5file again

Check that caching did not ruin everything!

=cut

ok $i->md5hex(DATA1_FN), DATA1_MD5,                      'md5file again ( 2)';

# -------------------------------------

=head2 Tests 5--7: md5 detail cached

=cut

ok exists $i->{_info}->{DATA1_FN()};
ok exists $i->{_info}->{DATA1_FN()}->{md5};
ok File::Info::_md5hex($i->{_info}->{DATA1_FN()}->{md5}), DATA1_MD5,
                                                     'md5 detail cached ( 3)';

# -------------------------------------

=head2 Tests 8--9: new file

# Test same filename, different contents, different dirs

=cut

my $tempdir = tempdir(CLEANUP => 1);
cp(catfile(DATA_DIR, DATA2_FN), catfile($tempdir, DATA1_FN));

my $j;
ok(evcheck(sub { $j=File::Info->new($tempdir); }, 'new file ( 1)'), 1,
                                                              'new file ( 1)');
ok $j->md5hex(DATA1_FN), DATA2_MD5,                           'new file ( 2)';

# -------------------------------------

=head2 Tests 10--12: local lookup

=cut

sub last4 {
  my ($fn) = @_;

  my $size = -s $fn;
  $size = 4
    if $size > 4;
  open my $fh, '<', $fn
    or die "Failed to open $fn: $!\n";
  seek $fh, -$size, SEEK_END;
  my $read;
  ($read = read $fh, my $buffy, $size) == $size
    or die "Short read on $fn (wanted $size, got $read): $!\n";
  close $fh
    or die "Failed to close $fn: $!\n";

  return $buffy;
}

ok(evcheck(sub { $j->add_local_lookup('last4', \&last4) },
           'local lookup ( 1)'),
   1,                                                     'local lookup ( 1)');
ok $j->last4(DATA1_FN), DATA2_LAST4,                      'local lookup ( 2)';
ok(evcheck(sub { $i->last4(DATA1_FN) }, 'local lookup ( 3)'),
   0,                                                     'local lookup ( 3)');

# -------------------------------------

=head2 Tests 13--15: global lookup

=cut

ok(evcheck(sub {File::Info->add_global_lookup ('rlast4',
                                               sub { reverse last4($_[0]) })}),
   1,                                                    'global lookup ( 1)');
ok $j->rlast4(DATA1_FN), reverse(DATA2_LAST4),           'global lookup ( 2)';
ok $i->rlast4(DATA1_FN), reverse(DATA1_LAST4),           'global lookup ( 3)';

# -------------------------------------

# Functions via the class for full paths

=head2 Tests 16--23: files with paths

=cut

my $fullname = catfile $tempdir, DATA1_FN;
ok(evcheck(sub { $j->md5hex($fullname) }, 'files with paths ( 1)'),
   0,                                                 'files with paths ( 1)');
ok(evcheck(sub { $j->rlast4($fullname) }, 'files with paths ( 2)'),
   0,                                                 'files with paths ( 2)');
ok(evcheck(sub { $j->last4($fullname) }, 'files with paths ( 3)'),
   0,                                                 'files with paths ( 3)');

ok(File::Info->md5hex($fullname), DATA2_MD5,          'files with paths ( 4)');
ok(evcheck(sub { File::Info->last4($fullname) }, 'files with paths ( 5)'),
   0,                                                 'files with paths ( 5)');
ok(File::Info->rlast4($fullname),reverse(DATA2_LAST4),'files with paths ( 6)');
my $incomplete = abs2rel($fullname, rootdir);
ok(evcheck(sub { File::Info->last4($incomplete) }, 'files with paths ( 7)'),
   0,                                                 'files with paths ( 7)');
ok(evcheck(sub { File::Info->rlast4($incomplete) }, 'files with paths ( 8)'),
   0,                                                 'files with paths ( 8)');

# -------------------------------------

=head2 Tests 24--28: another local

=cut

my $k;


ok(evcheck(sub { $k=File::Info->new(cwd); }, 'another local ( 1)'), 1,
                                                         'another local ( 1)');
ok(evcheck(sub { $k->add_local_lookup('last4', \&CONSTANT) },
           'another local ( 2)'),
   1,                                                    'another local ( 2)');
ok $j->last4(DATA1_FN), DATA2_LAST4,                     'another local ( 3)';
ok $k->last4(DATA1_FN), CONSTANT,                        'another local ( 4)';
ok(evcheck(sub { $i->last4(DATA1_FN) }, 'another local ( 5)'),
   0,                                                    'another local ( 5)');

# -------------------------------------

=head2 Tests 29--33: local override

=cut

ok(evcheck(sub { $k->add_local_lookup('md5', \&CONSTANT) },
           'local override ( 1)'),
   1,                                                   'local override ( 1)');
ok $k->md5(DATA1_FN), CONSTANT,                         'local override ( 2)';
ok $j->md5(DATA1_FN), DATA2_MD5BIN,                     'local override ( 3)';
ok(File::Info->md5($fullname), DATA2_MD5BIN,            'local override ( 4)');
my $fullname2 = rel2abs(DATA1_FN);
ok(File::Info->md5($fullname2), DATA1_MD5BIN,           'local override ( 5)');

# -------------------------------------

=head2 Tests 34--37: md5-16k

=cut

ok $i->md5hex(DATA3_FN), DATA3_MD5,                      'md5-16k again ( 1)';
ok $i->md5_16khex(DATA3_FN), DATA3_MD5_16K,              'md5-16k again ( 2)';
ok $i->md5(DATA3_FN), DATA3_MD5BIN,                      'md5-16k again ( 3)';
ok $i->md5_16k(DATA3_FN), DATA3_MD5_16KBIN,              'md5-16k again ( 4)';


# ----------------------------------------------------------------------------
