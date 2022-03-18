#!/usr/bin/perl -w
my $module = 'Math::Pari';
use strict;

my($msg, @crash, $tst) = 'No tests crashed';
for (<tst-run-*>) {
  ($tst=$_) =~ s/^tst-run-//;
  push@crash, "t/$tst";
  unlink $_ ;
  open FF, ">had-$_" and close FF;
}

if (@crash) {
  $msg = "  Test" .(@crash>1 and 's')." @crash crashed.  Reported" and warn $msg;
  unless ($ENV{AUTOMATED_TESTING} or $ENV{PERL_XSCODE_DEBUG}) {{
    if (($ENV{TMPDIR} || '') =~ /\bcpansmoker\b/i) {
      warn <<EOW;
I see that \$ENV{TMPDIR}=$ENV{TMPDIR}. Although AUTOMATED_TESTING and
PERL_XSCODE_DEBUG are not set, I assume that you want a more detailed report.
EOW
      last;
    }
    warn("    ... but skip auto-debug:\n\t  AUTOMATED_TESTING and PERL_XSCODE_DEBUG not set\n");
    @crash=();
  }}
}
print "1..1\nok 1\n";

my $debugger = 'auto-dbg/auto-debug-module.pl';
$debugger = "../$debugger" if not -f $debugger and -f "../$debugger";
@ARGV = ('-q', $module, @crash);
$0 = $debugger;
do $debugger or warn "$debugger exited unexpectedly: $@";
__END__
