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
use constant DATA1_LAST4 => '3A!|';
use constant DATA1_LINES => 0;

use constant DATA2_FN    => 'data.02';
use constant DATA2_LAST4 => "\cPhUr";
use constant DATA2_LINES => 2;

use constant DATA3_FN    => 'data.03';
use constant DATA3_LINES => 29;

use constant DATA4_FN    => 'data.04';
use constant DATA4_LINES => 26;

use constant BAR_PAR     => 'bar.par';
use constant CACK_PAR    => 'cack.par';

use constant EVO_JPG     => 'evolutn.jpg';

use constant CONSTANT    => 'wellington';

BEGIN {
  # 1 for compilation test,
  plan tests  => 37,
       todo   => [],
}

# ----------------------------------------------------------------------------

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

use File::Info qw( :types );

ok 1, 1, 'compilation';

for ( bsd_glob(catfile DATA_DIR, 'data*'),
      bsd_glob(catfile (DATA_DIR, '*.{par,jpg}'), GLOB_BRACE ), ) {
  cp($_, basename $_)
    or die "File copy for $_: $!\n";
}

# -------------------------------------

=head2 Tests 2--3: line_count

=cut

my $i;
ok(evcheck(sub { $i=File::Info->new(cwd); }, 'line_count ( 1)'), 1,
                                                            'line_count ( 1)');
ok $i->line_count(DATA3_FN), DATA3_LINES,                   'line_count ( 2)';

# -------------------------------------

=head2 Test 4: line_count again

Check that caching did not ruin everything!

=cut

ok $i->line_count(DATA3_FN), DATA3_LINES,              'line_count again ( 2)';

# -------------------------------------

=head2 Tests 5--7: line_count detail cached

=cut

ok exists $i->{_info}->{DATA3_FN()};
ok exists $i->{_info}->{DATA3_FN()}->{line_count};
ok $i->{_info}->{DATA3_FN()}->{line_count}, DATA3_LINES,
                                               'line_count detail cached ( 3)';

# -------------------------------------

=head2 Tests 8--9: new file

# Test same filename, different contents, different dirs

=cut

my $tempdir = tempdir(CLEANUP => 1);
cp(catfile(DATA_DIR, DATA4_FN), catfile($tempdir, DATA3_FN));
cp(catfile(DATA_DIR, DATA2_FN), catfile($tempdir, DATA1_FN));

my $j;
ok(evcheck(sub { $j=File::Info->new($tempdir); }, 'new file ( 1)'), 1,
                                                              'new file ( 1)');
ok $j->line_count(DATA3_FN), DATA4_LINES,                     'new file ( 2)';

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
ok(evcheck(sub { $j->line_count($fullname) }, 'files with paths ( 1)'),
   0,                                                 'files with paths ( 1)');
ok(evcheck(sub { $j->rlast4($fullname) }, 'files with paths ( 2)'),
   0,                                                 'files with paths ( 2)');
ok(evcheck(sub { $j->last4($fullname) }, 'files with paths ( 3)'),
   0,                                                 'files with paths ( 3)');

ok(File::Info->line_count($fullname), DATA2_LINES,    'files with paths ( 4)');
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

ok(evcheck(sub { $k->add_local_lookup('line_count', \&CONSTANT) },
           'local override ( 1)'),
   1,                                                   'local override ( 1)');
ok $k->line_count(DATA1_FN), CONSTANT,                  'local override ( 2)';
ok $j->line_count(DATA1_FN), DATA2_LINES,               'local override ( 3)';
ok(File::Info->line_count($fullname), DATA2_LINES,      'local override ( 4)');
my $fullname2 = rel2abs(DATA1_FN);
ok(File::Info->line_count($fullname2), DATA1_LINES,     'local override ( 5)');

# -------------------------------------

=head2 Tests 34--37: type

=cut

ok $i->type(DATA1_FN), TYPE_UNKNOWN,                              'type ( 1)';
ok $i->type(BAR_PAR),  TYPE_PAR,                                  'type ( 2)';
ok $i->type(CACK_PAR), TYPE_UNKNOWN,                              'type ( 3)';
ok $i->type(EVO_JPG),  TYPE_JPEG,                                 'type ( 4)';

# ----------------------------------------------------------------------------
