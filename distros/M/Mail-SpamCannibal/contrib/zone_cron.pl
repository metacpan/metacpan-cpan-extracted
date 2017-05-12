#!/usr/bin/perl
#
# zone_cron.pl
#
# version 1.00, 11-14-04, michael@bizsystems.com
# 
# extract the record count from the zonefile
#
# modify these as required for your setup
#
my $dir		= '/usr/local/spamcannibal/public_html/';
my $filein	= 'bl.spamcannibal.org.in';
my $fileout	= 'bl_records';

my $records = '<!-- no record count found -->'."\n";

open(F,$dir . $filein) or die "$0: could not open $filein\n";

while (<F>) {
  last unless $_ =~ /^;/;		# punt if not a header line
  if ($_ =~ /(\d+)\s+A\s+records/) {
    $records = "contains $1 A records\n";
    last;
  }
}
close F;

open(F,'>'. $dir . $fileout .'.tmp') or die "$0: could not open $fileout\n";
print F $records;
close F;

chmod 0755, $dir . $fileout;
rename $dir . $fileout .'.tmp', $dir . $fileout;
