# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Log::Info

This package tests the enable_file_channel/progress option in Log::Info

=cut

use FindBin 1.42 qw( $Bin );
use Test 1.13 qw( ok plan );

use lib $Bin;
use test qw( DATA_DIR
             evcheck restore_output save_output );

BEGIN {
  # 1 for compilation test,
  eval "use Term::ProgressBar 2.00 qw( );";
  if ( $@ ) {
    print "1..0 # Skip: Term::ProgressBar not found\n";
    print STDERR $@
      if $ENV{TEST_DEBUG};
    exit 0;
  }

  plan tests  => 5,
       todo   => [],
}

# ----------------------------------------------------------------------------

use Log::Info qw( :DEFAULT :default_channels :log_levels );
$Log::Info::__SINK_TERM_FORCE = 50;

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

ok 1, 1, 'compilation';

# -------------------------------------

=head Tests 2--5: enable_file_channel

=cut

{
  save_output('stderr', *STDERR{IO});
  ok(evcheck (sub {
	 	Log::Info::enable_file_channel(CHAN_PROGRESS, ':2',
                                               'option', 'sink', 1);
              }, 'enable_file_channel (1)'),
    1, 'enable_file_channel (1)');
  ok(evcheck (sub {
                Log(CHAN_PROGRESS, LOG_ERR, sprintf('[%d%% Done]',$_ ))
                  for 1..100;
              }, 'enable_file_channel (2)'),
     1,
     'enable_file_channel (2)');
  my $err = restore_output('stderr');

  $err =~ s!^.*\r!!gm;
  print STDERR "ERR:\n$err\nlength: ", length($err), "\n"
    if $ENV{TEST_DEBUG};

  my @lines = split /\n/, $err;

  ok $lines[-1], qr/\[=+\]/,            'enable_file_channel (3)';
  ok $lines[-1], qr/^\s*100%/,          'enable_file_channel (4)';
}

__END__
