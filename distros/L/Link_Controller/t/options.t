#!/usr/bin/perl -w

#apart from testing options, this also forces each of the programs to
#be run and so checked that they at least compile.

use Cwd;

$ENV{HOME}=cwd() . "/t/homedir";
$config=$ENV{HOME} . "/.link-control.pl";
die "LinkController test config file, $config missing." unless -e $config;

BEGIN {print "1..2\n"}

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

$err=0;
HELPCHECK: foreach (glob 'blib/script/*') {
  m/cgi/ && next;
  m/test-tmp/ && next;
  $response = `perl -I ./blib/lib ./$_ --help`;
  $response or do {warn "./$_ had no --help text"; $err++; next};
  ($base=$_) =~ s,.*/,,;
  $response =~ m/fortune/ and do
    { warn "./$_ seems to have outdated help text"; $err++;
      next HELPCHECK};
  $response =~ m/$base/ or do
    { warn "./$_ failed to mention its self in --help text"; $err++;
      next HELPCHECK};
}
$err && nogo;
ok(1);

$err=0;
VERCHECK: foreach (glob 'blib/script/*') {
  m/cgi/ && next;
  m/test-tmp/ && next;
  $response = `perl -I ./blib/lib ./$_ --version`;
  $response or do {warn "$_ had no --version text"; $err++; next};
  ($base=$_) =~ s,.*/,,;
  $response =~ m/$base/ or do 
    { warn "./$_ failed to mention its self in --version text";
      $err++; next VERCHECK}
}
$err && nogo;
ok(2);
