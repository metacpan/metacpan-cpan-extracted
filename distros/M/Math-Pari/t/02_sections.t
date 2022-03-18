#!/usr/bin/perl -w
	# A poor-man indicator of a crash
	my $SELF;
	BEGIN { ($SELF = __FILE__) =~ s(.*[/\\])();
	   open CR, ">tst-run-$SELF" and close CR}	# touch a file
	END {unlink "tst-run-$SELF"}			# remove it - unless we crash

BEGIN { unshift @INC, './lib', '../lib';
    require Config; import Config;
}

use Math::Pari;
(my $V = Math::Pari::pari_version_exp) =~ s/\d\d\d$//;

$test = 0;
$| = 1;
my %sec = qw(1 max 2 lift 3 erfc 4 factorint 5 elleta 6 idealnorm 7 polresultant 8 matrank 9 sumalt 10 ploth 11 forstep); # 2.3.5
my $secs = keys %sec;
my($mx, @extra) = 11;
$mx < $_ and $mx = $_ for keys %sec;
if ($V >= 2009) {
  @extra = (100..102);
  @sec{@extra} = qw(lfunan mseisenstein algbasis);	# :l_functions :modular_symbols :algebras
}
if ($V >= 2011) {
  push @extra, (103..104);
  @sec{103..104} = qw(numbpart mftonew);	# :combinatorics :modular
}
print "1..", &last ,"\n";

sub test {
  $test++; if (shift) {print "ok $test\n";1} else {print "not ok $test\n";0}
}

my %secOf;
for my $sec (0..$mx, @extra) {
  $secOf{$_} = $sec for Math::Pari::listPari($sec);
  test(1);
}
for my $psec (sort keys %sec) {
  my $f = $sec{$psec};
  test(1), next if $f eq 'ploth' and not Math::Pari->can('ploth');
#  my $sec = $psec + ($V == 2009 and 2*($psec>=6) + ($psec>=7));
#  warn "$f => actual=$secOf{$f}\n";
  warn "Mismatch: $f => stored=$psec, actual=$secOf{$f}\n"
   unless test( $secOf{$f} == $psec );
}
sub last {1 + $mx + @extra + keys %sec}
