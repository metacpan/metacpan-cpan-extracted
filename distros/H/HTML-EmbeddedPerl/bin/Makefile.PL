use Config;
use ExtUtils::Embed;

my @mkbin = ('twepl', 'twepc');
my @mksrc = ('twepl_parse', 'twepl_xsubs', 'twepl_xcore');
my $mkinc = '../mod_twepl';

my $optsf = $Config{_exe};
my $optop = $Config{optimize};
my $optcc = ExtUtils::Embed::ccopts;
my $optld = ExtUtils::Embed::ldopts;

if($^O =~ /cygwin/i){
  $optcc =~ s/\-fstack\-protector//g;
  $optld =~ s/\-fstack\-protector//g;
}

  open MKF, '>Makefile';
  flock MKF, 2;

if($optsf){

  my $rcc = $Config{cc} eq 'cl' ? 'rc /Fo' : 'windres -o';
  my $cpc = $Config{cc} eq 'cl' ? 'copy' : 'cp -f';
  my $cpo = $Config{cc} eq 'cl' ? ' /B /Y' : '';
  my $rmc = $Config{cc} eq 'cl' ? 'del' : 'rm -f';
  my $rmo = $Config{cc} eq 'cl' ? ' /Q' : '';

  print MKF "all: ";

  foreach my $e(@mkbin){
    print MKF " $e\.res $e$Config{_o} $e$optsf";
  }; print MKF "\n\n";

  my($mft, $mfi, $mfu, $mfc);

  foreach my $e(@mkbin){
    print MKF "$e\.res:\n\t$rcc $e\.res $e\.rc\n$e$Config{_o}:\n\t$Config{cc} -c $optop $e\.c -I\x22$mkinc\x22 $optcc\n";
  }; print MKF "\n";

  foreach my $e(@mkbin){
    print MKF "$e$optsf: $e\.res $e$Config{_o}\n\t$Config{ld} $e\.res $e$Config{_o} $optld";
    $mft .= "\t$e$optsf t/twepx.t\n";
    $mfi .= "\t$cpc$cpo $e$optsf $Config{installbin}\\$e$optsf\n";
    $mfu .= "\t$rmc $Config{installbin}\\$e$optsf\n";
    $mfc .= "\t$rmc$rmo $e$optsf\n";
  }; print MKF "\n";

print MKF <<_EOM_;
test: all
$mft
install: all
$mfi
uninstall:
$mfu
clean:
$mfc
\t$rmc$rmo *$Config{_o}
\t$rmc$rmo *.res
\t$rmc$rmo *.pdb
realclean: clean
\t$rmc Makefile
_EOM_

} else{

  print MKF 'all: '.join(' ', @mkbin)."\n\n";

  my($mft, $mfi, $mfu, $mfc);

  foreach my $e(@mkbin){
    print MKF "$e:\n\t$Config{cc} $optop -o $e $e\.c -I$mkinc $optcc $optld\n";
    $mft .= "\t./$e t/twepx.t\n";
    $mfi .= "\tcp -f twepl $Config{installbin}/$e\n";
    $mfu .= "\trm -f $Config{installbin}/$e\n";
    $mfc .= "\trm -f $e\n";
  }

print MKF <<_EOM_;
test: all
$mft
install: all
$mfi
uninstall:
$mfu
clean:
$mfc
realclean: clean
\trm -f Makefile
_EOM_

}

  close MKF;

print "Writing Makefile for twepl.\n";
