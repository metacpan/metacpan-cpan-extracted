use Test::More tests => 8;
# perl -d:DumpTrace=arg ...  fails to compile in Cygwin Perl 5.8.8,
# but it works in other Cygwin builds and Perl 5.8.8 on other platforms.
#	($^O eq 'cygwin' && $] == 5.008008 
#	? (skip_all => 'Cygwin 5.8.8 bug invalidates this test')
#	: (tests => 8));
use strict;
use warnings;

# using +<regex> and -<regex> to include/exclude packages.


# on some builds of v5.8.8, and only v5.8.8, there is a bug where
# 
#     perl5.8.8 -d:Foo=1 -e 1
#
# croaks with the specific compile-time error
#
#    "Can't find string terminator ";" anywhere before EOF."
#
# instead of working. This test will not work when that
# bug is present.

if ($] == 5.008008) {
    my $err = '';
    $err = qx($^X -d:Foo=1 -e 1 2>&1);

    if ($err =~ /Can't find string terminator .../) {
      SKIP: {
	  skip "5.8.8 has a bug with 'perl -d:Foo=bar ...', can't test", 8;
	}
	exit 0;
    }
}


# this test just completely fails on Cygwin 5.8.8?
# It is ok on other Cygwin versions and on version 5.8.8 on other platforms.

my $dmodule = "-d:DumpTrace";

open T, '>', "$0.pl";
print T <<'EO_T;';

{
  package Abc::Def::Ghi;

  sub jkl {
    42;
  }

}

{
  package Abc::Ghi::Jkl;

  sub mno {
    19;
  }

}

package Abc::Def;
Abc::Def::Ghi::jkl();
Abc::Ghi::Jkl::mno();

EO_T;
;

my @test = ( "",                       # no exclusions
	     "=-.*Ghi.*",              # exclude both subs
	     "=-.*Ghi.*,+.*Jkl.*",     # exclude both then include *Jkl*
	     "=-.*Jkl.*,+.*Ghi.*" );   # exclude *Jkl* then include both
my @results = ("4219", 
	       "", 
	       "19", 
	       "4219");

for my $z (0,1,2,3) {

  my $file = "$0.out.$z";
  my $keep = 0;
  $ENV{DUMPTRACE_FH} = $file;
  $ENV{DUMPTRACE_LEVEL} = 3;

  print qq<system($^X, "$dmodule$test[$z]", "-Iblib/lib", "-Ilib", "$0.pl")>;
  print "\n";
  my $c1 = system($^X, "-Iblib/lib", "-Ilib", $dmodule . $test[$z], "$0.pl");
  ok($c1 == 0, "ran test $z successfully") or $keep++;
  open XH, '<', $file;
  my @xh = <XH>;
  close XH;

  my $result = "42" x grep { /42/ } @xh;
  $result .= "19" x grep { /19/ } @xh;
  ok($results[$z] eq $result, "Got expected result $results[$z] eq $result");

  unlink $file unless $keep && ++$::gkeep;
}
unlink "$0.pl" unless $::gkeep;

