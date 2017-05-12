# (X)Emacs mode: -*- cperl -*-

use 5.10.0;
use strict;

=head1 Unit Test Package for Log::Info

This package tests that Log::Info, with :trap invoked, only logs die()s,
warnings, etc. once to stderr.

=cut

use Config       qw( %Config );
use FindBin 1.42 qw( $Bin );
use Test    1.13 qw( ok plan );

BEGIN {
  # Timing issues in non-ipc run often screw this up.
  eval "use IPC::Run 0.44 qw( );";
  if ( $@ ) {
    print STDERR "DEBUG: $@\n"
      if $ENV{TEST_DEBUG};
    print "1..0 # Skip: IPC::Run not found (or too old).\n";
    exit 0;
  }
}

use lib $Bin;
use test  qw( PERL );
use test2 qw( runcheck );

BEGIN {
  # 1 for compilation test,
  plan tests  => 61,
       todo   => [],
}

# ----------------------------------------------------------------------------

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

ok 1, 1, 'compilation';

# -------------------------------------

# call perl -MLog::Info=:trap -e '$!=0; $call "Blibble"'; watch the emitted
# strings and exit value.  Do this twice, second time with a newline after
# the "Blibble"
#
# $name: test name
# $call: subr name to call
# $libs: arrayref of libraries to pre-include; e.g., Carp
# $text: expected text to be emitted on stderr
# $exit: expected exit value
# $type: 0 => add \n to  $expect
#        1 => add .\n to $expect the first time, \n the second
#        2 => add .* at -e line 1\n to expect
#        3 => like 0, but expect to see line duplicated
#        all this because perl's warn puts a full-stop at the end of a trailing
#        'at line...'; whereas perl's die does not.

sub death {
  my ($name, $call, $libs, $text, $exit, $type) = @_;
  $type = 0
    unless defined $type;

  my ($out, $err) = ('') x 2;
  # call $call with a newline-less message
  ok(runcheck([[PERL, map("-M$_", @$libs), '-MLog::Info=:trap,:default_channels', 
                      -e => qq'\$!=0;$call "Blibble"'],
               '>', \$out, '2>', \$err,],
              "$name ( 1)", undef, $exit),
     1,                                                          "$name ( 1)");
  ok $out, '',                                                   "$name ( 2)";

  my $expect = "$text at -e line 1";
  given ( $type ) {
    when ( 1 ) { $expect .= ".\n" }
    when ( 2 ) { $expect = qr/$text (.* )?at -e line 1\n/s }
    when ( 3 ) { $expect .= "\n"; $expect x= 2 }
    default    { $expect .= "\n" }
  }

  # message is duplicated to stderr, see __trap_warn_die in Info.pm for why
  ok $err, $expect,                                           "$name ( 3)";

  ($out, $err) = ('') x 2;
  # call $call, with a newline appended to the message
  ok(runcheck([[PERL, map("-M$_", @$libs), '-MLog::Info=:trap,:default_channels',
                       -e => qq'\$!=0;$call "Blibble\n"'],
               '>', \$out, '2>', \$err,],
              "$name ( 4)", undef, $exit),
     1,                                                          "$name ( 4)");
  ok $out, '',                                                   "$name ( 5)";
  $expect = "$text\n";
  # I'm not at all sure why we need to special-case croak, but we do.  
  # So there.
  $expect = qr/$text(.* )?at -e line 1\n/s
    if $type == 2 or $name eq 'croak (imported)';
  $expect x= 2
    if 3 == $type;
  ok $err, $expect,                                              "$name ( 6)";
}

death('die',  'die', [], 'Blibble', 255, 3);
death('warn', 'warn', [], 'Blibble', 0, 1);

for (qw/ carp cluck confess croak /) {
  my $exit = (($_ eq 'croak' || $_ eq 'confess') ? 255 : 0);
  my $type = 2;
  death("$_ (imported)",     $_,       ["Carp=$_"], 'Blibble', $exit, 2);
  death("$_ (not imported)","Carp::$_",['Carp'],    'Blibble', $exit, 2);
}

# ----------------------------------------------------------------------------
