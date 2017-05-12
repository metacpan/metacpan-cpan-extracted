# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Getopt::Plus

This package tests the check_run function of the Getopt::Plus package.

=cut

use FindBin 1.42 qw( $Bin );
use Test 1.13 qw( ok plan );

use lib $Bin;
use test qw( DATA_DIR
             evcheck find_exec );

BEGIN {
  # 1 for compilation test,
  plan tests  => 13,
       todo   => [],
}

sub read_file {
  my ($fn) = @_;
  open my $fh, '<', $fn;
  local $/ = undef;
  my $contents = <$fh>;
  close $fh;
  return $contents;
}

# ----------------------------------------------------------------------------

our ($PACKAGE, $VERSION) = ('') x 2; # Keep Getopt::Plus happy

use Getopt::Plus;

my $rse = Getopt::Plus->new(scriptname => $0,
                            main       => sub {},
                            c_years    => [ 2002 ],
                            package    => $PACKAGE,
                            version    => $VERSION,
                            dry_run    => 1,);

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

ok 1, 1, 'compilation';

# -------------------------------------

=head2 Test 2: true

Run /bin/true with check_run.  Check it works.

=cut

{
  ok(evcheck(sub { $rse->check_run(cmd  => [[ find_exec('true') ]],
                                   name => 'true') },
             'true ( 1)'),
     1,                                                           'true ( 1)');
}

# -------------------------------------

=head2 Test 3: expect

Run /bin/false with check_run.  Check it works (and correctly "expects" the
expect value)

=cut

{
  ok(evcheck(sub { $rse->check_run(cmd    => [[ find_exec('false') ]],
                                   name   => 'false',
                                   expect => 1) },
             'expect ( 1)'),
     1,                                                         'expect ( 1)');
}

# -------------------------------------

=head2 Test 4--5: stdout

Run cat /etc/passwd with check_run.  Check it works, and it outputs the right
stuff.

=cut

{
  my $fn = '/etc/passwd';
  my $out = '';
  ok(evcheck(sub { $rse->check_run(cmd    => [[ 'cat', $fn ]],
                                   name   => 'cat',
                                   stdout => \$out,
                                  ) },
             'stdout ( 1)'),
     1,                                                         'stdout ( 1)');
  ok $out, read_file($fn),                                      'stdout ( 2)';
}

# -------------------------------------

=head2 Test 6--7: dry_run 1

Run cat /etc/passwd with check_run, with dry_run set to 0.  Check it works,
and it outputs the right stuff.

=cut

{
  my $fn = '/etc/passwd';
  my $out = '';
  ok(evcheck(sub { $rse->check_run(cmd     => [[ 'cat', $fn ]],
                                   name    => 'cat',
                                   stdout  => \$out,
                                   dry_run => 0,
                                  ) },
             'dry_run 1 ( 1)'),
     1,                                                      'dry_run 1 ( 1)');
  ok $out, read_file($fn),                                   'dry_run 1 ( 2)';
}

# -------------------------------------

=head2 Test 8--9: dry_run 2

Run cat /etc/passwd with check_run, with dry_run set to 0, and the dry_run
option invoked.  Check it works, and it outputs the right stuff.

=cut

{
  my $fn = '/etc/passwd';
  my $out = '';
  $rse->set___opt_dry_run;
  ok(evcheck(sub { $rse->check_run(cmd     => [[ 'cat', $fn ]],
                                   name    => 'cat',
                                   stdout  => \$out,
                                   dry_run => 0,
                                  ) },
             'dry_run 2 ( 1)'),
     1,                                                      'dry_run 2 ( 1)');
  ok $out, read_file($fn),                                   'dry_run 2 ( 2)';
}

# -------------------------------------

=head2 Test 10--11: dry_run 3

Run cat /etc/passwd with check_run, with dry_run set to 1, and the dry_run
option invoked.  Check it works, and nothing is output.

=cut

{
  my $fn = '/etc/passwd';
  my $out = '';
  $rse->set___opt_dry_run;
  ok(evcheck(sub { $rse->check_run(cmd     => [[ 'cat', $fn ]],
                                   name    => 'cat',
                                   stdout  => \$out,
                                   dry_run => 1,
                                  ) },
             'dry_run 3 ( 1)'),
     1,                                                      'dry_run 3 ( 1)');
  ok $out, '',                                               'dry_run 3 ( 2)';
}

# -------------------------------------

=head2 Test 12--13: dry_run 4

Run cat /etc/passwd with check_run, with dry_run set to 1, and the dry_run
option not invoked.  Check it works, and it outputs the right stuff.

=cut

{
  my $fn = '/etc/passwd';
  my $out = '';
  $rse->clear___opt_dry_run;
  ok(evcheck(sub { $rse->check_run(cmd     => [[ 'cat', $fn ]],
                                   name    => 'cat',
                                   stdout  => \$out,
                                   dry_run => 1,
                                  ) },
             'dry_run 4 ( 1)'),
     1,                                                      'dry_run 4 ( 1)');
  ok $out, read_file($fn),                                   'dry_run 4 ( 2)';
}

# ----------------------------------------------------------------------------
