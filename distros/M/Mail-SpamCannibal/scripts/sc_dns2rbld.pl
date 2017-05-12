#!/usr/bin/perl
#
# sc_dns2rbld.pl
#
# version 1.01, 5-7-05, michael@bizsystems.com
#
# script to convert dnsbls zone files from bind to rbldns file format
#
#
use Mail::SpamCannibal::ScriptSupport;

sub usage {
  my $warn = ($_[0])
	? "\n\t". $_[0] ."\n"
	: '';
  print STDERR qq($warn
Syntax: $0 infile outfile

);
  exit 1;
}

usage() unless @ARGV == 2;
my($in,$out) = @ARGV;
usage("NOT FOUND: $in")
	unless -e $in && -r $in;
usage("COULD NOT OPEN $out")
	unless open(OUT,'>'. $out);
unless (open(IN,$in)) {
  close OUT;
  unlink $out;
  usage("COULD NOT OPEN $in");
}

my $rblz = new Mail::SpamCannibal::ScriptSupport();
while (<IN>) {
  my $rv = $rblz->dns2rblz($_);
  print OUT $rv if $rv;
}
close OUT;
close IN;
